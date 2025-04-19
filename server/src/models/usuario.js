const mongoose = require('mongoose');

const usuarioSchema = new mongoose.Schema({
    IDUsuario: { type: String, required: true, unique: true },
    Nombre: { type: String, required: true },
    Correo: { type: String, required: true, unique: true },
    Contraseña: { type: String, required: true },
    FotoPerfil: { type: String },
    Juegos: [{
        IDJuego: { type: String, required: true },
        Nombre: { type: String, required: true },
        Nivel: { type: String, required: true },
        ELO: { type: Number, required: true }
    }],
    resetToken: { type: String },
    resetTokenExpiry: { type: Date },
    verificationCode: { type: String, default: null },
    verificationCodeExpires: { type: Date, default: null },
    verified: { type: Boolean, default: false },
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Usuario', usuarioSchema); 