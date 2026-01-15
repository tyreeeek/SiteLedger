const jwt = require('jsonwebtoken');
require('dotenv').config();

// Generate a test token for the user
const userId = '28f1c4b6-8c85-4751-baa3-ebe4a1d03013';
const email = 'tariqjkg41@gmail.com';

const token = jwt.sign(
  { 
    userId: userId,
    iat: Math.floor(Date.now() / 1000)
  },
  process.env.JWT_SECRET,
  { expiresIn: '1h', algorithm: 'HS256' }
);

console.log('Test token generated:');
console.log(token);
