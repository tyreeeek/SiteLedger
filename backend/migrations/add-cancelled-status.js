/**
 * Database Migration - Add 'cancelled' to job_status enum
 * Run this on the production server
 */

require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: { rejectUnauthorized: false }
});

async function migrate() {
  try {
    console.log('🔧 Adding "cancelled" status to job_status enum...');
    
    // PostgreSQL doesn't support IF NOT EXISTS for enum values directly
    // So we need to check first
    const checkResult = await pool.query(`
      SELECT EXISTS (
        SELECT 1 FROM pg_enum
        WHERE enumlabel = 'cancelled'
        AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'job_status')
      ) as exists
    `);
    
    if (checkResult.rows[0].exists) {
      console.log('✅ "cancelled" status already exists in job_status enum');
    } else {
      await pool.query(`ALTER TYPE job_status ADD VALUE 'cancelled'`);
      console.log('✅ Successfully added "cancelled" status to job_status enum');
    }
    
    console.log('');
    console.log('🎉 Migration complete!');
    console.log('Valid job statuses: active, completed, on_hold, cancelled');
    
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

migrate();
