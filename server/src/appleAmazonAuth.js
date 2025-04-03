const passport = require('passport');
const AppleStrategy = require('passport-apple').Strategy;
const AmazonStrategy = require('passport-amazon').Strategy;
const jwt = require('jsonwebtoken');
require('dotenv').config();

// Configuración de la estrategia de Apple
passport.use(new AppleStrategy({
    clientID: process.env.APPLE_CLIENT_ID,
    teamID: process.env.APPLE_TEAM_ID,
    keyID: process.env.APPLE_KEY_ID,
    privateKeyPath: process.env.APPLE_PRIVATE_KEY_PATH,
    callbackURL: `${process.env.BASE_URL}/api/auth/apple/callback`,
    scope: ['name', 'email']
}, async (accessToken, refreshToken, profile, done) => {
    try {
        const user = {
            appleId: profile.id,
            email: profile.email,
            name: profile.name ? `${profile.name.firstName} ${profile.name.lastName}` : null
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
    callbackURL: `${process.env.BASE_URL}/api/auth/amazon/callback`
}, async (accessToken, refreshToken, profile, done) => {
    try {
        const user = {
            amazonId: profile.id,
            email: profile.emails[0].value,
            name: profile.displayName
        };
        
        return done(null, user);
    } catch (error) {
        return done(error, null);
    }
}));

// Función para generar JWT para usuarios de Apple
function generateAppleJWT(user) {
    return jwt.sign(
        {
            appleId: user.appleId,
            email: user.email,
            name: user.name
        },
        process.env.JWT_SECRET,
        { expiresIn: '24h' }
    );
}

// Función para generar JWT para usuarios de Amazon
function generateAmazonJWT(user) {
    return jwt.sign(
        {
            amazonId: user.amazonId,
            email: user.email,
            name: user.name
        },
        process.env.JWT_SECRET,
        { expiresIn: '24h' }
    );
}

module.exports = {
    passport,
    generateAppleJWT,
    generateAmazonJWT
}; 