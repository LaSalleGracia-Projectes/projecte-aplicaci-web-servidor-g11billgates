const mongoose = require('mongoose');

const usuarioSchema = new mongoose.Schema({
    nombre: {
        type: String,
        required: true
    },
    email: {
        type: String,
        required: true,
        unique: true
    },
    password: {
        type: String,
        required: true
    },
    elo: [{
        gameId: {
            type: mongoose.Schema.Types.ObjectId,
            required: true
        },
        elo: {
            type: Number,
            default: 1000
        },
        ultimaActualizacion: {
            type: Date,
            default: Date.now
        },
        historial: [{
            elo: Number,
            fecha: Date
        }]
    }],
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Usuario', usuarioSchema); 