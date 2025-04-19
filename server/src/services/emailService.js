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
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                <h1 style="color: #4a90e2;">Recuperación de contraseña</h1>
                <p>Hemos recibido una solicitud para restablecer tu contraseña en TeamUP.</p>
                <p>Si no has solicitado este cambio, puedes ignorar este correo.</p>
                <p>Para restablecer tu contraseña, haz clic en el siguiente enlace:</p>
                <div style="text-align: center; margin: 20px 0;">
                    <a href="${resetUrl}" style="background-color: #4a90e2; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Restablecer contraseña</a>
                </div>
                <p>O copia y pega este enlace en tu navegador:</p>
                <p style="word-break: break-all;">${resetUrl}</p>
                <p>Este enlace expirará en 1 hora.</p>
                <hr style="margin: 20px 0; border: none; border-top: 1px solid #eee;">
                <p style="color: #666; font-size: 12px;">Este es un correo automático, por favor no respondas a este mensaje.</p>
            </div>
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

// Función para enviar el código de verificación
const sendVerificationCode = async (email, code) => {
    try {
        const mailOptions = {
            from: process.env.EMAIL_USER,
            to: email,
            subject: 'Código de verificación - TeamUP',
            html: `
                <h1>Verificación de email</h1>
                <p>Tu código de verificación es: <strong>${code}</strong></p>
                <p>Este código expirará en 10 minutos.</p>
                <p>Si no has solicitado este código, por favor ignora este email.</p>
            `
        };

        await transporter.sendMail(mailOptions);
        return true;
    } catch (error) {
        console.error('Error al enviar el email:', error);
        return false;
    }
};

module.exports = {
    sendPasswordResetEmail,
    sendVerificationCode
}; 