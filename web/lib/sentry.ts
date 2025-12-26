/**
 * Sentry Error Logging Utility
 * 
 * Centralized wrapper for Sentry error tracking across the web app.
 * Use these functions instead of directly calling Sentry.captureException.
 * 
 * @example
 * ```typescript
 * import { logError, logWarning, logInfo } from '@/lib/sentry';
 * 
 * try {
 *   await riskyOperation();
 * } catch (error) {
 *   logError(error, { context: 'Job Creation', jobId: '123' });
 * }
 * ```
 */

import * as Sentry from '@sentry/nextjs';

/**
 * Log an error to Sentry with optional context
 * @param error - The error object to log
 * @param context - Additional context about where/why the error occurred
 */
export const logError = (
  error: Error | unknown,
  context?: Record<string, any>
) => {
  if (process.env.NODE_ENV === 'development') {
    console.error('[Sentry Error]', error, context);
  }

  Sentry.captureException(error, {
    contexts: {
      additional: context || {},
    },
  });
};

/**
 * Log a warning message to Sentry
 * @param message - The warning message
 * @param context - Additional context
 */
export const logWarning = (
  message: string,
  context?: Record<string, any>
) => {
  if (process.env.NODE_ENV === 'development') {
    console.warn('[Sentry Warning]', message, context);
  }

  Sentry.captureMessage(message, {
    level: 'warning',
    contexts: {
      additional: context || {},
    },
  });
};

/**
 * Log an info message to Sentry (for important events)
 * @param message - The info message
 * @param context - Additional context
 */
export const logInfo = (
  message: string,
  context?: Record<string, any>
) => {
  if (process.env.NODE_ENV === 'development') {
    console.info('[Sentry Info]', message, context);
  }

  Sentry.captureMessage(message, {
    level: 'info',
    contexts: {
      additional: context || {},
    },
  });
};

/**
 * Set user context for Sentry error tracking
 * @param user - User information to associate with errors
 */
export const setUser = (user: {
  id: string;
  email?: string;
  username?: string;
  role?: string;
}) => {
  Sentry.setUser(user);
};

/**
 * Clear user context (on logout)
 */
export const clearUser = () => {
  Sentry.setUser(null);
};

/**
 * Add breadcrumb for debugging (tracks user actions leading to error)
 * @param message - Breadcrumb message
 * @param category - Category (e.g., 'auth', 'api', 'ui')
 * @param data - Additional data
 */
export const addBreadcrumb = (
  message: string,
  category: string,
  data?: Record<string, any>
) => {
  Sentry.addBreadcrumb({
    message,
    category,
    data,
    level: 'info',
  });
};

export default {
  logError,
  logWarning,
  logInfo,
  setUser,
  clearUser,
  addBreadcrumb,
};
