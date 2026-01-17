const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const pool = new Pool({
    user: process.env.DB_USER || 'siteledger_user',
    host: process.env.DB_HOST || 'localhost',
    database: process.env.DB_NAME || 'siteledger',
    password: process.env.DB_PASSWORD || 'password',
    port: process.env.DB_PORT || 5432,
});

async function runMigration() {
    const client = await pool.connect();
    try {
        console.log('🔌 Connected to database...');

        // Fix ownership if needed (idempotent)
        try {
            await client.query('ALTER TABLE jobs OWNER TO siteledger_user;');
        } catch (e) {
            console.log('Diminished permissions or table okay, skipping ownership change.');
        }

        const migrationFile = process.argv[2] || '016_add_company_info_to_users.sql';
        const filePath = path.join(__dirname, 'migrations', migrationFile);

        console.log(`📄 Reading migration: ${migrationFile}`);
        const sql = fs.readFileSync(filePath, 'utf8');

        console.log('🚀 Applying migration...');
        await client.query(sql);

        console.log('✅ Migration applied successfully!');
    } catch (err) {
        console.error('❌ Migration failed:', err);
    } finally {
        client.release();
        pool.end();
    }
}

runMigration();
