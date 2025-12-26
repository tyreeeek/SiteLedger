/**
 * Winston Logger Configuration for SiteLedger Backend
 * 
 * Provides structured logging with:
 * - Multiple log levels (error, warn, info, http, debug)
 * - Daily rotating log files
 * - Separate error log file
 * - Console output in development
 * - JSON format for production
 * - Automatic old log cleanup
 * 
 * @example
 * ```javascript
 * const logger = require('./config/logger');
 * 
 * logger.info('User logged in', { userId: '123', email: 'user@example.com' });
 * logger.error('Database connection failed', { error: err.message });
 * logger.warn('High memory usage detected', { usage: '85%' });
 * ```
 */

const winston = require('winston');
const DailyRotateFile = require('winston-daily-rotate-file');
const path = require('path');

// Define log directory
const logDir = path.join(__dirname, '../../logs');

// Define log format
const logFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.errors({ stack: true }),
  winston.format.splat(),
  winston.format.json()
);

// Console format for development (human-readable)
const consoleFormat = winston.format.combine(
  winston.format.colorize(),
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.printf(
    ({ timestamp, level, message, ...metadata }) => {
      let msg = `${timestamp} [${level}]: ${message}`;
      if (Object.keys(metadata).length > 0) {
        msg += ` ${JSON.stringify(metadata)}`;
      }
      return msg;
    }
  )
);

// Configure transports
const transports = [
  // Daily rotating file for all logs
  new DailyRotateFile({
    filename: path.join(logDir, 'application-%DATE%.log'),
    datePattern: 'YYYY-MM-DD',
    zippedArchive: true,
    maxSize: '20m',
    maxFiles: '14d', // Keep logs for 14 days
    format: logFormat,
  }),

  // Separate daily rotating file for errors
  new DailyRotateFile({
    filename: path.join(logDir, 'error-%DATE%.log'),
    datePattern: 'YYYY-MM-DD',
    zippedArchive: true,
    maxSize: '20m',
    maxFiles: '30d', // Keep error logs for 30 days
    level: 'error',
    format: logFormat,
  }),
];

// Add console transport in development
if (process.env.NODE_ENV !== 'production') {
  transports.push(
    new winston.transports.Console({
      format: consoleFormat,
    })
  );
}

// Create logger instance
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: logFormat,
  transports,
  // Don't exit on handled exceptions
  exitOnError: false,
});

// Create stream for Morgan HTTP logging
logger.stream = {
  write: (message) => {
    logger.http(message.trim());
  },
};

module.exports = logger;
