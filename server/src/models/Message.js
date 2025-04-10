const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
    chatId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Chat',
        required: true
    },
    senderId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Usuario',
        required: true
    },
    text: {
        type: String,
        default: ''
    },
    tipo: {
        type: String,
        enum: ['texto', 'image', 'audio', 'video'],
        default: 'texto'
    },
    mediaUrl: {
        type: String
    },
    mediaType: {
        type: String
    },
    fileName: {
        type: String
    },
    fileSize: {
        type: Number
    },
    timestamp: {
        type: Date,
        default: Date.now
    },
    estado: {
        type: String,
        enum: ['enviado', 'entregado', 'leido'],
        default: 'enviado'
    }
});

module.exports = mongoose.model('Message', messageSchema); 