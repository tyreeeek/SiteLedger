const path = require('path');
const fs = require('fs');

// Mock logger
const logger = {
  info: (...args) => console.log('[INFO]', ...args),
  error: (...args) => console.error('[ERROR]', ...args),
  warn: (...args) => console.warn('[WARN]', ...args)
};

// Temporarily override require to inject our mock logger
const Module = require('module');
const originalRequire = Module.prototype.require;
Module.prototype.require = function(id) {
  if (id === '../config/logger') {
    return logger;
  }
  return originalRequire.apply(this, arguments);
};

// Now load the OCR service
const OCRService = require('./src/services/ocr-service');
const ocrService = new OCRService();

// Test with a fake local URL
const testUrl = 'https://api.siteledger.ai/uploads/receipts/1/test.jpg';

console.log('\n🧪 Testing OCR Service...');
console.log('📍 Test URL:', testUrl);
console.log('📂 Backend directory:', __dirname);

// Check if uploads directory exists
const uploadsPath = path.join(__dirname, 'uploads');
console.log('📁 Uploads path:', uploadsPath);
console.log('📁 Uploads exists?', fs.existsSync(uploadsPath));

if (fs.existsSync(uploadsPath)) {
  console.log('📁 Uploads contents:', fs.readdirSync(uploadsPath));
}

// Try to process
ocrService.processReceipt(testUrl)
  .then(result => {
    console.log('\n✅ OCR Result:', result);
    process.exit(0);
  })
  .catch(error => {
    console.error('\n❌ OCR Error:', error);
    process.exit(1);
  });
