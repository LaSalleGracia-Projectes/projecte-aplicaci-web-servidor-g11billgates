const express = require('express');
const router = express.Router();
const { verifyGoogleToken, generateJWT } = require('../googleAuth');
const { MongoClient } = require('mongodb');
require('dotenv').config();

const client = new MongoClient(process.env.MONGODB_URI);
const db = client.db(process.env.DB_NAME);

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

module.exports = router; 