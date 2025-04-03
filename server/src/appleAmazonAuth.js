const passport = require('passport');
const AppleStrategy = require('passport-apple').Strategy;
const AmazonStrategy = require('passport-amazon').Strategy;
const jwt = require('jsonwebtoken');
const fs = require('fs');
require('dotenv').config();

// Validación de variables de entorno
const validateEnvVars = () => {
    const requiredVars = [
        'APPLE_CLIENT_ID',
        'APPLE_TEAM_ID',
        'APPLE_KEY_ID',
        'APPLE_PRIVATE_KEY_PATH',
        'AMAZON_CLIENT_ID',
        'AMAZON_CLIENT_SECRET',
        'JWT_SECRET'
    ];

    const missingVars = requiredVars.filter(varName => !process.env[varName]);
    if (missingVars.length > 0) {
        throw new Error(`Missing required environment variables: ${missingVars.join(', ')}`);
    }

    // Verificar que el archivo de clave privada existe
    if (!fs.existsSync(process.env.APPLE_PRIVATE_KEY_PATH)) {
        throw new Error(`Apple private key file not found at: ${process.env.APPLE_PRIVATE_KEY_PATH}`);
    }
};

try {
    validateEnvVars();
} catch (error) {
    console.error('Configuration error:', error);
    process.exit(1);
}

// Configuración de la estrategia de Apple
passport.use(new AppleStrategy({
    clientID: process.env.APPLE_CLIENT_ID,
    teamID: process.env.APPLE_TEAM_ID,
    keyID: process.env.APPLE_KEY_ID,
    privateKeyPath: process.env.APPLE_PRIVATE_KEY_PATH,
    callbackURL: `${process.env.BASE_URL}/api/auth/apple/callback`,
    scope: ['name', 'email'],
    passReqToCallback: true
}, async (req, accessToken, refreshToken, profile, done) => {
    try {
        if (!profile || !profile.id) {
            return done(new Error('Invalid Apple profile'), null);
        }

        const user = {
            appleId: profile.id,
            email: profile.email || null,
            name: profile.name ? `${profile.name.firstName} ${profile.name.lastName}` : null,
            provider: 'apple'
        };
        
        return done(null, user);
    } catch (error) {
        return done(error, null);
    }
}));

// Configuración de la estrategia de Amazon
passport.use(new AmazonStrategy({
    clientID: process.env.AMAZON_CLIENT_ID,
    clientSecret: process.env.AMAZON_CLIENT_SECRET,
    callbackURL: `${process.env.BASE_URL}/api/auth/amazon/callback`,
    passReqToCallback: true
}, async (req, accessToken, refreshToken, profile, done) => {
    try {
        if (!profile || !profile.id) {
            return done(new Error('Invalid Amazon profile'), null);
        }

        const user = {
            amazonId: profile.id,
            email: profile.emails?.[0]?.value || null,
            name: profile.displayName || null,
            provider: 'amazon'
        };
        
        return done(null, user);
    } catch (error) {
        return done(error, null);
    }
}));

// Función para generar JWT para usuarios de Apple
function generateAppleJWT(user) {
    if (!user || !user.appleId) {
        throw new Error('Invalid user data for Apple JWT generation');
    }

    return jwt.sign(
        {
            userId: user._id,
            appleId: user.appleId,
            email: user.email,
            name: user.name,
            provider: 'apple'
        },
        process.env.JWT_SECRET,
        { expiresIn: '24h' }
    );
}

// Función para generar JWT para usuarios de Amazon
function generateAmazonJWT(user) {
    if (!user || !user.amazonId) {
        throw new Error('Invalid user data for Amazon JWT generation');
    }

    return jwt.sign(
        {
            userId: user._id,
            amazonId: user.amazonId,
            email: user.email,
            name: user.name,
            provider: 'amazon'
        },
        process.env.JWT_SECRET,
        { expiresIn: '24h' }
    );
}

// Middleware para verificar la autenticación
const isAuthenticated = (req, res, next) => {
    if (req.isAuthenticated()) {
        return next();
    }
    res.status(401).json({ error: 'Not authenticated' });
};

module.exports = {
    passport,
    generateAppleJWT,
    generateAmazonJWT,
    isAuthenticated
}; 