const Usuario = require('../models/usuario');
const { sendVerificationCode } = require('../services/emailService');

// Función para generar un código de verificación aleatorio
const generateVerificationCode = () => {
    return Math.floor(100000 + Math.random() * 900000).toString();
};

// Función para enviar el email de verificación
const sendVerificationEmail = async (req, res) => {
    try {
        const { email } = req.body;
        
        // Buscar el usuario por email
        const usuario = await Usuario.findOne({ Email: email });
        if (!usuario) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        // Generar código de verificación
        const verificationCode = generateVerificationCode();
        const verificationCodeExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutos

        // Actualizar el usuario con el código y su expiración
        usuario.verificationCode = verificationCode;
        usuario.verificationCodeExpires = verificationCodeExpires;
        await usuario.save();

        // Enviar el código por email
        await sendVerificationCode(email, verificationCode);

        res.status(200).json({ message: 'Código de verificación enviado' });
    } catch (error) {
        console.error('Error al enviar el código de verificación:', error);
        res.status(500).json({ message: 'Error al enviar el código de verificación' });
    }
};

// Función para verificar el código
const verifyCode = async (req, res) => {
    try {
        const { email, code } = req.body;
        
        // Buscar el usuario por email
        const usuario = await Usuario.findOne({ Email: email });
        if (!usuario) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        // Verificar el código y su expiración
        if (usuario.verificationCode !== code) {
            return res.status(400).json({ message: 'Código de verificación incorrecto' });
        }

        if (usuario.verificationCodeExpires < new Date()) {
            return res.status(400).json({ message: 'El código de verificación ha expirado' });
        }

        // Marcar el usuario como verificado
        usuario.verified = true;
        usuario.verificationCode = null;
        usuario.verificationCodeExpires = null;
        await usuario.save();

        res.status(200).json({ message: 'Email verificado correctamente' });
    } catch (error) {
        console.error('Error al verificar el código:', error);
        res.status(500).json({ message: 'Error al verificar el código' });
    }
};

module.exports = {
    // ... existing code ...
    sendVerificationEmail,
    verifyCode
}; 