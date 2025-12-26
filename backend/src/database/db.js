/**
 * Database Connection Pool
 * Production-ready PostgreSQL configuration
 */

require('dotenv').config();
const { Pool } = require('pg');

const isProduction = process.env.NODE_ENV === 'production';

// Validate required environment variable
if (!process.env.DATABASE_URL) {
    console.error('❌ FATAL: DATABASE_URL environment variable is required');
    process.exit(1);
}

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    
    // SSL Configuration - DISABLED due to server not supporting SSL
    ssl: false,
    
    // Connection pool settings
    max: isProduction ? 20 : 5, // Max connections
    min: isProduction ? 5 : 1,  // Min connections
    idleTimeoutMillis: 30000,   // Close idle connections after 30s
    connectionTimeoutMillis: 5000, // Timeout after 5s
    
    // Query timeout
    statement_timeout: 30000, // 30 second query timeout
    query_timeout: 30000,
});

// Handle pool errors
pool.on('error', (err) => {
    console.error('Unexpected database pool error:', err.message);
});

// Test connection on startup
pool.query('SELECT NOW()', (err, res) => {
    if (err) {
        console.error('❌ Database connection failed:', err.message);
        if (isProduction) {
            console.error('FATAL: Cannot start without database connection');
            process.exit(1);
        }
    } else {
        console.log('✅ Connected to PostgreSQL');
    }
});

module.exports = pool;
