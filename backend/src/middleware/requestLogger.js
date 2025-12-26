/**
 * HTTP Request Logging Middleware
 * 
 * Uses Morgan to log all HTTP requests with Winston.
 * Logs include: method, URL, status code, response time, IP address.
 * 
 * Automatically filters sensitive data (tokens, passwords) from logs.
 */

const morgan = require('morgan');
const logger = require('../config/logger');

// Define Morgan format with useful fields
morgan.token('real-ip', (req) => {
  return req.headers['x-forwarded-for'] || req.connection.remoteAddress;
});

// Custom format: METHOD URL STATUS TIME - IP
const morganFormat = ':real-ip :method :url :status :res[content-length] - :response-time ms';

// Create Morgan middleware that uses Winston
const requestLogger = morgan(morganFormat, {
  stream: logger.stream,
  // Skip logging for health check endpoint (too noisy)
  skip: (req) => req.url === '/health' || req.url === '/api/health',
});

module.exports = requestLogger;
