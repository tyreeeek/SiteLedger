// This file configures the initialization of Sentry on the server.
// The config you add here will be used whenever the server handles a request.
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

  // Filter out specific errors
  beforeSend(event, hint) {
    // Add request context
    if (event.request) {
      // Don't log sensitive headers
      if (event.request.headers) {
        delete event.request.headers['authorization'];
        delete event.request.headers['cookie'];
      }
    }

    return event;
  },

  // Tag errors with environment
  environment: process.env.NODE_ENV || 'development',
});
