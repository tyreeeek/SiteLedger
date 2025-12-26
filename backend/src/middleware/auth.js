/**
 * JWT Authentication Middleware
 * Production-ready security configuration
 */

const jwt = require('jsonwebtoken');
const pool = require('../database/db');

const isProduction = process.env.NODE_ENV === 'production';

// Validate JWT secret in production
const JWT_SECRET = process.env.JWT_SECRET;
if (isProduction && (!JWT_SECRET || JWT_SECRET.length < 32)) {
    console.error('❌ FATAL: JWT_SECRET must be at least 32 characters in production');
    process.exit(1);
}
const SECRET = JWT_SECRET || 'dev-secret-change-in-production';

/**
 * Verify JWT token and attach user to request
 */
const authenticate = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ error: 'No token provided' });
        }
        
        const token = authHeader.split(' ')[1];
        
        // Verify token with additional security options
        const decoded = jwt.verify(token, SECRET, {
            algorithms: ['HS256'], // Only allow HS256
            maxAge: process.env.JWT_EXPIRES_IN || '7d'
        });
        
        // Fetch user from database
        const result = await pool.query(
            'SELECT id, email, name, role, active, hourly_rate, phone, photo_url, owner_id, worker_permissions FROM users WHERE id = $1',
            [decoded.userId]
        );
        
        if (result.rows.length === 0) {
            return res.status(401).json({ error: 'User not found' });
        }
        
        if (!result.rows[0].active) {
            return res.status(401).json({ error: 'Account is disabled' });
        }
        
        req.user = result.rows[0];
        next();
    } catch (error) {
        if (error.name === 'TokenExpiredError') {
            return res.status(401).json({ error: 'Token expired' });
        }
        if (error.name === 'JsonWebTokenError') {
            return res.status(401).json({ error: 'Invalid token' });
        }
        // Don't log full error in production (could contain sensitive info)
        if (!isProduction) {
            console.error('Auth error:', error);
        }
        res.status(500).json({ error: 'Authentication failed' });
    }
};

/**
 * Check if user is an owner
 */
const requireOwner = (req, res, next) => {
    if (req.user.role !== 'owner') {
        return res.status(403).json({ error: 'Owner access required' });
    }
    next();
};

/**
 * Check if user is a worker
 */
const requireWorker = (req, res, next) => {
    if (req.user.role !== 'worker') {
        return res.status(403).json({ error: 'Worker access required' });
    }
    next();
};

/**
 * Generate JWT tokens with security best practices
 */
const generateTokens = (userId) => {
    const accessToken = jwt.sign(
        { 
            userId,
            iat: Math.floor(Date.now() / 1000) // Issued at timestamp
        },
        SECRET,
        { 
            expiresIn: process.env.JWT_EXPIRES_IN || '7d',
            algorithm: 'HS256'
        }
    );
    
    return { accessToken };
};

/**
 * Get bcrypt rounds based on environment
 */
const getBcryptRounds = () => {
    return parseInt(process.env.BCRYPT_ROUNDS) || (isProduction ? 12 : 10);
};

module.exports = {
    authenticate,
    requireOwner,
    requireWorker,
    generateTokens,
    getBcryptRounds,
    JWT_SECRET: SECRET
};
