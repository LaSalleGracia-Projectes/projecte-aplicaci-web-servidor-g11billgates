const express = require('express');
const router = express.Router();
const { verifyGoogleToken } = require('../googleAuth');
const { passport: steamPassport } = require('../steamAuth');
const { passport: appleAmazonPassport } = require('../appleAmazonAuth');
const { verifyToken, logAuthAttempt, rateLimiter } = require('../middleware/auth');
const { generateUserToken, normalizeUserData, upsertUser, handleAuthError } = require('../utils/authUtils');

// Middleware común para todas las rutas de autenticación
router.use(rateLimiter.check);
router.use(logAuthAttempt);

// Ruta para verificar el estado de autenticación
router.get('/status', verifyToken, (req, res) => {
    res.json({
        authenticated: true,
        user: {
            id: req.user.userId,
            email: req.user.email,
            name: req.user.name,
            provider: req.user.provider,
            roles: req.user.roles
        }
    });
});

// Ruta para autenticación con Google
router.post('/google', async (req, res) => {
    try {
        const { token } = req.body;
        const googleProfile = await verifyGoogleToken(token);
        
        if (!googleProfile) {
            return res.status(401).json({ error: 'Invalid Google token' });
        }

        const userData = normalizeUserData(googleProfile, 'google');
        const user = await upsertUser(userData);
        const jwtToken = generateUserToken(user, 'google');
        
        res.json({
            token: jwtToken,
            user: {
                id: user._id,
                email: user.email,
                name: user.name,
                picture: user.picture,
                provider: user.provider,
                roles: user.roles
            }
        });
    } catch (error) {
        handleAuthError(res, error, 'google');
    }
});

// Rutas para autenticación con Steam
router.get('/steam', steamPassport.authenticate('steam'));

router.get('/steam/return', 
    steamPassport.authenticate('steam', { failureRedirect: '/login' }),
    async (req, res) => {
        try {
            const userData = normalizeUserData(req.user, 'steam');
            const user = await upsertUser(userData);
            const jwtToken = generateUserToken(user, 'steam');
            
            res.redirect(`${process.env.FRONTEND_URL}/auth/callback?token=${jwtToken}`);
        } catch (error) {
            handleAuthError(res, error, 'steam');
        }
    }
);

// Rutas para autenticación con Apple
router.get('/apple', appleAmazonPassport.authenticate('apple'));

router.post('/apple/callback', 
    appleAmazonPassport.authenticate('apple', { failureRedirect: '/login' }),
    async (req, res) => {
        try {
            const userData = normalizeUserData(req.user, 'apple');
            const user = await upsertUser(userData);
            const jwtToken = generateUserToken(user, 'apple');
            
            res.redirect(`${process.env.FRONTEND_URL}/auth/callback?token=${jwtToken}`);
        } catch (error) {
            handleAuthError(res, error, 'apple');
        }
    }
);

// Rutas para autenticación con Amazon
router.get('/amazon', appleAmazonPassport.authenticate('amazon', {
    scope: ['profile', 'postal_code']
}));

router.get('/amazon/callback', 
    appleAmazonPassport.authenticate('amazon', { failureRedirect: '/login' }),
    async (req, res) => {
        try {
            const userData = normalizeUserData(req.user, 'amazon');
            const user = await upsertUser(userData);
            const jwtToken = generateUserToken(user, 'amazon');
            
            res.redirect(`${process.env.FRONTEND_URL}/auth/callback?token=${jwtToken}`);
        } catch (error) {
            handleAuthError(res, error, 'amazon');
        }
    }
);

// Ruta para cerrar sesión
router.post('/logout', verifyToken, (req, res) => {
    req.logout();
    res.json({ message: 'Logged out successfully' });
});

module.exports = router; 