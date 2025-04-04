const jwt = require('jsonwebtoken');
const { MongoClient } = require('mongodb');
require('dotenv').config();

// Middleware para verificar JWT
const verifyToken = (req, res, next) => {
    const token = req.headers.authorization?.split(' ')[1];
    
    if (!token) {
        return res.status(401).json({ error: 'No token provided' });
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = decoded;
        next();
    } catch (error) {
        return res.status(401).json({ error: 'Invalid token' });
    }
};

// Middleware para verificar roles
const checkRole = (roles) => {
    return (req, res, next) => {
        if (!req.user || !req.user.roles) {
            return res.status(403).json({ error: 'No role permissions' });
        }

        const hasRole = roles.some(role => req.user.roles.includes(role));
        if (!hasRole) {
            return res.status(403).json({ error: 'Insufficient permissions' });
        }

        next();
    };
};

// Middleware para registrar intentos de inicio de sesión
const logAuthAttempt = async (req, res, next) => {
    const client = new MongoClient(process.env.MONGODB_URI);
    
    try {
        await client.connect();
        const db = client.db(process.env.DB_NAME);
        
        await db.collection('auth_logs').insertOne({
            timestamp: new Date(),
            provider: req.params.provider || 'unknown',
            ip: req.ip,
            userAgent: req.headers['user-agent'],
            success: true
        });
        
        next();
    } catch (error) {
        console.error('Error logging auth attempt:', error);
        next();
    } finally {
        await client.close();
    }
};

// Middleware para rate limiting
const rateLimiter = {
    attempts: new Map(),
    resetTime: 15 * 60 * 1000, // 15 minutos
    maxAttempts: 5,
    
    check: (req, res, next) => {
        const ip = req.ip;
        const currentTime = Date.now();
        const userAttempts = rateLimiter.attempts.get(ip) || { count: 0, timestamp: currentTime };
        
        // Resetear contador si ha pasado el tiempo
        if (currentTime - userAttempts.timestamp > rateLimiter.resetTime) {
            userAttempts.count = 0;
            userAttempts.timestamp = currentTime;
        }
        
        if (userAttempts.count >= rateLimiter.maxAttempts) {
            return res.status(429).json({
                error: 'Too many login attempts',
                tryAgainIn: Math.ceil((userAttempts.timestamp + rateLimiter.resetTime - currentTime) / 1000)
            });
        }
        
        userAttempts.count++;
        rateLimiter.attempts.set(ip, userAttempts);
        next();
    }
};

module.exports = {
    verifyToken,
    checkRole,
    logAuthAttempt,
    rateLimiter
}; 