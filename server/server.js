require('dotenv').config();
const express = require('express');
const { MongoClient, ObjectId } = require('mongodb');
const cors = require('cors');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');

const app = express();
const port = process.env.PORT || 3000;
const uri = process.env.MONGODB_URI || "mongodb+srv://rogerjove2005:rogjov01@cluster0.rxxyf.mongodb.net/";
const dbName = process.env.DB_NAME || "Projecte_prova";

// Middleware
app.use(cors());
app.use(express.json());

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
    "juegousuario"
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
    console.error('Error configurando validador:', error);
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

// Start server
connectDB().then(() => {
    app.listen(port, () => {
        console.log(`Server running on port ${port}`);
    });
}); 