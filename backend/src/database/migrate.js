/**
 * Database Migration Script
 * Creates all tables in PostgreSQL
 */

require('dotenv').config();
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

async function migrate() {
    console.log('🚀 Running database migrations...\n');
    
    try {
        // Read schema file
        const schemaPath = path.join(__dirname, 'schema.sql');
        const schema = fs.readFileSync(schemaPath, 'utf8');
        
        // Execute schema
        await pool.query(schema);
        
        console.log('✅ Database schema created successfully!\n');
        console.log('Tables created:');
        console.log('  - users');
        console.log('  - jobs');
        console.log('  - worker_job_assignments');
        console.log('  - receipts');
        console.log('  - timesheets');
        console.log('  - documents');
        console.log('  - alerts');
        console.log('  - worker_payments');
        console.log('  - refresh_tokens');
        console.log('\nHelper functions created:');
        console.log('  - calculate_effective_hours()');
        console.log('  - calculate_job_labor_cost()');
        console.log('  - calculate_job_profit()');
        
    } catch (error) {
        if (error.message.includes('already exists')) {
            console.log('⚠️  Some objects already exist. This is normal for re-runs.');
            console.log('   To reset: DROP all tables and run again.');
        } else {
            console.error('❌ Migration failed:', error.message);
        }
    } finally {
        await pool.end();
    }
}

migrate();
