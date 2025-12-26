// This file configures the initialization of Sentry on the client.
// The config you add here will be used whenever a users loads a page in their browser.
// https://docs.sentry.io/platforms/javascript/guides/nextjs/

import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,

  // Adjust this value in production, or use tracesSampler for greater control
  tracesSampleRate: 1,

  // Setting this option to true will print useful information to the console while you're setting up Sentry.
  debug: false,

  // Only send errors in production
  enabled: process.env.NODE_ENV === 'production',

  // Replay configuration (Session Replay for debugging)
  replaysOnErrorSampleRate: 1.0,
  replaysSessionSampleRate: 0.1, // 10% of sessions

  // Filter out specific errors that aren't actionable
  beforeSend(event, hint) {
    // Filter out common browser extension errors
    const error = hint.originalException as Error;
    if (error && error.message) {
      if (
        error.message.includes('Extension context invalidated') ||
        error.message.includes('chrome-extension://') ||
        error.message.includes('moz-extension://')
      ) {
        return null; // Don't send to Sentry
      }
    }

    // Add user context if available
    const user = localStorage.getItem('api_user');
    if (user) {
      try {
        const userData = JSON.parse(user);
        event.user = {
          id: userData.id,
          email: userData.email,
          username: userData.name,
        };
      } catch (e) {
        // Ignore JSON parse errors
      }
    }

    return event;
  },

  // Tag errors with environment
  environment: process.env.NODE_ENV || 'development',
});
