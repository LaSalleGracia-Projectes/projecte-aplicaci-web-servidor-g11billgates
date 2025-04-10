const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');
const Message = require('../models/Message');
const Chat = require('../models/Chat');

// Configuración de multer para el almacenamiento de archivos
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        let uploadDir;
        if (file.mimetype.startsWith('image/')) {
            uploadDir = path.join(__dirname, '../../uploads/chat/images');
        } else if (file.mimetype.startsWith('audio/')) {
            uploadDir = path.join(__dirname, '../../uploads/chat/audio');
        } else if (file.mimetype.startsWith('video/')) {
            uploadDir = path.join(__dirname, '../../uploads/chat/video');
        } else {
            uploadDir = path.join(__dirname, '../../uploads/chat/other');
        }
        
        if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
        }
        cb(null, uploadDir);
    },
    filename: function (req, file, cb) {
        const uniqueFileName = `${Date.now()}-${uuidv4()}${path.extname(file.originalname)}`;
        cb(null, uniqueFileName);
    }
});

// Filtro para tipos de archivos permitidos
const fileFilter = (req, file, cb) => {
    const allowedTypes = {
        'image': ['image/jpeg', 'image/png', 'image/gif', 'image/webp'],
        'audio': ['audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/mp4', 'audio/webm'],
        'video': ['video/mp4', 'video/webm', 'video/quicktime', 'video/x-msvideo']
    };

    const isAllowed = Object.values(allowedTypes).some(types => types.includes(file.mimetype));
    
    if (isAllowed) {
        cb(null, true);
    } else {
        cb(new Error('Tipo de archivo no permitido. Solo se permiten imágenes (JPEG, PNG, GIF, WEBP), audios (MP3, WAV, OGG, MP4, WEBM) y videos (MP4, WEBM, MOV, AVI)'), false);
    }
};

const upload = multer({
    storage: storage,
    fileFilter: fileFilter,
    limits: {
        fileSize: 50 * 1024 * 1024 // 50MB máximo para permitir videos
    }
});

// Manejador de errores para multer
const handleMulterError = (err, req, res, next) => {
    if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
            return res.status(400).json({ message: 'El archivo es demasiado grande. Máximo 50MB.' });
        }
        return res.status(400).json({ message: 'Error al subir el archivo.' });
    } else if (err) {
        return res.status(400).json({ message: err.message });
    }
    next();
};

// Enviar mensaje con o sin archivo multimedia
router.post('/send', upload.single('file'), handleMulterError, async (req, res) => {
    try {
        const { chatId, senderId, text } = req.body;
        
        if (!chatId || !senderId) {
            return res.status(400).json({ message: 'Se requieren chatId y senderId' });
        }

        // Crear el objeto del mensaje
        const message = {
            chatId,
            senderId,
            text: text || '',
            timestamp: new Date(),
            tipo: 'texto',
            estado: 'enviado'
        };

        // Si hay un archivo, determinar su tipo y añadir la ruta
        if (req.file) {
            const fileType = req.file.mimetype.split('/')[0]; // 'image', 'audio' o 'video'
            const relativePath = path.relative(
                path.join(__dirname, '../../'),
                req.file.path
            );
            
            message.tipo = fileType;
            message.mediaUrl = `/${relativePath}`;
            message.mediaType = req.file.mimetype;
            message.fileName = req.file.originalname;
            message.fileSize = req.file.size;
        }

        // Guardar el mensaje en la base de datos
        const newMessage = await Message.create(message);

        // Actualizar el último mensaje del chat
        await Chat.findByIdAndUpdate(chatId, {
            lastMessage: newMessage._id,
            updatedAt: new Date()
        });

        res.status(201).json(newMessage);
    } catch (error) {
        console.error('Error al enviar mensaje:', error);
        // Si hay un error y se subió un archivo, eliminarlo
        if (req.file) {
            fs.unlink(req.file.path, (err) => {
                if (err) console.error('Error al eliminar archivo:', err);
            });
        }
        res.status(500).json({ message: 'Error al enviar el mensaje' });
    }
});

// Obtener mensajes de un chat
router.get('/:chatId', async (req, res) => {
    try {
        const { chatId } = req.params;
        const messages = await Message.find({ chatId })
            .sort({ timestamp: 1 });
        res.json(messages);
    } catch (error) {
        console.error('Error al obtener mensajes:', error);
        res.status(500).json({ message: 'Error al obtener los mensajes' });
    }
});

module.exports = router; 