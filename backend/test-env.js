// Test if environment variables are loaded
require('dotenv').config();

console.log('=== Environment Variable Test ===');
console.log('OCR_SPACE_API_KEY:', process.env.OCR_SPACE_API_KEY ? `${process.env.OCR_SPACE_API_KEY}` : 'NOT SET');
console.log('DATABASE_URL:', process.env.DATABASE_URL ? 'SET' : 'NOT SET');
console.log('=================================');
