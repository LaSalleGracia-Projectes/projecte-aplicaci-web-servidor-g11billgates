const express = require('express');
const router = express.Router();
const { verifyGoogleToken, generateJWT } = require('../googleAuth');
const { passport, generateSteamJWT } = require('../steamAuth');
const { MongoClient } = require('mongodb');
require('dotenv').config();

const client = new MongoClient(process.env.MONGODB_URI);
const db = client.db(process.env.DB_NAME);

// Ruta para autenticación con Google
router.post('/google', async (req, res) => {
    try {
        const { token } = req.body;
        
        if (!token) {
            return res.status(400).json({ error: 'Token is required' });
        }

        const googleUser = await verifyGoogleToken(token);
        
        // Check if user exists
        let user = await db.collection('users').findOne({ email: googleUser.email });
        
        if (!user) {
            // Create new user
            user = {
                email: googleUser.email,
                name: googleUser.name,
                picture: googleUser.picture,
                googleId: googleUser.googleId,
                createdAt: new Date()
            };
            
            const result = await db.collection('users').insertOne(user);
            user._id = result.insertedId;
        }

        // Generate JWT
        const jwtToken = generateJWT(user);
        
        res.json({
            token: jwtToken,
            user: {
                id: user._id,
                email: user.email,
                name: user.name,
                picture: user.picture
            }
        });
    } catch (error) {
        console.error('Authentication error:', error);
        res.status(500).json({ error: 'Authentication failed' });
    }
});

// Rutas para autenticación con Steam
router.get('/steam', passport.authenticate('steam'));

router.get('/steam/return', 
    passport.authenticate('steam', { failureRedirect: '/login' }),
    async (req, res) => {
        try {
            const steamUser = req.user;
            
            // Check if user exists
            let user = await db.collection('users').findOne({ steamId: steamUser.steamId });
            
            if (!user) {
                // Create new user
                user = {
                    steamId: steamUser.steamId,
                    displayName: steamUser.displayName,
                    profileUrl: steamUser.profileUrl,
                    avatar: steamUser.avatar,
                    createdAt: new Date()
                };
                
                const result = await db.collection('users').insertOne(user);
                user._id = result.insertedId;
            }

            // Generate JWT
            const jwtToken = generateSteamJWT(user);
            
            // Redirigir al frontend con el token
            res.redirect(`${process.env.FRONTEND_URL}/auth/callback?token=${jwtToken}`);
        } catch (error) {
            console.error('Steam authentication error:', error);
            res.redirect(`${process.env.FRONTEND_URL}/login?error=auth_failed`);
        }
    }
);

module.exports = router; 