const mongoose = require('mongoose');

const matchSchema = new mongoose.Schema({
    usuario1: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Usuario',
        required: true
    },
    usuario2: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Usuario',
        required: true
    },
    juego: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Juego',
        required: true
    },
    estado: {
        type: String,
        enum: ['pendiente', 'aceptado', 'rechazado', 'completado'],
        default: 'pendiente'
    },
    fechaCreacion: {
        type: Date,
        default: Date.now
    },
    fechaActualizacion: {
        type: Date,
        default: Date.now
    },
    resultado: {
        ganador: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Usuario'
        },
        puntuacionUsuario1: Number,
        puntuacionUsuario2: Number
    }
});

// Índices para búsquedas eficientes
matchSchema.index({ usuario1: 1, estado: 1 });
matchSchema.index({ usuario2: 1, estado: 1 });
matchSchema.index({ juego: 1, estado: 1 });

module.exports = mongoose.model('Match', matchSchema); 