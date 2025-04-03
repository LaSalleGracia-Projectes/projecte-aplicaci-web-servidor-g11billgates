const express = require('express');
const router = express.Router();
const { verifyGoogleToken } = require('../googleAuth');

// Ruta de prueba para verificar el token de Google
router.post('/verify-google-token', async (req, res) => {
    try {
        const { token } = req.body;
        
        if (!token) {
            return res.status(400).json({ error: 'Token is required' });
        }

        const googleUser = await verifyGoogleToken(token);
        
        res.json({
            success: true,
            message: 'Token verificado correctamente',
            user: {
                email: googleUser.email,
                name: googleUser.name,
                picture: googleUser.picture
            }
        });
    } catch (error) {
        console.error('Error en la verificación:', error);
        res.status(401).json({
            success: false,
            error: 'Token inválido o expirado'
        });
    }
});

module.exports = router; 