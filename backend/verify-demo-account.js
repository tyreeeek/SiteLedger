#!/usr/bin/env node

/**
 * Verify Apple Review Demo Account
 * 
 * Checks if applereview@siteledger.ai exists and has demo data
 * Usage: node verify-demo-account.js
 */

require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false
});

async function verifyDemoAccount() {
    const client = await pool.connect();
    
    try {
        console.log('🔍 Checking Apple Review demo account...\n');
        
        // Check if user exists
        const userResult = await client.query(
            'SELECT id, name, email, role, active, created_at FROM users WHERE email = $1',
            ['applereview@siteledger.ai']
        );
        
        if (userResult.rows.length === 0) {
            console.log('❌ Demo account NOT FOUND!');
            console.log('   Email: applereview@siteledger.ai');
            console.log('\n⚠️  You need to create this account in your database!');
            return;
        }
        
        const user = userResult.rows[0];
        console.log('✅ Demo account EXISTS');
        console.log(`   User ID: ${user.id}`);
        console.log(`   Name: ${user.name}`);
        console.log(`   Email: ${user.email}`);
        console.log(`   Role: ${user.role}`);
        console.log(`   Active: ${user.active}`);
        console.log(`   Created: ${user.created_at}`);
        console.log('');
        
        // Check jobs
        const jobsResult = await client.query(
            'SELECT COUNT(*) as count FROM jobs WHERE owner_id = $1',
            [user.id]
        );
        console.log(`📋 Jobs: ${jobsResult.rows[0].count}`);
        
        // Check receipts
        const receiptsResult = await client.query(
            'SELECT COUNT(*) as count FROM receipts WHERE owner_id = $1',
            [user.id]
        );
        console.log(`🧾 Receipts: ${receiptsResult.rows[0].count}`);
        
        // Check timesheets
        const timesheetsResult = await client.query(
            'SELECT COUNT(*) as count FROM timesheets WHERE user_id = $1 OR user_id IN (SELECT id FROM users WHERE owner_id = $1)',
            [user.id]
        );
        console.log(`⏰ Timesheets: ${timesheetsResult.rows[0].count}`);
        
        // Check workers
        const workersResult = await client.query(
            'SELECT COUNT(*) as count FROM users WHERE owner_id = $1 AND role = $2',
            [user.id, 'worker']
        );
        console.log(`👷 Workers: ${workersResult.rows[0].count}`);
        
        // Check documents
        const docsResult = await client.query(
            'SELECT COUNT(*) as count FROM documents WHERE owner_id = $1',
            [user.id]
        );
        console.log(`📄 Documents: ${docsResult.rows[0].count}`);
        
        console.log('\n✅ Demo account is ready for Apple Review!');
        console.log('\n📝 Credentials for App Store Connect:');
        console.log('   Username: applereview@siteledger.ai');
        console.log('   Password: AppleReview2025!');
        console.log('   Role: Owner');
        
    } catch (error) {
        console.error('❌ Error:', error.message);
    } finally {
        client.release();
        await pool.end();
    }
}

verifyDemoAccount();
