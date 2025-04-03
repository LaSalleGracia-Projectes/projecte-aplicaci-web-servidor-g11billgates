const passport = require('passport');
const SteamStrategy = require('passport-steam').Strategy;
const jwt = require('jsonwebtoken');
require('dotenv').config();

// Configuración de la estrategia de Steam
passport.use(new SteamStrategy({
    returnURL: `${process.env.BASE_URL}/api/auth/steam/return`,
    realm: process.env.BASE_URL,
    apiKey: process.env.STEAM_API_KEY
}, async (identifier, profile, done) => {
    try {
        // Aquí puedes manejar la lógica de usuario
        // Por ejemplo, crear o actualizar el usuario en la base de datos
        const user = {
            steamId: profile.id,
            displayName: profile.displayName,
            profileUrl: profile._json.profileurl,
            avatar: profile._json.avatarfull
        };
        
        return done(null, user);
    } catch (error) {
        return done(error, null);
    }
}));

// Serialización del usuario para la sesión
passport.serializeUser((user, done) => {
    done(null, user);
});

passport.deserializeUser((user, done) => {
    done(null, user);
});

// Función para generar JWT para usuarios de Steam
function generateSteamJWT(user) {
    return jwt.sign(
        {
            steamId: user.steamId,
            displayName: user.displayName,
            profileUrl: user.profileUrl,
            avatar: user.avatar
        },
        process.env.JWT_SECRET,
        { expiresIn: '24h' }
    );
}

module.exports = {
    passport,
    generateSteamJWT
}; 