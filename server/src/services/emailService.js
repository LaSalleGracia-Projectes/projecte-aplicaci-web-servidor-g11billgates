const nodemailer = require('nodemailer');

// Configuración del transporter
const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASSWORD
    }
});

// Función para enviar correo de recuperación de contraseña
async function sendPasswordResetEmail(email, resetToken) {
    const resetUrl = `${process.env.FRONTEND_URL}/reset-password?token=${resetToken}`;
    
    const mailOptions = {
        from: process.env.EMAIL_USER,
        to: email,
        subject: 'Recuperación de contraseña - TeamUP',
        html: `
            <h1>Recuperación de contraseña</h1>
            <p>Hemos recibido una solicitud para restablecer tu contraseña.</p>
            <p>Si no has solicitado este cambio, puedes ignorar este correo.</p>
            <p>Para restablecer tu contraseña, haz clic en el siguiente enlace:</p>
            <a href="${resetUrl}">Restablecer contraseña</a>
            <p>Este enlace expirará en 1 hora.</p>
        `
    };

    try {
        await transporter.sendMail(mailOptions);
        return true;
    } catch (error) {
        console.error('Error al enviar el correo:', error);
        throw error;
    }
}

module.exports = {
    sendPasswordResetEmail
}; 