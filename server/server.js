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
const authRoutes = require('./src/routes/auth');
const testAuthRoutes = require('./src/routes/testAuth');
const messageRoutes = require('./src/routes/messageRoutes');
const session = require('express-session');
const { passport: steamPassport } = require('./src/steamAuth');
const { passport: appleAmazonPassport } = require('./src/appleAmazonAuth');
const { runSeeders } = require('./src/seeders');
const axios = require('axios');
const mongoose = require('mongoose');
const Usuario = require('./src/models/usuario');
const Match = require('./src/models/match');
const { sendPasswordResetEmail } = require('./src/services/emailService');
const nodemailer = require('nodemailer');

ffmpeg.setFfmpegPath(ffmpegInstaller.path);

const app = express();
const port = process.env.PORT || 3001;
const uri = process.env.MONGODB_URI || "mongodb+srv://rogerjove2005:rogjov01@cluster0.rxxyf.mongodb.net/";
const dbName = process.env.DB_NAME || "Projecte_prova";

// Configuración de directorios para archivos
const uploadDir = path.join(__dirname, 'uploads');
const profileImagesDir = path.join(uploadDir, 'profiles');
const chatMediaDir = path.join(uploadDir, 'chat');
const chatImagesDir = path.join(chatMediaDir, 'images');
const chatVideosDir = path.join(chatMediaDir, 'videos');
const chatAudioDir = path.join(chatMediaDir, 'audio');

// Crear directorios si no existen
[uploadDir, profileImagesDir, chatMediaDir, chatImagesDir, chatVideosDir, chatAudioDir].forEach(dir => {
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
    } else if (file.fieldname === 'chatMedia' || file.fieldname === 'audio') {
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

// Servir archivos estáticos
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Rutas
app.use('/api/auth', authRoutes);
app.use('/api/test', testAuthRoutes);
app.use('/api/messages', messageRoutes);

// Configuración de sesiones
app.use(session({
    secret: process.env.SESSION_SECRET || 'your-secret-key',
    resave: false,
    saveUninitialized: true,
    cookie: { secure: process.env.NODE_ENV === 'production' }
}));

// Inicialización de Passport
app.use(steamPassport.initialize());
app.use(steamPassport.session());

// Inicialización de Passport para Apple y Amazon
app.use(appleAmazonPassport.initialize());
app.use(appleAmazonPassport.session());

// MongoDB client
const client = new MongoClient(uri);

// Configuración de rate limiting mejorada
const rateLimit = require('express-rate-limit');
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutos
    max: 100, // límite de 100 peticiones por ventana
    message: 'Demasiadas peticiones desde esta IP, por favor intenta de nuevo más tarde',
    standardHeaders: true,
    legacyHeaders: false,
});

// Middleware de autenticación mejorado
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'Token de autenticación no proporcionado' });
    }

    jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
        if (err) {
            return res.status(403).json({ error: 'Token inválido o expirado' });
        }
        req.user = user;
        next();
    });
};

// Validación de ELO
function validarElo(elo) {
    return Number.isInteger(elo) && elo >= 0 && elo <= 3000;
}

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
          required: ["IDChat", "IDUsuario", "Tipo", "FechaEnvio"],
          properties: {
            IDChat: { bsonType: ["objectId", "string"] },
            IDUsuario: { bsonType: ["objectId", "string"] },
            Tipo: { 
              bsonType: "string",
              enum: ["texto", "imagen", "video", "audio"]
            },
            Contenido: { bsonType: "string" },
            RutaArchivo: { bsonType: "string" },
            FechaEnvio: { bsonType: "date" },
            Estado: {
              bsonType: "string",
              enum: ["enviado", "entregado", "leido"]
            }
          }
        }
      }
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

// Función para crear usuarios decoy
async function createDecoyUsers(database) {
    try {
        console.log('Iniciando creación de usuarios decoy...');
        
        // Primero, obtener los juegos existentes de la base de datos
        const juegosExistentes = await database.collection('juego').find({}).toArray();
        console.log(`Juegos encontrados en la base de datos: ${juegosExistentes.length}`);
        
        if (juegosExistentes.length === 0) {
            console.error('No hay juegos en la base de datos');
            return;
        }

        // Lista de rangos por juego
        const rangosPorJuego = {
            'League of Legends': ['Hierro', 'Bronce', 'Plata', 'Oro', 'Platino', 'Diamante', 'Maestro', 'Gran Maestro', 'Desafiante'],
            'Valorant': ['Hierro', 'Bronce', 'Plata', 'Oro', 'Platino', 'Diamante', 'Ascendente', 'Inmortal', 'Radiante'],
            'Counter-Strike 2': ['Plata I', 'Plata II', 'Plata III', 'Plata IV', 'Plata Elite', 'Plata Elite Master', 'Nova I', 'Nova II', 'Nova III', 'Nova Master', 'AK I', 'AK II', 'AK Cruz', 'Águila I', 'Águila II', 'Águila Master', 'Supremo', 'Global Elite'],
            'Fortnite': ['Bronce', 'Plata', 'Oro', 'Platino', 'Diamante', 'Champion', 'Unreal']
        };

        // Nombres y descripciones para los usuarios decoy
        const decoyUsers = [
            // Grupo 1: League of Legends y Valorant
            { nombre: 'AlexGamer', edad: 22, genero: 'Masculino', descripcion: 'Busco equipo para rankeds. Main ADC en LoL y Duelista en Valorant.', juegos: ['League of Legends', 'Valorant'] },
            { nombre: 'SarahPro', edad: 25, genero: 'Femenino', descripcion: 'Streamer y jugadora competitiva. Especialista en estrategia y análisis de juego.', juegos: ['League of Legends', 'Valorant'] },
            { nombre: 'MikeTheTank', edad: 20, genero: 'Masculino', descripcion: 'Tank main en todos los juegos. Siempre protegiendo al equipo.', juegos: ['League of Legends', 'Valorant'] },
            
            // Grupo 2: Counter-Strike 2 y Fortnite
            { nombre: 'LunaGaming', edad: 23, genero: 'Femenino', descripcion: 'Amante de los FPS. Alta precisión y buen trabajo en equipo.', juegos: ['Counter-Strike 2', 'Fortnite'] },
            { nombre: 'CarlosNinja', edad: 21, genero: 'Masculino', descripcion: 'Jugador versátil. Me adapto a cualquier rol y estrategia.', juegos: ['Counter-Strike 2', 'Fortnite'] },
            { nombre: 'EmmaBuilder', edad: 24, genero: 'Femenino', descripcion: 'Especialista en construcción y edición en Fortnite. Busco duo para torneos.', juegos: ['Counter-Strike 2', 'Fortnite'] },
            
            // Grupo 3: League of Legends y Counter-Strike 2
            { nombre: 'DavidSniper', edad: 22, genero: 'Masculino', descripcion: 'AWP main en CS2. Precisión y paciencia son mis puntos fuertes.', juegos: ['League of Legends', 'Counter-Strike 2'] },
            { nombre: 'SophiaSupport', edad: 25, genero: 'Femenino', descripcion: 'Support main en LoL. Me encanta ayudar al equipo a brillar.', juegos: ['League of Legends', 'Counter-Strike 2'] },
            { nombre: 'LeoRush', edad: 20, genero: 'Masculino', descripcion: 'Jugador agresivo. Me especializo en early game y snowball.', juegos: ['League of Legends', 'Counter-Strike 2'] },
            
            // Grupo 4: Valorant y Fortnite
            { nombre: 'MiaTactics', edad: 23, genero: 'Femenino', descripcion: 'Estratega nata. Me gusta analizar y explotar las debilidades del rival.', juegos: ['Valorant', 'Fortnite'] },
            { nombre: 'RyanFlex', edad: 21, genero: 'Masculino', descripcion: 'Jugador flexible. Puedo adaptarme a cualquier rol y situación.', juegos: ['Valorant', 'Fortnite'] },
            { nombre: 'ZoeCreative', edad: 24, genero: 'Femenino', descripcion: 'Jugadora creativa. Me especializo en estrategias poco convencionales.', juegos: ['Valorant', 'Fortnite'] }
        ];

        // Verificar si ya existen usuarios decoy
        const existingDecoy = await database.collection('usuario').findOne({ email: 'alexgamer@example.com' });
        if (existingDecoy) {
            console.log('Los usuarios decoy ya existen en la base de datos');
            return;
        }

        // Crear cada usuario decoy
        for (const user of decoyUsers) {
            try {
                // Asignar los juegos específicos para cada usuario
                const userGames = [];
                
                for (const gameName of user.juegos) {
                    const selectedGame = juegosExistentes.find(game => game.NombreJuego === gameName);
                    if (!selectedGame) {
                        console.error(`No se encontró el juego: ${gameName}`);
                        continue;
                    }
                    
                    const rangos = rangosPorJuego[selectedGame.NombreJuego];
                    if (!rangos) {
                        console.error(`No se encontraron rangos para el juego: ${selectedGame.NombreJuego}`);
                        continue;
                    }
                    
                    const rangoIndex = Math.floor(Math.random() * rangos.length);
                    
                    userGames.push({
                        IDJuego: selectedGame._id,
                        NombreJuego: selectedGame.NombreJuego,
                        NivelElo: rangos[rangoIndex]
                    });
                }

                if (userGames.length === 0) {
                    console.error(`No se pudieron asignar juegos al usuario ${user.nombre}`);
                    continue;
                }

                // Crear el usuario decoy
                const newUser = await database.collection('usuario').insertOne({
                    Nombre: user.nombre,
                    Correo: `${user.nombre.toLowerCase()}@example.com`,
                    Contraseña: await bcrypt.hash('decoy123', 10), // Contraseña por defecto para usuarios decoy
                    Edad: user.edad,
                    Genero: user.genero,
                    Descripcion: user.descripcion,
                    Juegos: userGames,
                    FotoPerfil: `https://api.dicebear.com/7.x/avataaars/svg?seed=${user.nombre}` // Avatar generado
                });

                console.log(`Usuario decoy creado exitosamente: ${user.nombre}`);
            } catch (error) {
                console.error(`Error al crear usuario decoy ${user.nombre}:`, error);
            }
        }

        console.log('Proceso de creación de usuarios decoy completado');
    } catch (error) {
        console.error('Error general al crear usuarios decoy:', error);
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
        await initializeData(database);
        
        console.log('Database initialized successfully');
    } catch (error) {
        console.error('Error connecting to MongoDB:', error);
        process.exit(1);
    }
}

async function initializeData(database) {
    try {
        const usuarios = database.collection('usuario');
        const chats = database.collection('chat');

        // 1. Crear usuarios
        console.log('Creating users...');
        const testUsers = [
            {
                IDUsuario: 1,
                Nombre: "Alex",
                Correo: "alex@test.com",
                Contraseña: await bcrypt.hash("password123", 10),
                FotoPerfil: "DwarfTestIcon",
                Edad: 23,
                Region: "Europa",
                Descripcion: "Buscando equipo para rankeds",
                Juegos: [
                    { nombre: "League of Legends", rango: "Platino" },
                    { nombre: "Valorant", rango: "Oro" }
                ],
                Genero: "Masculino"
            },
            {
                IDUsuario: 2,
                Nombre: "Laura",
                Correo: "laura@test.com",
                Contraseña: await bcrypt.hash("password123", 10),
                FotoPerfil: "ToadTestIcon",
                Edad: 25,
                Region: "Europa",
                Descripcion: "Main support, looking for ADC",
                Juegos: [
                    { nombre: "League of Legends", rango: "Diamante" },
                    { nombre: "World of Warcraft", rango: "2100+" }
                ],
                Genero: "Femenino"
            },
            {
                IDUsuario: 3,
                Nombre: "Roger",
                Correo: "roger@test.com",
                Contraseña: await bcrypt.hash("password123", 10),
                FotoPerfil: "TerroristTestIcon",
                Edad: 28,
                Region: "Europa",
                Descripcion: "Jugador competitivo buscando team",
                Juegos: [
                    { nombre: "Valorant", rango: "Inmortal" },
                    { nombre: "CS2", rango: "Águila" }
                ],
                Genero: "Masculino"
            },
            {
                IDUsuario: 4,
                Nombre: "Saten",
                Correo: "saten@test.com",
                Contraseña: await bcrypt.hash("password123", 10),
                FotoPerfil: "CatTestIcon",
                Edad: 24,
                Region: "Europa",
                Descripcion: "Hola me llamo Saten soy maja",
                Juegos: [
                    { nombre: "Valorant", rango: "Inmortal" },
                    { nombre: "CS2", rango: "Águila" }
                ],
                Genero: "Femenino"
            }
        ];
        
        // Insertar usuarios
        for (const user of testUsers) {
            const existingUser = await usuarios.findOne({ IDUsuario: user.IDUsuario });
            if (!existingUser) {
                await usuarios.insertOne(user);
                console.log(`Created user: ${user.Nombre}`);
            } else {
                console.log(`User ${user.Nombre} already exists`);
            }
        }
        
        // 2. Crear chats entre todos los usuarios
        console.log('\nCreating chats...');
        const allUsers = await usuarios.find({}).toArray();
        console.log(`Found ${allUsers.length} users`);
        
        // Obtener el último IDChat para asegurar unicidad
        const lastChat = await chats.findOne({}, { sort: { IDChat: -1 } });
        let nextChatId = (lastChat && lastChat.IDChat) ? parseInt(lastChat.IDChat) + 1 : 1;
        
        // Primero, obtener todos los chats existentes para evitar duplicados
        const existingChats = await chats.find({}).toArray();
        const existingChatPairs = new Set();
        
        // Crear un conjunto de pares de usuarios que ya tienen chat
        for (const chat of existingChats) {
            if (chat && chat.usuarios && Array.isArray(chat.usuarios)) {
                const sortedUsers = [...chat.usuarios].sort((a, b) => a - b);
                existingChatPairs.add(`${sortedUsers[0]}-${sortedUsers[1]}`);
            }
        }
        
        for (let i = 0; i < allUsers.length; i++) {
            for (let j = i + 1; j < allUsers.length; j++) {
                const user1 = allUsers[i];
                const user2 = allUsers[j];
                
                // Crear una clave única para el par de usuarios
                const sortedUsers = [user1.IDUsuario, user2.IDUsuario].sort((a, b) => a - b);
                const chatKey = `${sortedUsers[0]}-${sortedUsers[1]}`;
                
                if (!existingChatPairs.has(chatKey)) {
                    // Crear nuevo chat con ID incremental
                    const newChat = {
                        IDChat: nextChatId,
                        usuarios: [user1.IDUsuario, user2.IDUsuario],
                        mensajes: [],
                        FechaCreacion: new Date(),
                        estado: 'active'
                    };
                    
                    try {
                    await chats.insertOne(newChat);
                    console.log(`Created chat between ${user1.Nombre} and ${user2.Nombre} with ID ${nextChatId}`);
                    nextChatId++;
                        existingChatPairs.add(chatKey);
                    } catch (error) {
                        if (error.code === 11000) {
                            // Si hay un error de duplicado, incrementar el ID y reintentar
                            nextChatId++;
                            continue;
                        }
                        throw error;
                    }
                } else {
                    console.log(`Chat already exists between ${user1.Nombre} and ${user2.Nombre}`);
                }
            }
        }
        
        console.log('\nInitialization completed successfully!');
    } catch (error) {
        console.error('Error initializing data:', error);
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

// Configuración de la API de FACEIT
const FACEIT_API_KEY = process.env.FACEIT_API_KEY;
const FACEIT_API_URL = 'https://open.faceit.com/data/v4';

// Cliente de FACEIT API
const faceitClient = axios.create({
    baseURL: FACEIT_API_URL,
    headers: {
        'Authorization': `Bearer ${FACEIT_API_KEY}`,
        'Content-Type': 'application/json'
    }
});

// Función para obtener datos de FACEIT
async function getFaceitPlayerStats(gameId, playerId) {
    try {
        const response = await faceitClient.get(`/players/${playerId}/stats/${gameId}`);
        return response.data;
    } catch (error) {
        console.error('Error getting FACEIT stats:', error);
        return null;
    }
}

// Función para sincronizar ELO con FACEIT
async function syncFaceitElo(userId, gameId) {
    try {
        const faceitStats = await getFaceitPlayerStats(gameId, userId);
        if (!faceitStats) return null;

        const database = client.db(dbName);
        const elo = faceitStats.lifetime.average_elo || 1200; // ELO por defecto si no hay datos

        await database.collection('juegousuario').updateOne(
            { 
                IDUsuario: parseInt(userId), 
                IDJuego: parseInt(gameId)
            },
            { 
                $set: { 
                    NivelElo: elo,
                    Rango: calcularRango(elo),
                    UltimaSincFaceit: new Date()
                }
            }
        );

        return elo;
    } catch (error) {
        console.error('Error syncing FACEIT ELO:', error);
        return null;
    }
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
        const { Nombre, Correo, Contraseña, Juegos, FotoPerfil, Edad, Region, Descripcion, Genero } = req.body;
        
        console.log('Datos recibidos en registro:', {
            Nombre,
            Correo,
            Juegos,
            FotoPerfil,
            Edad,
            Region,
            Descripcion,
            Genero
        });

        // Validar edad
        const edad = Number(Edad);
        if (!edad || edad < 18) {
            return res.status(400).json({ error: 'Debes ser mayor de 18 años para registrarte' });
        }

        const database = client.db(dbName);
        const usuarios = database.collection('usuario');
        
        // Check if email already exists
        const existingUser = await usuarios.findOne({ Correo });
        if (existingUser) {
            return res.status(400).json({ error: 'Email already registered' });
        }

        // Generate a new unique IDUsuario
        const timestamp = Date.now();
        const random = Math.floor(Math.random() * 1000);
        const IDUsuario = parseInt(`${timestamp}${random}`);
        
        console.log('Nuevo IDUsuario generado:', IDUsuario);
        
        // Hash the password
        const saltRounds = 10;
        const hashedPassword = await bcrypt.hash(Contraseña, saltRounds);

        // Format games array
        let formattedGames = [];
        if (Juegos && Array.isArray(Juegos)) {
            formattedGames = Juegos.map(game => {
                // Si el juego viene como objeto {nombre, rango}
                if (game && typeof game === 'object') {
                    return {
                        nombre: game.nombre || '',
                        rango: game.rango || 'Principiante',
                        addedAt: new Date()
                    };
                }
                // Si el juego viene como array [nombre, rango]
                else if (Array.isArray(game)) {
                    return {
                        nombre: game[0] || '',
                        rango: game[1] || 'Principiante',
                        addedAt: new Date()
                    };
                }
                return null;
            }).filter(game => game !== null && game.nombre);
        }

        console.log('Juegos formateados:', formattedGames);

        // Create user document
        const userDocument = {
            IDUsuario: IDUsuario,
            Nombre: String(Nombre),
            Correo: String(Correo),
            Contraseña: hashedPassword,
            FotoPerfil: FotoPerfil || "default_profile",
            Edad: edad,
            Region: Region || "Not specified",
            Descripcion: Descripcion || "¡Hola! Me gusta jugar videojuegos.",
            Juegos: formattedGames,
            Genero: Genero || "Not specified"
        };

        console.log('Documento de usuario a insertar:', userDocument);

        // Insert the user
        const result = await usuarios.insertOne(userDocument);
        
        if (result.insertedId) {
            res.status(201).json({
                message: 'User registered successfully',
                userId: result.insertedId,
                juegos: formattedGames
            });
        } else {
            res.status(500).json({ error: 'Failed to register user' });
        }
    } catch (error) {
        console.error('Error en registro:', error);
        res.status(500).json({ error: 'Error en el servidor' });
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

// Forgot password endpoint
app.post('/forgot-password', async (req, res) => {
    try {
        const { email } = req.body;
        
        if (!email) {
            return res.status(400).json({ 
                success: false,
                message: 'El email es requerido' 
            });
        }

        const database = client.db(dbName);
        const usuarios = database.collection('usuario');
        
        // Buscar usuario por email
        const user = await usuarios.findOne({ Correo: email });
        
        if (!user) {
            // Por seguridad, devolvemos el mismo mensaje aunque el email no exista
            return res.status(200).json({ 
                success: true,
                message: 'Si el email está registrado, recibirás un correo con las instrucciones de recuperación'
            });
        }
        
        // Generar código de verificación de 6 dígitos
        const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
        const resetToken = crypto.randomBytes(32).toString('hex');
        const resetTokenExpiry = new Date(Date.now() + 3600000); // 1 hora
        
        // Guardar código y token en la base de datos
        await usuarios.updateOne(
            { IDUsuario: user.IDUsuario },
            { 
                $set: { 
                    verificationCode,
                    resetToken,
                    resetTokenExpiry
                }
            }
        );
        
        // Enviar email con el código de verificación usando el servicio de email
        const { sendVerificationCode } = require('./src/services/emailService');
        const emailSent = await sendVerificationCode(email, verificationCode);
        
        if (!emailSent) {
            throw new Error('Error al enviar el email');
        }
        
        res.status(200).json({ 
            success: true,
            message: 'Si el email está registrado, recibirás un correo con el código de verificación'
        });
        
    } catch (error) {
        console.error('Forgot password error:', error);
        res.status(500).json({ 
            success: false,
            message: 'Error al procesar la solicitud de recuperación de contraseña'
        });
    }
});

// Verify code endpoint
app.post('/verify-code', async (req, res) => {
    try {
        const { email, code } = req.body;
        
        if (!email || !code) {
            return res.status(400).json({ 
                success: false,
                message: 'Email y código son requeridos' 
            });
        }
        
        const database = client.db(dbName);
        const usuarios = database.collection('usuario');
        
        // Buscar usuario por email y código
        const user = await usuarios.findOne({ 
            Correo: email,
            verificationCode: code,
            resetTokenExpiry: { $gt: new Date() }
        });
        
        if (!user) {
            return res.status(400).json({ 
                success: false,
                message: 'Código inválido o expirado' 
            });
        }
        
        // Devolver el token de reset para cambiar la contraseña
        res.status(200).json({ 
            success: true,
            message: 'Código verificado correctamente',
            resetToken: user.resetToken
        });
        
    } catch (error) {
        console.error('Verify code error:', error);
        res.status(500).json({ 
            success: false,
            message: 'Error al verificar el código'
        });
    }
});

// Reset password endpoint
app.post('/reset-password', async (req, res) => {
    try {
        const { token, newPassword } = req.body;
        
        if (!token || !newPassword) {
            return res.status(400).json({ 
                success: false,
                message: 'Token y nueva contraseña son requeridos' 
            });
        }
        
        const database = client.db(dbName);
        const usuarios = database.collection('usuario');
        
        // Buscar usuario por token de recuperación
        const user = await usuarios.findOne({ 
            resetToken: token,
            resetTokenExpiry: { $gt: new Date() }
        });
        
        if (!user) {
            return res.status(400).json({ 
                success: false,
                message: 'Token inválido o expirado' 
            });
        }
        
        // Hash de la nueva contraseña
        const saltRounds = 10;
        const hashedPassword = await bcrypt.hash(newPassword, saltRounds);
        
        // Actualizar contraseña y limpiar tokens
        await usuarios.updateOne(
            { IDUsuario: user.IDUsuario },
            { 
                $set: { 
                    Contraseña: hashedPassword 
                },
                $unset: { 
                    resetToken: "",
                    resetTokenExpiry: "",
                    verificationCode: ""
                }
            }
        );
        
        res.status(200).json({ 
            success: true,
            message: 'Contraseña actualizada exitosamente' 
        });
        
    } catch (error) {
        console.error('Reset password error:', error);
        res.status(500).json({ 
            success: false,
            message: 'Error al resetear la contraseña'
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
        console.log('Iniciando subida de archivo multimedia...');
        console.log('Body:', req.body);
        console.log('File:', req.file);

        if (!req.file) {
            console.log('Error: No se ha subido ningún archivo');
            return res.status(400).json({ error: 'No se ha subido ningún archivo' });
        }

        const { chatId, userId } = req.body;
        if (!chatId || !userId) {
            console.log('Error: Faltan campos requeridos', { chatId, userId });
            return res.status(400).json({ 
                error: 'Se requiere chatId y userId',
                received: { chatId, userId }
            });
        }

        const database = client.db(dbName);
        const mensajes = database.collection('mensaje');
        const archivosMultimedia = database.collection('archivos_multimedia');

        // Determinar el tipo de archivo y su subdirectorio
        const fileType = req.file.mimetype.split('/')[0];
        let processedFilePath = req.file.path;
        let duracion = null;
        let fileUrl = '';

        try {
        // Procesar el archivo según su tipo
            switch (fileType) {
                case 'image':
                    console.log('Procesando imagen...');
                    processedFilePath = path.join(chatImagesDir, 'processed-' + req.file.filename);
            await sharp(req.file.path)
                .resize(800, 800, { fit: 'inside' })
                .jpeg({ quality: 80 })
                .toFile(processedFilePath);
            fs.unlinkSync(req.file.path);
                    fileUrl = `/uploads/chat/images/processed-${path.basename(req.file.filename)}`;
                    break;

                case 'video':
                    console.log('Procesando video...');
                    processedFilePath = path.join(chatVideosDir, req.file.filename);
                    fileUrl = `/uploads/chat/videos/${path.basename(req.file.filename)}`;
            // Obtener duración del video
            duracion = await new Promise((resolve, reject) => {
                ffmpeg.ffprobe(req.file.path, (err, metadata) => {
                    if (err) reject(err);
                    resolve(metadata.format.duration);
                });
            });
                    break;

                case 'audio':
                    console.log('Procesando audio...');
                    processedFilePath = path.join(chatAudioDir, req.file.filename);
                    fileUrl = `/uploads/chat/audio/${path.basename(req.file.filename)}`;
                    // Obtener duración del audio
                    duracion = await new Promise((resolve, reject) => {
                        ffmpeg.ffprobe(req.file.path, (err, metadata) => {
                            if (err) reject(err);
                            resolve(metadata.format.duration);
                        });
                    });
                    break;

                default:
                    throw new Error('Tipo de archivo no soportado');
            }

            console.log('Creando mensaje en la base de datos...');
            // Crear mensaje en la base de datos
            const lastMessage = await mensajes.findOne({}, { sort: { IDMensaje: -1 } });
            const IDMensaje = lastMessage ? (lastMessage.IDMensaje || 0) + 1 : 1;

            // Asegurarnos de que el tipo sea uno de los permitidos
            const tipoMensaje = fileType === 'image' ? 'imagen' : fileType;

            const mensaje = {
                IDMensaje: Number(IDMensaje),
                IDChat: Number(chatId),
                IDUsuario: Number(userId),
                Tipo: tipoMensaje,
                Contenido: fileUrl,
                FechaEnvio: new Date(),
                Estado: "enviado"
            };

            console.log('Insertando mensaje:', mensaje);
            await mensajes.insertOne(mensaje);

            // Crear documento en archivos_multimedia
        const lastFile = await archivosMultimedia.findOne({}, { sort: { IDArchivo: -1 } });
        const IDArchivo = lastFile ? (lastFile.IDArchivo || 0) + 1 : 1;

            const archivoMultimedia = {
            IDArchivo: Number(IDArchivo),
            IDMensaje: Number(IDMensaje),
                Tipo: tipoMensaje,
                URL: fileUrl,
            NombreArchivo: req.file.originalname,
                Tamaño: Number(req.file.size),
            Formato: req.file.mimetype,
            FechaSubida: new Date(),
                Duracion: duracion ? Number(duracion) : null
        };

            console.log('Insertando archivo multimedia:', archivoMultimedia);
            await archivosMultimedia.insertOne(archivoMultimedia);

            // Devolver respuesta con la URL completa
            const baseUrl = process.env.BASE_URL || 'http://localhost:3000';
            const fullUrl = `${baseUrl}${fileUrl}`;

            console.log('Subida completada exitosamente');
        res.json({
            message: 'Archivo multimedia subido exitosamente',
                data: {
                    url: fullUrl,
                    type: tipoMensaje,
                    duration: duracion,
                    messageId: IDMensaje
                }
            });

        } catch (error) {
            console.error('Error al procesar el archivo:', error);
            // Limpiar archivos en caso de error
            if (fs.existsSync(req.file.path)) {
                fs.unlinkSync(req.file.path);
            }
            if (fs.existsSync(processedFilePath)) {
                fs.unlinkSync(processedFilePath);
            }
            throw error;
        }

    } catch (error) {
        console.error('Error al subir archivo multimedia:', error);
        res.status(500).json({ 
            error: 'Error al procesar el archivo',
            details: error.message,
            stack: error.stack
        });
    }
});

// Get all users endpoint
app.get('/users', async (req, res) => {
    try {
        const database = client.db(dbName);
        const usuarios = database.collection('usuario');
        
        // Obtener todos los usuarios con una proyección específica
        const users = await usuarios.find({}).project({
            IDUsuario: 1,
            Nombre: 1,
            Correo: 1,
            FotoPerfil: 1,
            Edad: 1,
            Region: 1,
            Descripcion: 1,
            Juegos: 1,
            Genero: 1,
            _id: 0
        }).toArray();
        
        if (!users) {
            return res.status(404).json({ error: 'No se encontraron usuarios' });
        }

        console.log('Usuarios encontrados:', users.length);
        res.status(200).json(users);
        
    } catch (error) {
        console.error('Error al obtener usuarios:', error);
        res.status(500).json({ 
            error: 'Error al obtener usuarios',
            message: error.message
        });
    }
});

// Función mejorada para calcular el ELO
const calcularElo = (elo1, elo2, resultado, kFactor = 32) => {
    // Validación de rangos de ELO
    if (elo1 < 0 || elo2 < 0) {
        throw new Error('Los valores de ELO no pueden ser negativos');
    }

    // Cálculo de la probabilidad esperada
    const probabilidadEsperada1 = 1 / (1 + Math.pow(10, (elo2 - elo1) / 400));
    const probabilidadEsperada2 = 1 - probabilidadEsperada1;

    // Cálculo del nuevo ELO
    let nuevoElo1, nuevoElo2;
    
    if (resultado === 'empate') {
        nuevoElo1 = elo1 + kFactor * (0.5 - probabilidadEsperada1);
        nuevoElo2 = elo2 + kFactor * (0.5 - probabilidadEsperada2);
    } else if (resultado === 'victoria1') {
        nuevoElo1 = elo1 + kFactor * (1 - probabilidadEsperada1);
        nuevoElo2 = elo2 + kFactor * (0 - probabilidadEsperada2);
    } else {
        nuevoElo1 = elo1 + kFactor * (0 - probabilidadEsperada1);
        nuevoElo2 = elo2 + kFactor * (1 - probabilidadEsperada2);
    }

    // Asegurar que el ELO no sea negativo
    nuevoElo1 = Math.max(0, Math.round(nuevoElo1));
    nuevoElo2 = Math.max(0, Math.round(nuevoElo2));

    return { nuevoElo1, nuevoElo2 };
};

// Función mejorada para calcular el rango
const calcularRango = (elo) => {
    if (elo < 800) return 'Bronce';
    if (elo < 1200) return 'Plata';
    if (elo < 1600) return 'Oro';
    if (elo < 2000) return 'Platino';
    if (elo < 2400) return 'Diamante';
    return 'Maestro';
};

// Endpoint mejorado para obtener el ELO
app.get('/api/elo/:userId/:gameId', authenticateToken, limiter, async (req, res) => {
    try {
        const { userId, gameId } = req.params;
        
        // Validación de IDs
        if (!mongoose.Types.ObjectId.isValid(userId) || !mongoose.Types.ObjectId.isValid(gameId)) {
            return res.status(400).json({ error: 'IDs inválidos' });
        }

        const usuario = await Usuario.findById(userId);
        if (!usuario) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        const eloData = usuario.elo.find(e => e.gameId.toString() === gameId);
        if (!eloData) {
            return res.status(404).json({ error: 'No se encontró ELO para este juego' });
        }

        res.json({
            elo: eloData.elo,
            rango: calcularRango(eloData.elo),
            ultimaActualizacion: eloData.ultimaActualizacion,
            historial: eloData.historial || []
        });
    } catch (error) {
        console.error('Error al obtener ELO:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// Endpoint mejorado para actualizar el ELO
app.put('/api/elo/update', authenticateToken, limiter, async (req, res) => {
    try {
        const { userId, gameId, newElo } = req.body;

        // Validaciones
        if (!userId || !gameId || newElo === undefined) {
            return res.status(400).json({ error: 'Faltan parámetros requeridos' });
        }

        if (!mongoose.Types.ObjectId.isValid(userId) || !mongoose.Types.ObjectId.isValid(gameId)) {
            return res.status(400).json({ error: 'IDs inválidos' });
        }

        if (newElo < 0) {
            return res.status(400).json({ error: 'El ELO no puede ser negativo' });
        }

        const usuario = await Usuario.findById(userId);
        if (!usuario) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        const eloIndex = usuario.elo.findIndex(e => e.gameId.toString() === gameId);
        if (eloIndex === -1) {
            usuario.elo.push({
                gameId,
                elo: newElo,
                ultimaActualizacion: new Date(),
                historial: []
            });
        } else {
            // Guardar el ELO anterior en el historial
            usuario.elo[eloIndex].historial = usuario.elo[eloIndex].historial || [];
            usuario.elo[eloIndex].historial.push({
                elo: usuario.elo[eloIndex].elo,
                fecha: usuario.elo[eloIndex].ultimaActualizacion
            });

            // Actualizar el ELO
            usuario.elo[eloIndex].elo = newElo;
            usuario.elo[eloIndex].ultimaActualizacion = new Date();
        }

        await usuario.save();

        res.json({
            mensaje: 'ELO actualizado correctamente',
            nuevoElo: newElo,
            rango: calcularRango(newElo)
        });
    } catch (error) {
        console.error('Error al actualizar ELO:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// Endpoint mejorado para registrar resultado de partida
app.post('/api/elo/match-result', authenticateToken, limiter, async (req, res) => {
    try {
        const { player1Id, player2Id, gameId, winner, isDraw } = req.body;

        // Validaciones
        if (!player1Id || !player2Id || !gameId || (!winner && !isDraw)) {
            return res.status(400).json({ error: 'Faltan parámetros requeridos' });
        }

        if (!mongoose.Types.ObjectId.isValid(player1Id) || 
            !mongoose.Types.ObjectId.isValid(player2Id) || 
            !mongoose.Types.ObjectId.isValid(gameId)) {
            return res.status(400).json({ error: 'IDs inválidos' });
        }

        const [player1, player2] = await Promise.all([
            Usuario.findById(player1Id),
            Usuario.findById(player2Id)
        ]);

        if (!player1 || !player2) {
            return res.status(404).json({ error: 'Uno o ambos jugadores no encontrados' });
        }

        const elo1 = player1.elo.find(e => e.gameId.toString() === gameId)?.elo || 1000;
        const elo2 = player2.elo.find(e => e.gameId.toString() === gameId)?.elo || 1000;

        let resultado;
        if (isDraw) {
            resultado = 'empate';
        } else if (winner === player1Id) {
            resultado = 'victoria1';
        } else {
            resultado = 'victoria2';
        }

        const { nuevoElo1, nuevoElo2 } = calcularElo(elo1, elo2, resultado);

        // Actualizar ELOs en una transacción
        const session = await mongoose.startSession();
        session.startTransaction();

        try {
            // Actualizar jugador 1
            const eloIndex1 = player1.elo.findIndex(e => e.gameId.toString() === gameId);
            if (eloIndex1 === -1) {
                player1.elo.push({
                    gameId,
                    elo: nuevoElo1,
                    ultimaActualizacion: new Date(),
                    historial: []
                });
            } else {
                player1.elo[eloIndex1].historial = player1.elo[eloIndex1].historial || [];
                player1.elo[eloIndex1].historial.push({
                    elo: player1.elo[eloIndex1].elo,
                    fecha: player1.elo[eloIndex1].ultimaActualizacion
                });
                player1.elo[eloIndex1].elo = nuevoElo1;
                player1.elo[eloIndex1].ultimaActualizacion = new Date();
            }

            // Actualizar jugador 2
            const eloIndex2 = player2.elo.findIndex(e => e.gameId.toString() === gameId);
            if (eloIndex2 === -1) {
                player2.elo.push({
                    gameId,
                    elo: nuevoElo2,
                    ultimaActualizacion: new Date(),
                    historial: []
                });
            } else {
                player2.elo[eloIndex2].historial = player2.elo[eloIndex2].historial || [];
                player2.elo[eloIndex2].historial.push({
                    elo: player2.elo[eloIndex2].elo,
                    fecha: player2.elo[eloIndex2].ultimaActualizacion
                });
                player2.elo[eloIndex2].elo = nuevoElo2;
                player2.elo[eloIndex2].ultimaActualizacion = new Date();
            }

            await Promise.all([
                player1.save({ session }),
                player2.save({ session })
            ]);

            await session.commitTransaction();

            res.json({
                mensaje: 'Resultado de partida registrado correctamente',
                player1: {
                    eloAnterior: elo1,
                    eloNuevo: nuevoElo1,
                    rango: calcularRango(nuevoElo1)
                },
                player2: {
                    eloAnterior: elo2,
                    eloNuevo: nuevoElo2,
                    rango: calcularRango(nuevoElo2)
                }
            });
        } catch (error) {
            await session.abortTransaction();
            throw error;
        } finally {
            session.endSession();
        }
    } catch (error) {
        console.error('Error al registrar resultado de partida:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// Función para calcular la compatibilidad entre usuarios basada en ELO
async function calcularCompatibilidad(usuario1Id, usuario2Id, juegoId) {
    try {
        const usuario1 = await Usuario.findById(usuario1Id);
        const usuario2 = await Usuario.findById(usuario2Id);

        if (!usuario1 || !usuario2) {
            throw new Error('Usuarios no encontrados');
        }

        const elo1 = usuario1.elo.find(e => e.gameId.toString() === juegoId.toString())?.elo || 1000;
        const elo2 = usuario2.elo.find(e => e.gameId.toString() === juegoId.toString())?.elo || 1000;

        // Diferencia máxima de ELO permitida (ajustable)
        const maxDiferenciaElo = 200;
        const diferenciaElo = Math.abs(elo1 - elo2);

        return {
            compatible: diferenciaElo <= maxDiferenciaElo,
            diferenciaElo,
            elo1,
            elo2
        };
    } catch (error) {
        console.error('Error al calcular compatibilidad:', error);
        throw error;
    }
}

// Función para buscar usuarios compatibles
async function buscarUsuariosCompatibles(usuarioId, juegoId) {
    try {
        const database = client.db(dbName);
        
        // Obtener el usuario actual
        const usuario = await database.collection('usuario').findOne({ IDUsuario: Number(usuarioId) });
        if (!usuario) {
            throw new Error('Usuario no encontrado');
        }

        // Obtener los juegos del usuario actual
        const userGames = usuario.Juegos || [];
        if (userGames.length === 0) {
            return []; // Si el usuario no tiene juegos, retornar array vacío
        }

        // Crear un conjunto de nombres de juegos para búsqueda más eficiente
        const userGameNames = new Set(userGames.map(game => game.nombre));

        // Buscar usuarios que tengan al menos un juego en común
        // Incluimos tanto usuarios reales como decoy
        const matchingUsers = await database.collection('usuario')
            .find({
                IDUsuario: { $ne: Number(usuarioId) }, // Excluir al usuario actual
                Juegos: {
                    $elemMatch: {
                        nombre: { $in: [...userGameNames] }
                    }
                },
                // No filtramos por tipo de usuario (real o decoy)
            })
            .project({
                IDUsuario: 1,
                Nombre: 1,
                FotoPerfil: 1,
                Juegos: 1,
                Edad: 1,
                Region: 1,
                Descripcion: 1,
                Genero: 1,
                isDecoy: 1 // Incluimos este campo para identificar usuarios decoy
            })
            .toArray();

        // Calcular el porcentaje de coincidencia y obtener rangos en común
        const usersWithMatchPercentage = matchingUsers.map(user => {
            const userGameNames = new Set(user.Juegos.map(g => g.nombre));
            const commonGames = [...userGameNames].filter(name => userGameNames.has(name));
            const matchPercentage = (commonGames.length / userGames.length) * 100;

            // Obtener rangos en común para cada juego
            const commonGamesWithRanks = commonGames.map(gameName => {
                const currentUserGame = userGames.find(g => g && g.nombre === gameName);
                const otherUserGame = user.Juegos.find(g => g && g.nombre === gameName);
                
                return {
                    nombre: gameName,
                    miRango: currentUserGame?.rango || "No disponible",
                    suRango: otherUserGame?.rango || "No disponible"
                };
            });

            return {
                id: user.IDUsuario,
                name: user.Nombre,
                profileImage: user.FotoPerfil || "default_profile",
                games: user.Juegos.map(game => ({
                    nombre: game.nombre,
                    rango: game.rango || "No disponible"
                })),
                age: user.Edad || 18,
                region: user.Region || "Not specified",
                description: user.Descripcion || "No description available",
                gender: user.Genero || "Not specified",
                matchPercentage: Math.round(matchPercentage),
                commonGames: commonGamesWithRanks,
                isDecoy: user.isDecoy || false // Identificar si es un usuario decoy
            };
        });

        // Ordenar por porcentaje de coincidencia
        const sortedUsers = usersWithMatchPercentage.sort((a, b) => b.matchPercentage - a.matchPercentage);

        return sortedUsers;
    } catch (error) {
        console.error('Error al buscar usuarios compatibles:', error);
        throw error;
    }
}

// Endpoint para buscar matches
app.get('/api/matches/buscar', authenticateToken, async (req, res) => {
    try {
        const { juegoId } = req.query;
        if (!juegoId) {
            return res.status(400).json({ error: 'ID de juego requerido' });
        }

        const usuariosCompatibles = await buscarUsuariosCompatibles(req.usuario.id, juegoId);
        res.json(usuariosCompatibles);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Endpoint para crear un match
app.post('/api/matches/crear', authenticateToken, async (req, res) => {
    try {
        const { usuario2Id, juegoId } = req.body;
        if (!usuario2Id || !juegoId) {
            return res.status(400).json({ error: 'Usuario2 ID y Juego ID son requeridos' });
        }

        // Verificar compatibilidad
        const compatibilidad = await calcularCompatibilidad(req.usuario.id, usuario2Id, juegoId);
        if (!compatibilidad.compatible) {
            return res.status(400).json({ 
                error: 'Usuarios no compatibles',
                diferenciaElo: compatibilidad.diferenciaElo
            });
        }

        // Crear el match
        const match = new Match({
            usuario1: req.usuario.id,
            usuario2: usuario2Id,
            juego: juegoId,
            estado: 'pendiente'
        });

        await match.save();
        res.status(201).json(match);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Endpoint para actualizar el estado de un match
app.put('/api/matches/:matchId/estado', authenticateToken, async (req, res) => {
    try {
        const { matchId } = req.params;
        const { estado } = req.body;

        if (!['aceptado', 'rechazado'].includes(estado)) {
            return res.status(400).json({ error: 'Estado inválido' });
        }

        const match = await Match.findById(matchId);
        if (!match) {
            return res.status(404).json({ error: 'Match no encontrado' });
        }

        // Verificar que el usuario es parte del match
        if (match.usuario1.toString() !== req.usuario.id && 
            match.usuario2.toString() !== req.usuario.id) {
            return res.status(403).json({ error: 'No autorizado' });
        }

        match.estado = estado;
        match.fechaActualizacion = new Date();
        await match.save();

        res.json(match);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Endpoint para registrar el resultado de un match
app.put('/api/matches/:matchId/resultado', authenticateToken, async (req, res) => {
    try {
        const { matchId } = req.params;
        const { ganadorId, puntuacionUsuario1, puntuacionUsuario2 } = req.body;

        const match = await Match.findById(matchId);
        if (!match) {
            return res.status(404).json({ error: 'Match no encontrado' });
        }

        // Verificar que el match está aceptado
        if (match.estado !== 'aceptado') {
            return res.status(400).json({ error: 'El match no está aceptado' });
        }

        // Verificar que el usuario es parte del match
        if (match.usuario1.toString() !== req.usuario.id && 
            match.usuario2.toString() !== req.usuario.id) {
            return res.status(403).json({ error: 'No autorizado' });
        }

        // Actualizar el resultado
        match.resultado = {
            ganador: ganadorId,
            puntuacionUsuario1,
            puntuacionUsuario2
        };
        match.estado = 'completado';
        match.fechaActualizacion = new Date();

        // Calcular y actualizar ELO
        const resultado = ganadorId === match.usuario1.toString() ? 1 : 0;
        await calcularElo(match.usuario1, match.usuario2, match.juego, resultado);

        await match.save();
        res.json(match);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Endpoint para obtener usuarios compatibles
app.get('/api/users/matching', async (req, res) => {
    try {
        const { userId, gameId } = req.query;
        
        if (!userId || !gameId) {
            return res.status(400).json({ error: 'Se requieren userId y gameId' });
        }

        const usuariosCompatibles = await buscarUsuariosCompatibles(userId, gameId);
        
        // Verificar si hay usuarios compatibles
        if (usuariosCompatibles.length === 0) {
            return res.status(404).json({ 
                message: 'No se encontraron usuarios compatibles',
                suggestions: [
                    'Intenta agregar más juegos a tu perfil',
                    'Ajusta tus preferencias de búsqueda',
                    'Revisa tu configuración de región'
                ]
            });
        }

        res.json(usuariosCompatibles);
    } catch (error) {
        console.error('Error al obtener usuarios compatibles:', error);
        res.status(500).json({ error: 'Error al buscar usuarios compatibles' });
    }
});

// Endpoint para reportar un usuario y eliminar el chat
app.post('/report-user', async (req, res) => {
    try {
        const { userId, reportedUserId, chatId } = req.body;
        
        if (!userId || !reportedUserId || !chatId) {
            return res.status(400).json({ error: 'Faltan datos requeridos' });
        }

        const database = client.db(dbName);
        const chats = database.collection('chat');
        const mensajes = database.collection('mensaje');
        const reportes = database.collection('reportes');
        const usuarios = database.collection('usuario');

        // Marcar al usuario como reportado
        await usuarios.updateOne(
            { IDUsuario: Number(reportedUserId) },
            { $set: { reportado: true, fechaReporte: new Date() } }
        );

        // Eliminar todos los mensajes del chat
        await mensajes.deleteMany({ IDChat: Number(chatId) });
        
        // En lugar de eliminar el chat, lo marcamos como oculto
        await chats.updateOne(
            { _id: Number(chatId) },
            { 
                $set: { 
                    oculto: true,
                    fechaOculto: new Date(),
                    motivoOculto: 'reportado'
                }
            }
        );

        // Crear el reporte
        const reporte = {
            reporterId: Number(userId),
            reportedUserId: Number(reportedUserId),
            chatId: Number(chatId),
            fecha: new Date(),
            estado: 'pendiente'
        };

        await reportes.insertOne(reporte);

        res.status(200).json({ 
            message: 'Usuario reportado y chat ocultado exitosamente',
            reporte: reporte
        });

    } catch (error) {
        console.error('Error al reportar usuario:', error);
        res.status(500).json({ error: 'Error al procesar el reporte' });
    }
});

// Manejo de errores global
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ 
        message: 'Error interno del servidor',
        error: process.env.NODE_ENV === 'development' ? err.message : undefined
    });
});

// Start server
connectDB().then(() => {
    app.listen(port, () => {
        console.log(`Servidor corriendo en puerto ${port}`);
    }).on('error', (err) => {
        if (err.code === 'EADDRINUSE') {
            console.error(`Error: El puerto ${port} ya está en uso. Intentando con el siguiente puerto...`);
            // Intentar con el siguiente puerto
            const newPort = port + 1;
            app.listen(newPort, () => {
                console.log(`Servidor corriendo en puerto ${newPort}`);
            });
        } else {
            console.error('Error al iniciar el servidor:', err);
        }
    });
}); 

// Middleware to update online status
const updateOnlineStatus = async (req, res, next) => {
    if (req.user) {
        try {
            await Usuario.findByIdAndUpdate(
                req.user._id,
                { 
                    isOnline: true,
                    lastSeen: new Date()
                }
            );
        } catch (error) {
            console.error('Error updating online status:', error);
        }
    }
    next();
};

// Apply online status middleware to all authenticated routes
app.use('/api', authenticateToken, updateOnlineStatus);

// Add route to handle user disconnection
app.post('/api/auth/logout', authenticateToken, async (req, res) => {
    try {
        await Usuario.findByIdAndUpdate(
            req.user._id,
            { 
                isOnline: false,
                lastSeen: new Date()
            }
        );
        res.json({ message: 'Logged out successfully' });
    } catch (error) {
        console.error('Error updating offline status:', error);
        res.status(500).json({ error: 'Error updating status' });
    }
});

// ... existing code ...

// Modify the profile endpoint to include online status
app.get('/api/auth/profile', authenticateToken, async (req, res) => {
    try {
        const user = await Usuario.findById(req.user._id).select('-Contraseña -resetToken -resetTokenExpiry');
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        res.json({
            ...user.toObject(),
            isOnline: user.isOnline,
            lastSeen: user.lastSeen
        });
    } catch (error) {
        console.error('Error fetching profile:', error);
        res.status(500).json({ error: 'Error fetching profile' });
    }
});

// ... existing code ...

// Configuración de imágenes prefabricadas para chat
const imagenesPrefabricadas = [
    {
        id: 1,
        nombre: "thumbs-up",
        url: "https://api.dicebear.com/7.x/bottts/png?seed=thumbs-up",
        descripcion: "Pulgar arriba"
    },
    {
        id: 2,
        nombre: "thumbs-down",
        url: "https://api.dicebear.com/7.x/bottts/png?seed=thumbs-down",
        descripcion: "Pulgar abajo"
    },
    {
        id: 3,
        nombre: "heart",
        url: "https://api.dicebear.com/7.x/bottts/png?seed=heart",
        descripcion: "Corazón"
    },
    {
        id: 4,
        nombre: "smile",
        url: "https://api.dicebear.com/7.x/bottts/png?seed=smile",
        descripcion: "Sonrisa"
    },
    {
        id: 5,
        nombre: "sad",
        url: "https://api.dicebear.com/7.x/bottts/png?seed=sad",
        descripcion: "Triste"
    }
];

// Endpoint para obtener imágenes prefabricadas
app.get('/api/chat/prefab-images', (req, res) => {
    res.json(imagenesPrefabricadas);
});

// Endpoint para enviar imagen prefabricada en el chat
app.post('/api/chat/send-prefab-image', async (req, res) => {
    try {
        const { chatId, userId, imageId } = req.body;

        if (!chatId || !userId || !imageId) {
            return res.status(400).json({ error: 'Faltan datos requeridos' });
        }

        const imagen = imagenesPrefabricadas.find(img => img.id === parseInt(imageId));
        if (!imagen) {
            return res.status(404).json({ error: 'Imagen no encontrada' });
        }

        const database = client.db(dbName);
        const mensajes = database.collection('mensaje');

        // Crear nuevo mensaje con la imagen prefabricada
        const nuevoMensaje = {
            IDMensaje: Date.now(),
            IDChat: parseInt(chatId),
            IDUsuario: parseInt(userId),
            Tipo: "imagen_prefab",
            Contenido: imagen.url,
            FechaEnvio: new Date(),
            Estado: "enviado"
        };

        await mensajes.insertOne(nuevoMensaje);

        res.status(200).json({
            message: 'Imagen enviada exitosamente',
            mensaje: nuevoMensaje
        });

    } catch (error) {
        console.error('Error al enviar imagen prefabricada:', error);
        res.status(500).json({ error: 'Error al enviar la imagen' });
    }
});

// ... existing code ...

// Endpoint para grabar y guardar audio
app.post('/api/chat/record-audio', upload.single('audio'), async (req, res) => {
    try {
        console.log('Iniciando grabación de audio...');
        console.log('Body:', req.body);
        console.log('File:', req.file);

        if (!req.file) {
            console.log('Error: No se ha subido ningún archivo de audio');
            return res.status(400).json({ error: 'No se ha subido ningún archivo de audio' });
        }

        const { chatId, userId } = req.body;
        if (!chatId || !userId) {
            console.log('Error: Faltan campos requeridos', { chatId, userId });
            return res.status(400).json({ 
                error: 'Se requiere chatId y userId',
                received: { chatId, userId }
            });
        }

        const database = client.db(dbName);
        const mensajes = database.collection('mensaje');
        const archivosMultimedia = database.collection('archivos_multimedia');

        // Mover el archivo a la carpeta de audios
        const audioFileName = `audio-${Date.now()}-${req.file.originalname}`;
        const audioPath = path.join(chatAudioDir, audioFileName);
        fs.renameSync(req.file.path, audioPath);

        // Obtener duración del audio
        const duracion = await new Promise((resolve, reject) => {
            ffmpeg.ffprobe(audioPath, (err, metadata) => {
                if (err) reject(err);
                resolve(metadata.format.duration);
            });
        });

        // Crear mensaje en la base de datos
        const lastMessage = await mensajes.findOne({}, { sort: { IDMensaje: -1 } });
        const IDMensaje = lastMessage ? (lastMessage.IDMensaje || 0) + 1 : 1;

        const fileUrl = `/uploads/chat/audio/${audioFileName}`;

        const mensaje = {
            IDMensaje: Number(IDMensaje),
            IDChat: Number(chatId),
            IDUsuario: Number(userId),
            Tipo: "audio",
            Contenido: fileUrl,
            FechaEnvio: new Date(),
            Estado: "enviado"
        };

        console.log('Insertando mensaje:', mensaje);
        await mensajes.insertOne(mensaje);

        // Crear documento en archivos_multimedia
        const lastFile = await archivosMultimedia.findOne({}, { sort: { IDArchivo: -1 } });
        const IDArchivo = lastFile ? (lastFile.IDArchivo || 0) + 1 : 1;

        const archivoMultimedia = {
            IDArchivo: Number(IDArchivo),
            IDMensaje: Number(IDMensaje),
            Tipo: "audio",
            URL: fileUrl,
            NombreArchivo: req.file.originalname,
            Tamaño: Number(req.file.size),
            Formato: req.file.mimetype,
            FechaSubida: new Date(),
            Duracion: duracion ? Number(duracion) : null
        };

        console.log('Insertando archivo multimedia:', archivoMultimedia);
        await archivosMultimedia.insertOne(archivoMultimedia);

        // Devolver respuesta con la URL completa
        const baseUrl = process.env.BASE_URL || 'http://localhost:3000';
        const fullUrl = `${baseUrl}${fileUrl}`;

        console.log('Audio guardado exitosamente');
        res.json({
            message: 'Audio guardado exitosamente',
            data: {
                url: fullUrl,
                type: "audio",
                duration: duracion,
                messageId: IDMensaje
            }
        });

    } catch (error) {
        console.error('Error al guardar audio:', error);
        res.status(500).json({ 
            error: 'Error al procesar el audio',
            details: error.message,
            stack: error.stack
        });
    }
});

// ... existing code ...

// Endpoint para obtener los chats de un usuario
app.get('/api/users/:userId/chats', async (req, res) => {
    try {
        const { userId } = req.params;
        
        const database = client.db(dbName);
        const chats = database.collection('chat');
        const usuarios = database.collection('usuario');
        const mensajes = database.collection('mensaje');
        
        // Obtener todos los chats donde el usuario es participante
        const userChats = await chats.find({
            usuarios: { $in: [Number(userId)] },
            oculto: { $ne: true }
        }).toArray();
        
        // Para cada chat, obtener la información del otro participante y el último mensaje
        const chatPreviews = await Promise.all(userChats.map(async (chat) => {
            const otherUserId = chat.usuarios.find(id => id !== Number(userId));
            const otherUser = await usuarios.findOne({ IDUsuario: otherUserId });
            
            // Obtener el último mensaje del chat
            const lastMessage = await mensajes.findOne(
                { IDChat: chat.IDChat },
                { sort: { FechaEnvio: -1 } }
            );
            
            return {
                id: chat.IDChat.toString(),
                username: otherUser?.Nombre ?? "Usuario desconocido",
                lastMessage: lastMessage?.Contenido ?? "No hay mensajes",
                timestamp: lastMessage?.FechaEnvio ? formatDate(lastMessage.FechaEnvio) : "Nunca",
                profileImage: otherUser?.FotoPerfil ?? "default-profile",
                participants: chat.usuarios.map(String.init),
                isHidden: false
            };
        }));
        
        res.json(chatPreviews);
    } catch (error) {
        console.error('Error al obtener chats:', error);
        res.status(500).json({ error: 'Error al obtener chats' });
    }
});

// Función auxiliar para formatear fechas
function formatDate(date) {
    const now = new Date();
    const messageDate = new Date(date);
    const diff = now - messageDate;
    
    // Si es hoy
    if (diff < 24 * 60 * 60 * 1000) {
        return messageDate.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    }
    // Si es ayer
    if (diff < 48 * 60 * 60 * 1000) {
        return "Ayer";
    }
    // Si es esta semana
    if (diff < 7 * 24 * 60 * 60 * 1000) {
        return messageDate.toLocaleDateString([], { weekday: 'long' });
    }
    // Si es este año
    if (messageDate.getFullYear() === now.getFullYear()) {
        return messageDate.toLocaleDateString([], { month: 'short', day: 'numeric' });
    }
    // Si es de otro año
    return messageDate.toLocaleDateString([], { year: 'numeric', month: 'short', day: 'numeric' });
}

// ... existing code ...

// Endpoint para obtener los puntos de un usuario
app.get('/api/user/points/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        const database = client.db(dbName);
        const usuarios = database.collection('usuario');
        
        const user = await usuarios.findOne({ IDUsuario: parseInt(userId) });
        if (!user) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        // Calcular puntos totales basados en el ELO de todos los juegos
        let totalPoints = 0;
        if (user.Juegos && Array.isArray(user.Juegos)) {
            totalPoints = user.Juegos.reduce((sum, game) => sum + (game.ELO || 0), 0);
        }

        res.json({ points: totalPoints });
    } catch (error) {
        console.error('Error al obtener puntos:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// ... existing code ...

// Endpoint para manejar likes y matches con usuarios de prueba
app.post('/api/matches/like', authenticateToken, async (req, res) => {
    try {
        const { likedUserId } = req.body;
        const userId = req.user.id;

        // Obtener los usuarios
        const user = await db.collection('users').findOne({ id: userId });
        const likedUser = await db.collection('users').findOne({ id: likedUserId });

        if (!user || !likedUser) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        // Crear el match
        const match = {
            user1Id: userId,
            user2Id: likedUserId,
            createdAt: new Date()
        };

        // Guardar el match en la base de datos
        await db.collection('matches').insertOne(match);

        // Crear un chat entre los usuarios
        const chat = {
            participants: [userId, likedUserId],
            messages: [],
            createdAt: new Date()
        };

        // Guardar el chat en la base de datos
        await db.collection('chats').insertOne(chat);

        res.json({
            success: true,
            match: {
                id: match._id,
                user1: user,
                user2: likedUser
            },
            chat: {
                id: chat._id
            }
        });
    } catch (error) {
        console.error('Error al procesar el like:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// ... existing code ...