const express = require('express');
const router = express.Router();
const { verifyGoogleToken, generateJWT } = require('../googleAuth');
const { passport: steamPassport, generateSteamJWT } = require('../steamAuth');
const { passport: appleAmazonPassport, generateAppleJWT, generateAmazonJWT } = require('../appleAmazonAuth');
const { MongoClient } = require('mongodb');
require('dotenv').config();

const client = new MongoClient(process.env.MONGODB_URI);
const db = client.db(process.env.DB_NAME);

// Middleware para manejar errores de autenticación
const handleAuthError = (res, error, provider) => {
    console.error(`${provider} authentication error:`, error);
    res.redirect(`${process.env.FRONTEND_URL}/login?error=auth_failed&provider=${provider}`);
};

// Middleware para validar tokens
const validateToken = (req, res, next) => {
    const token = req.body.token;
    if (!token) {
        return res.status(400).json({ error: 'Token is required' });
    }
    next();
};

// Ruta para autenticación con Google
router.post('/google', validateToken, async (req, res) => {
    try {
        const { token } = req.body;
        const googleUser = await verifyGoogleToken(token);
        
        if (!googleUser) {
            return res.status(401).json({ error: 'Invalid Google token' });
        }

        let user = await db.collection('users').findOne({ email: googleUser.email });
        
        if (!user) {
            user = {
                email: googleUser.email,
                name: googleUser.name,
                picture: googleUser.picture,
                googleId: googleUser.googleId,
                createdAt: new Date(),
                lastLogin: new Date(),
                provider: 'google'
            };
            
            const result = await db.collection('users').insertOne(user);
            user._id = result.insertedId;
        } else {
            // Actualizar última conexión
            await db.collection('users').updateOne(
                { _id: user._id },
                { $set: { lastLogin: new Date() } }
            );
        }

        const jwtToken = generateJWT(user);
        
        res.json({
            token: jwtToken,
            user: {
                id: user._id,
                email: user.email,
                name: user.name,
                picture: user.picture,
                provider: user.provider
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
            const steamUser = req.user;
            
            let user = await db.collection('users').findOne({ steamId: steamUser.steamId });
            
            if (!user) {
                user = {
                    steamId: steamUser.steamId,
                    displayName: steamUser.displayName,
                    profileUrl: steamUser.profileUrl,
                    avatar: steamUser.avatar,
                    createdAt: new Date(),
                    lastLogin: new Date(),
                    provider: 'steam'
                };
                
                const result = await db.collection('users').insertOne(user);
                user._id = result.insertedId;
            } else {
                await db.collection('users').updateOne(
                    { _id: user._id },
                    { $set: { lastLogin: new Date() } }
                );
            }

            const jwtToken = generateSteamJWT(user);
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
            const appleUser = req.user;
            
            let user = await db.collection('users').findOne({ appleId: appleUser.appleId });
            
            if (!user) {
                user = {
                    appleId: appleUser.appleId,
                    email: appleUser.email,
                    name: appleUser.name,
                    createdAt: new Date(),
                    lastLogin: new Date(),
                    provider: 'apple'
                };
                
                const result = await db.collection('users').insertOne(user);
                user._id = result.insertedId;
            } else {
                await db.collection('users').updateOne(
                    { _id: user._id },
                    { $set: { lastLogin: new Date() } }
                );
            }

            const jwtToken = generateAppleJWT(user);
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
            const amazonUser = req.user;
            
            let user = await db.collection('users').findOne({ amazonId: amazonUser.amazonId });
            
            if (!user) {
                user = {
                    amazonId: amazonUser.amazonId,
                    email: amazonUser.email,
                    name: amazonUser.name,
                    createdAt: new Date(),
                    lastLogin: new Date(),
                    provider: 'amazon'
                };
                
                const result = await db.collection('users').insertOne(user);
                user._id = result.insertedId;
            } else {
                await db.collection('users').updateOne(
                    { _id: user._id },
                    { $set: { lastLogin: new Date() } }
                );
            }

            const jwtToken = generateAmazonJWT(user);
            res.redirect(`${process.env.FRONTEND_URL}/auth/callback?token=${jwtToken}`);
        } catch (error) {
            handleAuthError(res, error, 'amazon');
        }
    }
);

// Ruta para obtener el estado de autenticación
router.get('/status', async (req, res) => {
    try {
        const token = req.headers.authorization?.split(' ')[1];
        if (!token) {
            return res.status(401).json({ error: 'No token provided' });
        }

        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const user = await db.collection('users').findOne({ _id: new ObjectId(decoded.userId) });

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        res.json({
            isAuthenticated: true,
            user: {
                id: user._id,
                email: user.email,
                name: user.name,
                provider: user.provider,
                lastLogin: user.lastLogin
            }
        });
    } catch (error) {
        res.status(401).json({ error: 'Invalid token' });
    }
});

module.exports = router; 