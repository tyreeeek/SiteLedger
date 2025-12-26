// Run Migration 007 - Add User Preferences
const pool = require('./src/database/db');
const fs = require('fs').promises;

async function runMigration() {
  try {
    console.log('Running migration 007_add_user_preferences.sql...');
    
    const sql = await fs.readFile('./src/database/migrations/007_add_user_preferences.sql', 'utf8');
    
    await pool.query(sql);
    
    console.log('✅ Migration completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    process.exit(1);
  }
}

runMigration();
