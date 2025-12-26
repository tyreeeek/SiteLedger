/**
 * Production Logger
 * Replaces console.log with proper logging
 */

const isProduction = process.env.NODE_ENV === 'production';

const logger = {
    info: (message, ...args) => {
        if (!isProduction) {
            console.log(`ℹ️  ${message}`, ...args);
        }
    },
    
    error: (message, error) => {
        if (isProduction) {
            // In production, log without sensitive details
            console.error(`❌ ${message}`);
        } else {
            console.error(`❌ ${message}`, error);
        }
    },
    
    warn: (message, ...args) => {
        console.warn(`⚠️  ${message}`, ...args);
    },
    
    debug: (message, ...args) => {
        if (!isProduction) {
            console.debug(`🐛 ${message}`, ...args);
        }
    },
    
    success: (message, ...args) => {
        if (!isProduction) {
            console.log(`✅ ${message}`, ...args);
        }
    }
};

module.exports = logger;
