#!/usr/bin/env node

/**
 * Script to reset a worker's password directly in the database
 * Usage: node reset-worker-password.js <worker-email> <new-password>
 */

const bcrypt = require('bcryptjs');
const pool = require('./src/database/db');

async function resetPassword(email, newPassword) {
    try {
        console.log(`Resetting password for: ${email}`);
        
        // Validate password
        if (newPassword.length < 8) {
            throw new Error('Password must be at least 8 characters');
        }
        if (!/[A-Z]/.test(newPassword)) {
            throw new Error('Password must contain at least one uppercase letter');
        }
        if (!/[a-z]/.test(newPassword)) {
            throw new Error('Password must contain at least one lowercase letter');
        }
        if (!/[0-9]/.test(newPassword)) {
            throw new Error('Password must contain at least one number');
        }
        
        // Hash password
        const passwordHash = await bcrypt.hash(newPassword, 10);
        
        // Update in database
        const result = await pool.query(
            'UPDATE users SET password_hash = $1 WHERE email = $2 RETURNING id, email, name',
            [passwordHash, email]
        );
        
        if (result.rows.length === 0) {
            throw new Error(`Worker not found: ${email}`);
        }
        
        const user = result.rows[0];
        console.log(`✅ Password reset successfully!`);
        console.log(`   User: ${user.name} (${user.email})`);
        console.log(`   ID: ${user.id}`);
        console.log(`   New password: ${newPassword}`);
        
        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error.message);
        process.exit(1);
    }
}

// Parse command line arguments
const args = process.argv.slice(2);
if (args.length !== 2) {
    console.error('Usage: node reset-worker-password.js <worker-email> <new-password>');
    console.error('Example: node reset-worker-password.js worker@example.com Testing123');
    process.exit(1);
}

const [email, newPassword] = args;
resetPassword(email, newPassword);
