require('dotenv').config();
const express = require('express');
const { MongoClient, ObjectId } = require('mongodb');
const cors = require('cors');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const sharp = require('sharp');
const ffmpeg = require('fluent-ffmpeg');
const ffmpegInstaller = require('@ffmpeg-installer/ffmpeg');

ffmpeg.setFfmpegPath(ffmpegInstaller.path);

const app = express();
const port = process.env.PORT || 3000;
const uri = process.env.MONGODB_URI || "mongodb+srv://rogerjove2005:rogjov01@cluster0.rxxyf.mongodb.net/";
const dbName = process.env.DB_NAME || "Projecte_prova";

// Configuración de directorios para archivos
const uploadDir = path.join(__dirname, 'uploads');
const profileImagesDir = path.join(uploadDir, 'profiles');
const chatMediaDir = path.join(uploadDir, 'chat');

// Crear directorios si no existen
[uploadDir, profileImagesDir, chatMediaDir].forEach(dir => {
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
});

// Configuración de multer para subida de archivos
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        let uploadPath = uploadDir;
        if (file.fieldname === 'profileImage') {
            uploadPath = profileImagesDir;
        } else if (file.fieldname === 'chatMedia') {
            uploadPath = chatMediaDir;
        }
        cb(null, uploadPath);
    },
    filename: function (req, file, cb) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
    }
});

const fileFilter = (req, file, cb) => {
    if (file.fieldname === 'profileImage') {
        // Solo permitir imágenes para foto de perfil
        if (file.mimetype.startsWith('image/')) {
            cb(null, true);
        } else {
            cb(new Error('Solo se permiten imágenes para la foto de perfil'), false);
        }
    } else if (file.fieldname === 'chatMedia') {
        // Permitir imágenes, videos y audios para el chat
        if (file.mimetype.startsWith('image/') || 
            file.mimetype.startsWith('video/') || 
            file.mimetype.startsWith('audio/')) {
            cb(null, true);
        } else {
            cb(new Error('Tipo de archivo no permitido'), false);
        }
    } else {
        cb(new Error('Campo de archivo no reconocido'), false);
    }
};

const upload = multer({
    storage: storage,
    fileFilter: fileFilter,
    limits: {
        fileSize: 10 * 1024 * 1024, // 10MB para imágenes y audios
        files: 1
    }
});

// Middleware
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(uploadDir));

// MongoDB client
const client = new MongoClient(uri);

// Database initialization functions
async function crearColecciones(database) {
  const colecciones = [
    "usuario", 
    "mensaje", 
    "chat", 
    "matchusers", 
    "actividad", 
    "juego",
    "juegousuario",
    "archivos_multimedia"
  ];
  
  for (const col of colecciones) {
    try {
      await database.createCollection(col);
      console.log(`Colección ${col} creada con éxito`);
    } catch (e) {
      if (e.code === 48) {
        console.log(`La colección ${col} ya existe, omitiendo creación`);
      } else {
        throw e;
      }
    }
  }
}

async function crearIndices(database) {
  console.log('Creando índices...');
  
  await database.collection("usuario").createIndex({ IDUsuario: 1 }, { unique: true });
  await database.collection("usuario").createIndex({ Correo: 1 }, { unique: true });
  await database.collection("usuario").createIndex({ Nombre: "text" });
  
  await database.collection("mensaje").createIndex({ IDMensaje: 1 }, { unique: true });
  await database.collection("mensaje").createIndex({ IDChat: 1 });
  await database.collection("mensaje").createIndex({ IDUsuario: 1 });
  await database.collection("mensaje").createIndex({ FechaEnvio: 1 });
  await database.collection("mensaje").createIndex({ IDArchivo: 1 });
  
  await database.collection("archivos_multimedia").createIndex({ IDArchivo: 1 }, { unique: true });
  await database.collection("archivos_multimedia").createIndex({ IDMensaje: 1 });
  await database.collection("archivos_multimedia").createIndex({ Tipo: 1 });
  await database.collection("archivos_multimedia").createIndex({ FechaSubida: 1 });
  
  await database.collection("chat").createIndex({ IDChat: 1 }, { unique: true });
  await database.collection("chat").createIndex({ IDMatch: 1 });
  await database.collection("chat").createIndex({ FechaCreacion: 1 });
  
  await database.collection("matchusers").createIndex({ IDMatch: 1 }, { unique: true });
  await database.collection("matchusers").createIndex({ IDUsuario1: 1, IDUsuario2: 1 }, { unique: true });
  await database.collection("matchusers").createIndex({ FechaCreacion: 1 });
  
  await database.collection("actividad").createIndex({ IDActividad: 1 }, { unique: true });
  await database.collection("actividad").createIndex({ IDUsuario: 1 });
  await database.collection("actividad").createIndex({ FechaRegistro: 1 });
  
  await database.collection("juego").createIndex({ IDJuego: 1 }, { unique: true });
  await database.collection("juego").createIndex({ NombreJuego: "text" });
  await database.collection("juego").createIndex({ Genero: 1 });
  
  await database.collection("juegousuario").createIndex({ IDUsuario: 1, IDJuego: 1 }, { unique: true });
  await database.collection("juegousuario").createIndex({ NivelElo: -1 });
  
  console.log('Índices creados con éxito');
}

async function configurarValidacion(database) {
  console.log('Configurando validadores de esquema...');
  
  try {
    // Validador para la colección de mensajes
    await database.command({
      collMod: "mensaje",
      validator: {
        $jsonSchema: {
          bsonType: "object",
          required: ["IDMensaje", "IDChat", "IDUsuario", "Tipo", "FechaEnvio"],
          properties: {
            IDMensaje: { bsonType: ["int", "number"] },
            IDChat: { bsonType: ["int", "number"] },
            IDUsuario: { bsonType: ["int", "number"] },
            Tipo: { 
              bsonType: "string",
              enum: ["texto", "imagen", "video", "audio"]
            },
            Contenido: { bsonType: "string" },
            FechaEnvio: { bsonType: "date" },
            IDArchivo: { bsonType: ["int", "number", "null"] }
          }
        }
      },
      validationLevel: "moderate",
      validationAction: "error"
    });
    console.log('Validador de mensaje configurado con éxito');

    // Validador para la colección de archivos multimedia
    await database.command({
      collMod: "archivos_multimedia",
      validator: {
        $jsonSchema: {
          bsonType: "object",
          required: ["IDArchivo", "IDMensaje", "Tipo", "URL", "FechaSubida"],
          properties: {
            IDArchivo: { bsonType: ["int", "number"] },
            IDMensaje: { bsonType: ["int", "number"] },
            Tipo: { 
              bsonType: "string",
              enum: ["imagen", "video", "audio"]
            },
            URL: { bsonType: "string" },
            NombreArchivo: { bsonType: "string" },
            Tamaño: { bsonType: ["int", "number"] },
            Formato: { bsonType: "string" },
            FechaSubida: { bsonType: "date" },
            Duracion: { bsonType: ["int", "number", "null"] } // Para videos y audio
          }
        }
      },
      validationLevel: "moderate",
      validationAction: "error"
    });
    console.log('Validador de archivos multimedia configurado con éxito');

    // Validador existente para usuario
    await database.command({
      collMod: "usuario",
      validator: {
        $jsonSchema: {
          bsonType: "object",
          required: ["Nombre", "Correo", "Contraseña"],
          properties: {
            IDUsuario: { bsonType: ["int", "number"] },
            Nombre: { bsonType: "string" },
            Correo: { bsonType: "string" },
            Contraseña: { bsonType: "string" },
            FotoPerfil: { bsonType: ["string", "null"] },
            Edad: { bsonType: ["int", "number", "null"] },
            Region: { bsonType: ["string", "null"] },
            bloqueado: { bsonType: "bool" }
          }
        }
      },
      validationLevel: "moderate",
      validationAction: "error"
    });
    console.log('Validador de usuario configurado con éxito');
  } catch (error) {
    console.error('Error configurando validadores:', error);
  }
}

// Connect to MongoDB and initialize database
async function connectDB() {
    try {
        await client.connect();
        console.log('Connected to MongoDB');
        
        const database = client.db(dbName);
        await crearColecciones(database);
        await crearIndices(database);
        await configurarValidacion(database);
        
        console.log('Database initialized successfully');
    } catch (error) {
        console.error('Error connecting to MongoDB:', error);
        process.exit(1);
    }
}

// Helper functions for common queries
async function buscarUsuariosPorJuego(database, idJuego) {
  return await database.collection("juegousuario")
    .aggregate([
      { $match: { IDJuego: idJuego } },
      { $sort: { NivelElo: -1 } },
      { $lookup: {
          from: "usuario",
          localField: "IDUsuario",
          foreignField: "IDUsuario",
          as: "datosUsuario"
        }
      },
      { $unwind: "$datosUsuario" },
      { $project: {
          _id: 0,
          IDUsuario: 1,
          NivelElo: 1,
          nombreUsuario: "$datosUsuario.Nombre",
          region: "$datosUsuario.Region"
        }
      }
    ]).toArray();
}

async function obtenerConversacion(database, idChat) {
  return await database.collection("mensaje")
    .aggregate([
      { $match: { IDChat: idChat } },
      { $sort: { FechaEnvio: 1 } },
      { $lookup: {
          from: "usuario",
          localField: "IDUsuario",
          foreignField: "IDUsuario",
          as: "datosUsuario"
        }
      },
      { $unwind: "$datosUsuario" },
      { $project: {
          _id: 0,
          IDMensaje: 1,
          emisor: "$datosUsuario.Nombre",
          Tipo: 1,
          Contenido: 1,
          FechaEnvio: 1
        }
      }
    ]).toArray();
}

async function buscarPosiblesMatches(database, idUsuario, idJuego) {
  const usuario = await database.collection("juegousuario").findOne({ IDUsuario: idUsuario, IDJuego: idJuego });
  
  if (!usuario) return [];
  
  const nivelMin = usuario.NivelElo - 300;
  const nivelMax = usuario.NivelElo + 300;
  
  const matchesExistentes = await database.collection("matchusers")
    .find({ 
      $or: [
        { IDUsuario1: idUsuario },
        { IDUsuario2: idUsuario }
      ]
    })
    .toArray();
  
  const usuariosConMatch = matchesExistentes.map(match => 
    match.IDUsuario1 === idUsuario ? match.IDUsuario2 : match.IDUsuario1
  );
  
  return await database.collection("juegousuario")
    .aggregate([
      { 
        $match: { 
          IDJuego: idJuego,
          IDUsuario: { $ne: idUsuario, $nin: usuariosConMatch },
          NivelElo: { $gte: nivelMin, $lte: nivelMax }
        } 
      },
      { $lookup: {
          from: "usuario",
          localField: "IDUsuario",
          foreignField: "IDUsuario",
          as: "datosUsuario"
        }
      },
      { $unwind: "$datosUsuario" },
      { $project: {
          _id: 0,
          IDUsuario: 1,
          NivelElo: 1,
          nombre: "$datosUsuario.Nombre",
          edad: "$datosUsuario.Edad",
          region: "$datosUsuario.Region"
        }
      }
    ]).toArray();
}

// Login endpoint
app.post('/login', async (req, res) => {
    try {
        const { Identificador, Contraseña } = req.body;
        
        const database = client.db(dbName);
        const usuarios = database.collection('usuario');
        
        // Buscar usuario por email o nombre
        const user = await usuarios.findOne({
            $or: [
                { Correo: Identificador },
                { Nombre: Identificador }
            ]
        });

        if (!user) {
            return res.status(401).json({ error: 'Usuario no encontrado' });
        }

        // Verificar si el usuario está bloqueado
        if (user.bloqueado) {
            return res.status(403).json({ error: 'Tu cuenta ha sido bloqueada. Por favor, contacta con el administrador.' });
        }

        // Verificar la contraseña
        const isValidPassword = await bcrypt.compare(Contraseña, user.Contraseña);
        if (!isValidPassword) {
            return res.status(401).json({ error: 'Contraseña incorrecta' });
        }

        // Crear token JWT
        const token = jwt.sign(
            { userId: user.IDUsuario },
            process.env.JWT_SECRET || 'tu_secreto_jwt',
            { expiresIn: '24h' }
        );

        // Enviar respuesta exitosa
        res.json({
            message: 'Login exitoso',
            user: {
                id: user.IDUsuario,
                email: user.Correo,
                username: user.Nombre
            },
            token
        });
    } catch (error) {
        console.error('Error en login:', error);
        res.status(500).json({ error: 'Error en el servidor' });
    }
});

// Register endpoint
app.post('/register', async (req, res) => {
    try {
        const { Nombre, Correo, Contraseña, FotoPerfil, Edad, Region } = req.body;
        
        const database = client.db(dbName);
        const usuarios = database.collection('usuario');
        
        // Check if email already exists
        const existingUser = await usuarios.findOne({ Correo });
        if (existingUser) {
            return res.status(400).json({ error: 'Email already registered' });
        }

        // Generate a new unique IDUsuario
        const lastUser = await usuarios.findOne({}, { sort: { IDUsuario: -1 } });
        const IDUsuario = lastUser ? (lastUser.IDUsuario || 0) + 1 : 1;
        
        // Hash the password
        const saltRounds = 10;
        const hashedPassword = await bcrypt.hash(Contraseña, saltRounds);
        
        // Create user document with required fields
        const userDocument = {
            IDUsuario: Number(IDUsuario),
            Nombre: String(Nombre || ''),
            Correo: String(Correo || ''),
            Contraseña: hashedPassword,
            FotoPerfil: FotoPerfil ? String(FotoPerfil) : "default_profile",
            Edad: Edad ? Number(Edad) : null,
            Region: Region ? String(Region) : "Not specified"
        };

        // Validate required fields
        if (!userDocument.Nombre || !userDocument.Correo || !Contraseña) {
            return res.status(400).json({ 
                error: 'Missing required fields',
                required: ['Nombre', 'Correo', 'Contraseña']
            });
        }

        console.log('Intentando registrar usuario:', {
            ...userDocument,
            Contraseña: '[PROTECTED]'
        });
        
        // Insert new user
        const result = await usuarios.insertOne(userDocument);
        
        if (!result.acknowledged) {
            throw new Error('Failed to insert user');
        }
        
        // Return success response with user data (excluding password)
        const { Contraseña: _, ...userData } = userDocument;
        res.status(201).json({
            message: 'User registered successfully',
            user: userData
        });
        
    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({ 
            error: 'Error registering user',
            details: error.message,
            validationErrors: error.errInfo?.details?.schemaRulesNotSatisfied
        });
    }
});

// Add user game endpoint
app.post('/addUserGame', async (req, res) => {
    try {
        const { IDUsuario, IDJuego, Estadisticas, Preferencias, NivelElo } = req.body;
        
        const database = client.db(dbName);
        const juegousuario = database.collection('juegousuario');
        
        // Check if user-game combination already exists
        const existingUserGame = await juegousuario.findOne({ IDUsuario, IDJuego });
        if (existingUserGame) {
            return res.status(400).json({ error: 'User already has this game registered' });
        }
        
        // Insert new user-game relationship
        const result = await juegousuario.insertOne({
            IDUsuario,
            IDJuego,
            Estadisticas,
            Preferencias,
            NivelElo
        });
        
        res.status(201).json({
            message: 'Game added successfully',
            userGameId: result.insertedId
        });
        
    } catch (error) {
        console.error('Add game error:', error);
        res.status(500).json({ error: 'Error adding game to user' });
    }
});

// New endpoints
app.get('/users/game/:gameId', async (req, res) => {
    try {
        const gameId = parseInt(req.params.gameId);
        const database = client.db(dbName);
        const users = await buscarUsuariosPorJuego(database, gameId);
        res.json(users);
    } catch (error) {
        console.error('Error fetching users by game:', error);
        res.status(500).json({ error: 'Error fetching users' });
    }
});

app.get('/chat/:chatId/messages', async (req, res) => {
    try {
        const chatId = parseInt(req.params.chatId);
        const database = client.db(dbName);
        const messages = await obtenerConversacion(database, chatId);
        res.json(messages);
    } catch (error) {
        console.error('Error fetching chat messages:', error);
        res.status(500).json({ error: 'Error fetching messages' });
    }
});

app.get('/matches/:userId/:gameId', async (req, res) => {
    try {
        const userId = parseInt(req.params.userId);
        const gameId = parseInt(req.params.gameId);
        const database = client.db(dbName);
        const matches = await buscarPosiblesMatches(database, userId, gameId);
        res.json(matches);
    } catch (error) {
        console.error('Error finding matches:', error);
        res.status(500).json({ error: 'Error finding matches' });
    }
});

// Change password endpoint
app.post('/change-password', async (req, res) => {
    try {
        const { IDUsuario, NuevaContraseña } = req.body;
        
        const database = client.db(dbName);
        const usuarios = database.collection('usuario');
        
        // Find user by ID
        const user = await usuarios.findOne({ IDUsuario: Number(IDUsuario) });
        
        if (!user) {
            return res.status(401).json({ error: 'Usuario no encontrado' });
        }
        
        // Hash new password
        const saltRounds = 10;
        const hashedNewPassword = await bcrypt.hash(NuevaContraseña, saltRounds);
        
        // Update password in database
        const result = await usuarios.updateOne(
            { IDUsuario: Number(IDUsuario) },
            { $set: { Contraseña: hashedNewPassword } }
        );
        
        if (result.modifiedCount === 1) {
            res.status(200).json({ message: 'Contraseña actualizada correctamente' });
        } else {
            throw new Error('Error al actualizar la contraseña');
        }
        
    } catch (error) {
        console.error('Change password error:', error);
        res.status(500).json({ 
            error: 'Error al cambiar la contraseña',
            details: error.message
        });
    }
});

// Reset password endpoint
app.post('/reset-password', async (req, res) => {
    try {
        const { Identificador, NuevaContraseña } = req.body;
        
        const database = client.db(dbName);
        const usuarios = database.collection('usuario');
        
        // Buscar usuario por email o nombre
        const user = await usuarios.findOne({
            $or: [
                { Correo: Identificador },
                { Nombre: Identificador }
            ]
        });
        
        if (!user) {
            return res.status(401).json({ error: 'Usuario no encontrado' });
        }
        
        // Hash new password
        const saltRounds = 10;
        const hashedNewPassword = await bcrypt.hash(NuevaContraseña, saltRounds);
        
        // Update password in database
        const result = await usuarios.updateOne(
            { IDUsuario: user.IDUsuario },
            { $set: { Contraseña: hashedNewPassword } }
        );
        
        if (result.modifiedCount === 1) {
            res.status(200).json({ message: 'Contraseña actualizada correctamente' });
        } else {
            throw new Error('Error al actualizar la contraseña');
        }
        
    } catch (error) {
        console.error('Reset password error:', error);
        res.status(500).json({ 
            error: 'Error al cambiar la contraseña',
            details: error.message
        });
    }
});

// Forgot password endpoint
app.post('/forgot-password', async (req, res) => {
    try {
        const { email } = req.body;
        
        const database = client.db(dbName);
        const usuarios = database.collection('usuario');
        
        // Buscar usuario por email
        const user = await usuarios.findOne({ Correo: email });
        
        if (!user) {
            return res.status(404).json({ error: 'No se encontró ningún usuario con ese email' });
        }
        
        // Generar token de recuperación
        const resetToken = crypto.randomBytes(32).toString('hex');
        const resetTokenExpiry = new Date(Date.now() + 3600000); // 1 hora
        
        // Guardar token en la base de datos
        await usuarios.updateOne(
            { IDUsuario: user.IDUsuario },
            { 
                $set: { 
                    resetToken,
                    resetTokenExpiry
                }
            }
        );
        
        // Aquí iría la lógica para enviar el email con el token
        // Por ahora solo enviamos una respuesta de éxito
        res.status(200).json({ 
            message: 'Se han enviado las instrucciones de recuperación a tu email'
        });
        
    } catch (error) {
        console.error('Forgot password error:', error);
        res.status(500).json({ 
            error: 'Error al procesar la solicitud de recuperación de contraseña',
            details: error.message
        });
    }
});

// Block user endpoint
app.post('/block-user', async (req, res) => {
    try {
        const { IDUsuario, IDUsuarioBloqueador } = req.body;
        
        const database = client.db(dbName);
        const usuarios = database.collection('usuario');
        
        // Verificar que el usuario que bloquea existe
        const bloqueador = await usuarios.findOne({ IDUsuario: Number(IDUsuarioBloqueador) });
        if (!bloqueador) {
            return res.status(404).json({ error: 'Usuario bloqueador no encontrado' });
        }

        // Actualizar el estado de bloqueo del usuario
        const result = await usuarios.updateOne(
            { IDUsuario: Number(IDUsuario) },
            { $set: { bloqueado: true } }
        );

        if (result.matchedCount === 0) {
            return res.status(404).json({ error: 'Usuario a bloquear no encontrado' });
        }

        res.json({ message: 'Usuario bloqueado exitosamente' });
    } catch (error) {
        console.error('Error al bloquear usuario:', error);
        res.status(500).json({ error: 'Error en el servidor' });
    }
});

// Unblock user endpoint
app.post('/unblock-user', async (req, res) => {
    try {
        const { IDUsuario, IDUsuarioDesbloqueador } = req.body;
        
        const database = client.db(dbName);
        const usuarios = database.collection('usuario');
        
        // Verificar que el usuario que desbloquea existe
        const desbloqueador = await usuarios.findOne({ IDUsuario: Number(IDUsuarioDesbloqueador) });
        if (!desbloqueador) {
            return res.status(404).json({ error: 'Usuario desbloqueador no encontrado' });
        }

        // Actualizar el estado de bloqueo del usuario
        const result = await usuarios.updateOne(
            { IDUsuario: Number(IDUsuario) },
            { $set: { bloqueado: false } }
        );

        if (result.matchedCount === 0) {
            return res.status(404).json({ error: 'Usuario a desbloquear no encontrado' });
        }

        res.json({ message: 'Usuario desbloqueado exitosamente' });
    } catch (error) {
        console.error('Error al desbloquear usuario:', error);
        res.status(500).json({ error: 'Error en el servidor' });
    }
});

// Endpoint para subir foto de perfil
app.post('/upload-profile-image', upload.single('profileImage'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No se ha subido ningún archivo' });
        }

        const { IDUsuario } = req.body;
        const database = client.db(dbName);
        const usuarios = database.collection('usuario');

        // Procesar la imagen con sharp (redimensionar y optimizar)
        const processedImagePath = path.join(profileImagesDir, 'processed-' + req.file.filename);
        await sharp(req.file.path)
            .resize(200, 200, { fit: 'cover' })
            .jpeg({ quality: 80 })
            .toFile(processedImagePath);

        // Eliminar la imagen original
        fs.unlinkSync(req.file.path);

        // Actualizar la URL de la foto de perfil en la base de datos
        const imageUrl = `/uploads/profiles/processed-${req.file.filename}`;
        await usuarios.updateOne(
            { IDUsuario: Number(IDUsuario) },
            { $set: { FotoPerfil: imageUrl } }
        );

        res.json({
            message: 'Foto de perfil actualizada exitosamente',
            imageUrl: imageUrl
        });
    } catch (error) {
        console.error('Error al subir foto de perfil:', error);
        res.status(500).json({ error: 'Error al procesar la imagen' });
    }
});

// Endpoint para subir archivos multimedia al chat
app.post('/upload-chat-media', upload.single('chatMedia'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No se ha subido ningún archivo' });
        }

        const { IDMensaje, IDUsuario } = req.body;
        const database = client.db(dbName);
        const archivosMultimedia = database.collection('archivos_multimedia');
        const mensajes = database.collection('mensaje');

        // Determinar el tipo de archivo
        const fileType = req.file.mimetype.split('/')[0];
        let processedFilePath = req.file.path;
        let duracion = null;

        // Procesar el archivo según su tipo
        if (fileType === 'image') {
            // Procesar imagen con sharp
            processedFilePath = path.join(chatMediaDir, 'processed-' + req.file.filename);
            await sharp(req.file.path)
                .resize(800, 800, { fit: 'inside' })
                .jpeg({ quality: 80 })
                .toFile(processedFilePath);
            fs.unlinkSync(req.file.path);
        } else if (fileType === 'video') {
            // Obtener duración del video
            duracion = await new Promise((resolve, reject) => {
                ffmpeg.ffprobe(req.file.path, (err, metadata) => {
                    if (err) reject(err);
                    resolve(metadata.format.duration);
                });
            });
        }

        // Generar ID único para el archivo
        const lastFile = await archivosMultimedia.findOne({}, { sort: { IDArchivo: -1 } });
        const IDArchivo = lastFile ? (lastFile.IDArchivo || 0) + 1 : 1;

        // Crear registro en la base de datos
        const archivoData = {
            IDArchivo: Number(IDArchivo),
            IDMensaje: Number(IDMensaje),
            Tipo: fileType,
            URL: `/uploads/chat/${path.basename(processedFilePath)}`,
            NombreArchivo: req.file.originalname,
            Tamaño: req.file.size,
            Formato: req.file.mimetype,
            FechaSubida: new Date(),
            Duracion: duracion
        };

        await archivosMultimedia.insertOne(archivoData);

        // Actualizar el mensaje con el ID del archivo
        await mensajes.updateOne(
            { IDMensaje: Number(IDMensaje) },
            { $set: { IDArchivo: Number(IDArchivo) } }
        );

        res.json({
            message: 'Archivo multimedia subido exitosamente',
            archivo: archivoData
        });
    } catch (error) {
        console.error('Error al subir archivo multimedia:', error);
        res.status(500).json({ error: 'Error al procesar el archivo' });
    }
});

// Start server
connectDB().then(() => {
    app.listen(port, () => {
        console.log(`Server running on port ${port}`);
    });
}); 