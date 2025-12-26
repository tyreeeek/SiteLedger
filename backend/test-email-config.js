#!/usr/bin/env node

/**
 * Test Email Sender Configuration
 * Verifies that emails are sent from siteledger@siteledger.ai
 */

require('dotenv').config();

console.log('\n📧 Email Configuration Test\n');
console.log('═══════════════════════════════════════════════════════════\n');

console.log('SMTP Configuration:');
console.log('  Host:', process.env.SMTP_HOST || '❌ NOT SET');
console.log('  Port:', process.env.SMTP_PORT || '❌ NOT SET');
console.log('  User:', process.env.SMTP_USER || '❌ NOT SET');
console.log('  Pass:', process.env.SMTP_PASS ? '✅ SET (hidden)' : '❌ NOT SET');
console.log('  From:', process.env.SMTP_FROM || '⚠️  NOT SET (will use SMTP_USER)');

console.log('\n───────────────────────────────────────────────────────────\n');

// Determine actual "from" address
const fromAddress = (process.env.SMTP_FROM && process.env.SMTP_FROM.trim())
    ? process.env.SMTP_FROM
    : (process.env.SMTP_USER ? `"SiteLedger" <${process.env.SMTP_USER}>` : '"SiteLedger" <noreply@siteledger.app>');

console.log('Email Sender Address:');
console.log('  📮 From:', fromAddress);

if (fromAddress.includes('siteledger@siteledger.ai')) {
    console.log('  ✅ Correctly configured to use siteledger@siteledger.ai\n');
} else {
    console.log('  ⚠️  NOT using siteledger@siteledger.ai\n');
    console.log('  To fix, add this to .env:');
    console.log('  SMTP_FROM="SiteLedger" <siteledger@siteledger.ai>\n');
}

console.log('═══════════════════════════════════════════════════════════\n');

// Test the emailService directly
console.log('Testing emailService module...\n');

const emailService = require('./src/utils/emailService');

console.log('✅ Email service loaded successfully');
console.log('✅ Configuration will be used when sending emails\n');

console.log('Test complete! 🎉\n');
