/**
 * SiteLedger Backend API
 * Express + PostgreSQL + DigitalOcean Spaces
 * Production-Ready Configuration
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const compression = require('compression');
const path = require('path');

// Logger setup
const logger = require('./config/logger');
const requestLogger = require('./middleware/requestLogger');

// Route imports
const authRoutes = require('./routes/auth');
const jobsRoutes = require('./routes/jobs');
const receiptsRoutes = require('./routes/receipts');
const timesheetsRoutes = require('./routes/timesheets');
const documentsRoutes = require('./routes/documents');
const alertsRoutes = require('./routes/alerts');
const workersRoutes = require('./routes/workers');
const paymentsRoutes = require('./routes/payments');
const workerPaymentsRoutes = require('./routes/worker-payments');
const clientPaymentsRoutes = require('./routes/client-payments');
const aiInsightsRoutes = require('./routes/ai-insights');
const uploadRoutes = require('./routes/upload');
const settingsRoutes = require('./routes/settings');
const configRoutes = require('./routes/config');
const passwordRoutes = require('./routes/password');
const preferencesRoutes = require('./routes/preferences');
const permissionsRoutes = require('./routes/permissions');
const exportRoutes = require('./routes/export');
const supportRoutes = require('./routes/support');
const notificationsRoutes = require('./routes/notifications');

const app = express();
const PORT = process.env.PORT || 3000;
const isProduction = process.env.NODE_ENV === 'production';

// Trust proxy (required for rate limiting behind Nginx/load balancer)
if (isProduction) {
    app.set('trust proxy', 1);
    logger.info('Production mode: Trusting proxy headers');
}

// Security middleware with production hardening
app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'"],
            imgSrc: ["'self'", "data:", "https:"],
            scriptSrc: ["'self'"]
        }
    },
    hsts: {
        maxAge: 31536000, // 1 year
        includeSubDomains: true,
        preload: true
    },
    referrerPolicy: { policy: 'strict-origin-when-cross-origin' }
}));

// Compression middleware - gzip/deflate responses
app.use(compression({
    // Only compress responses larger than 1KB
    threshold: 1024,
    // Compress all text responses (JSON, HTML, CSS, JS)
    filter: (req, res) => {
        if (req.headers['x-no-compression']) {
            return false;
        }
        return compression.filter(req, res);
    },
    // Level 6 = good balance between speed and compression
    level: 6
}));

// CORS configuration - strict in production
const corsOptions = {
    origin: isProduction
        ? (process.env.CORS_ORIGIN || 'https://siteledger.ai').split(',').map(s => s.trim())
        : '*',
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    maxAge: 86400 // Cache preflight for 24 hours
};
app.use(cors(corsOptions));

// Rate limiting - general API (production-ready limits)
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 5000, // Very generous limit for app with multiple features and real-time updates
    message: { error: 'Too many requests, please try again later' },
    standardHeaders: true,
    legacyHeaders: false,
    skip: (req) => req.path === '/health' || req.path === '/api/config/check' // Don't rate limit health checks
});
app.use('/api/', limiter);

// Stricter rate limiting for auth endpoints (prevent brute force)
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 50, // Increased for legitimate password attempts
    message: { error: 'Too many login attempts, please try again later' },
    standardHeaders: true,
    legacyHeaders: false
});
app.use('/api/auth/login', authLimiter);
app.use('/api/auth/signup', authLimiter);
app.use('/api/auth/reset-password', authLimiter);

// Separate generous rate limit for export endpoints
const exportLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 hour
    max: 100, // 100 exports per hour
    message: { error: 'Too many export requests, please try again later' },
    standardHeaders: true,
    legacyHeaders: false
});
app.use('/api/auth/export-data', exportLimiter);

// Body parsing with security limits (increased for image uploads)
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// HTTP request logging middleware (Winston + Morgan)
app.use(requestLogger);

// Serve uploaded files (enabled in both dev and production)
// In production, Nginx will handle this more efficiently, but Node can serve as fallback
app.use('/uploads', express.static(path.join(__dirname, '../uploads'), {
    maxAge: isProduction ? '1y' : 0, // Cache for 1 year in production
    etag: true,
    lastModified: true
}));
console.log('📁 Serving local uploads at /uploads');

// Keep-Alive headers to maintain persistent connections
app.use((req, res, next) => {
    res.setHeader('Connection', 'keep-alive');
    res.setHeader('Keep-Alive', 'timeout=60'); // 60 seconds
    next();
});

// Request logging (minimal in production)
app.use((req, res, next) => {
    if (!isProduction) {
        console.log(`${req.method} ${req.path}`);
    }
    next();
});

// Health check (no auth required, but don't expose internals)
app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        version: '1.0.0'
    });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/jobs', jobsRoutes);
app.use('/api/receipts', receiptsRoutes);
app.use('/api/timesheets', timesheetsRoutes);
app.use('/api/documents', documentsRoutes);
app.use('/api/alerts', alertsRoutes);
app.use('/api/workers', workersRoutes);
app.use('/api/payments', paymentsRoutes);
app.use('/api/worker-payments', workerPaymentsRoutes);
app.use('/api/client-payments', clientPaymentsRoutes);
app.use('/api/ai-insights', aiInsightsRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/settings', settingsRoutes);
app.use('/api/config', configRoutes);
app.use('/api/password', passwordRoutes);
app.use('/api/preferences', preferencesRoutes);
app.use('/api/permissions', permissionsRoutes);
app.use('/api/export', exportRoutes);
app.use('/api/support', supportRoutes);
app.use('/api/notifications', notificationsRoutes);

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Not found' });
});

// Error handler - never leak stack traces in production
app.use((err, req, res, next) => {
    // Log full error server-side
    console.error('Error:', {
        message: err.message,
        stack: isProduction ? undefined : err.stack,
        path: req.path,
        method: req.method
    });

    // Send safe response to client
    const statusCode = err.status || err.statusCode || 500;
    res.status(statusCode).json({
        error: isProduction
            ? (statusCode === 500 ? 'Internal server error' : err.message)
            : err.message,
        ...(isProduction ? {} : { stack: err.stack })
    });
});

// Global error handlers to prevent crashes
process.on('uncaughtException', (error) => {
    console.error('❌ Uncaught Exception:', error);
    // Log but don't crash - PM2 will manage restarts if needed
});

process.on('unhandledRejection', (reason, promise) => {
    logger.error('❌ Unhandled Rejection', { reason, promise });
    // Log but don't crash - PM2 will manage restarts if needed
});

process.on('uncaughtException', (error) => {
    logger.error('❌ Uncaught Exception', { error: error.message, stack: error.stack });
    // Don't crash - let PM2 handle restarts if needed
});

// Create server with keep-alive and timeout settings
const http = require('http');
const server = http.createServer(app);

// Configure server timeouts for production reliability
server.keepAliveTimeout = 61000; // 61 seconds (must be > Keep-Alive header)
server.headersTimeout = 62000; // 62 seconds (must be > keepAliveTimeout)
server.requestTimeout = 120000; // 120 seconds for large uploads

server.listen(PORT, '0.0.0.0', () => {
    logger.info(`🚀 SiteLedger API running on port ${PORT}`);
    logger.info(`📊 Environment: ${isProduction ? 'PRODUCTION' : 'development'}`);
    if (!isProduction) {
        logger.info(`📊 Health check: http://localhost:${PORT}/health`);
    }
});

// Graceful shutdown handler
const gracefulShutdown = () => {
    logger.info('📴 Shutting down gracefully...');

    server.close(() => {
        logger.info('✅ HTTP server closed');
        process.exit(0);
    });

    // Force shutdown after 10 seconds
    setTimeout(() => {
        logger.error('⚠️  Forcing shutdown after timeout');
        process.exit(1);
    }, 10000);
};

process.on('SIGTERM', gracefulShutdown);
process.on('SIGINT', gracefulShutdown);

module.exports = app;
