'use client';

import { useEffect } from 'react';
import * as Sentry from '@sentry/nextjs';
import { AlertTriangle, RefreshCw, Home } from 'lucide-react';
import Link from 'next/link';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    // Log error to console in development
    if (process.env.NODE_ENV === 'development') {
      console.error('Error boundary caught:', error);
    }
    
    // Send to Sentry in all environments (but Sentry is disabled in non-production)
    Sentry.captureException(error, {
      contexts: {
        errorBoundary: {
          digest: error.digest,
          componentStack: (error as any).componentStack,
        },
      },
    });
  }, [error]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900 px-4">
      <div className="max-w-md w-full text-center">
        {/* Error Icon */}
        <div className="flex justify-center mb-6">
          <div className="rounded-full bg-red-100 dark:bg-red-900/20 p-6">
            <AlertTriangle className="w-16 h-16 text-red-600 dark:text-red-400" />
          </div>
        </div>

        {/* Error Message */}
        <h1 className="text-3xl font-bold text-gray-900 dark:text-gray-100 mb-3">
          Something went wrong
        </h1>
        <p className="text-gray-600 dark:text-gray-400 mb-8">
          We've encountered an unexpected error. Our team has been notified and we're working on a fix.
        </p>

        {/* Error Details (Development Only) */}
        {process.env.NODE_ENV === 'development' && (
          <div className="mb-8 p-4 bg-gray-100 dark:bg-gray-800 rounded-lg text-left">
            <p className="text-sm font-mono text-red-600 dark:text-red-400 break-all">
              {error.message}
            </p>
          </div>
        )}

        {/* Action Buttons */}
        <div className="flex flex-col sm:flex-row gap-3 justify-center">
          <button
            onClick={reset}
            className="flex items-center justify-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition font-medium"
          >
            <RefreshCw className="w-5 h-5" />
            Try Again
          </button>
          <Link
            href="/dashboard"
            className="flex items-center justify-center gap-2 px-6 py-3 bg-gray-200 dark:bg-gray-700 text-gray-900 dark:text-gray-100 rounded-lg hover:bg-gray-300 dark:hover:bg-gray-600 transition font-medium"
          >
            <Home className="w-5 h-5" />
            Go Home
          </Link>
        </div>

        {/* Support Link */}
        <p className="mt-8 text-sm text-gray-500 dark:text-gray-500">
          Need help?{' '}
          <Link href="/support" className="text-blue-600 dark:text-blue-400 hover:underline">
            Contact Support
          </Link>
        </p>
      </div>
    </div>
  );
}
