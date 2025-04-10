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
        const dir = path.join(__dirname, '../../uploads/chat');
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
        }
        cb(null, dir);
    },
    filename: function (req, file, cb) {
        const uniqueFileName = `${uuidv4()}${path.extname(file.originalname)}`;
        cb(null, uniqueFileName);
    }
});

// Filtro para tipos de archivos permitidos
const fileFilter = (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/gif'];
    if (allowedTypes.includes(file.mimetype)) {
        cb(null, true);
    } else {
        cb(new Error('Tipo de archivo no permitido. Solo se permiten imágenes (JPEG, PNG, GIF)'), false);
    }
};

const upload = multer({
    storage: storage,
    fileFilter: fileFilter,
    limits: {
        fileSize: 5 * 1024 * 1024 // 5MB máximo
    }
});

// Manejador de errores para multer
const handleMulterError = (err, req, res, next) => {
    if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
            return res.status(400).json({ message: 'El archivo es demasiado grande. Máximo 5MB.' });
        }
        return res.status(400).json({ message: 'Error al subir el archivo.' });
    } else if (err) {
        return res.status(400).json({ message: err.message });
    }
    next();
};

// Enviar mensaje con o sin imagen
router.post('/send', upload.single('image'), handleMulterError, async (req, res) => {
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
            tipo: req.file ? 'imagen' : 'texto',
            estado: 'enviado'
        };

        // Si hay una imagen, añadir la ruta al mensaje
        if (req.file) {
            message.image = `/uploads/chat/${req.file.filename}`;
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