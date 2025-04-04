const jwt = require('jsonwebtoken');
const { MongoClient } = require('mongodb');
require('dotenv').config();

// Función para generar un JWT consistente para todos los proveedores
const generateUserToken = (user, provider) => {
    if (!user || !user._id) {
        throw new Error('Invalid user data for token generation');
    }

    return jwt.sign(
        {
            userId: user._id,
            email: user.email,
            name: user.name,
            provider: provider,
            roles: user.roles || ['user'],
            providerId: user[`${provider}Id`]
        },
        process.env.JWT_SECRET,
        { expiresIn: '24h' }
    );
};

// Función para normalizar los datos del usuario
const normalizeUserData = (profile, provider) => {
    const normalizedUser = {
        email: null,
        name: null,
        picture: null,
        [`${provider}Id`]: null,
        roles: ['user'],
        createdAt: new Date(),
        lastLogin: new Date(),
        provider: provider
    };

    switch (provider) {
        case 'google':
            normalizedUser.email = profile.email;
            normalizedUser.name = profile.name;
            normalizedUser.picture = profile.picture;
            normalizedUser.googleId = profile.googleId;
            break;
        case 'steam':
            normalizedUser.steamId = profile.id;
            normalizedUser.name = profile.displayName;
            normalizedUser.picture = profile._json?.avatarfull;
            break;
        case 'apple':
            normalizedUser.appleId = profile.id;
            normalizedUser.email = profile.email;
            normalizedUser.name = profile.name;
            break;
        case 'amazon':
            normalizedUser.amazonId = profile.id;
            normalizedUser.email = profile.emails?.[0]?.value;
            normalizedUser.name = profile.displayName;
            break;
        default:
            throw new Error(`Unsupported provider: ${provider}`);
    }

    return normalizedUser;
};

// Función para actualizar o crear usuario en la base de datos
const upsertUser = async (userData) => {
    const client = new MongoClient(process.env.MONGODB_URI);
    
    try {
        await client.connect();
        const db = client.db(process.env.DB_NAME);
        const users = db.collection('users');
        
        // Buscar usuario por ID del proveedor
        const providerId = `${userData.provider}Id`;
        const query = { [providerId]: userData[providerId] };
        
        const update = {
            $set: {
                ...userData,
                lastLogin: new Date()
            },
            $setOnInsert: {
                createdAt: new Date()
            }
        };
        
        const options = { 
            upsert: true,
            returnDocument: 'after'
        };
        
        const result = await users.findOneAndUpdate(query, update, options);
        return result.value;
    } finally {
        await client.close();
    }
};

// Función para manejar errores de autenticación
const handleAuthError = (res, error, provider) => {
    console.error(`Error en autenticación ${provider}:`, error);
    
    const errorResponse = {
        error: 'Authentication failed',
        provider: provider,
        message: error.message || 'An unexpected error occurred'
    };
    
    // Log del error para debugging
    if (process.env.NODE_ENV !== 'production') {
        errorResponse.stack = error.stack;
    }
    
    res.status(401).json(errorResponse);
};

module.exports = {
    generateUserToken,
    normalizeUserData,
    upsertUser,
    handleAuthError
}; 