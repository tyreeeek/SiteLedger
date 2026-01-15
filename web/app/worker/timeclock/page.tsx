'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Loader2 } from 'lucide-react';

/**
 * Worker Timeclock Redirect
 * 
 * This route redirects /worker/timeclock to /timesheets/clock
 * for backwards compatibility and cleaner worker URLs.
 */
export default function WorkerTimeclockRedirect() {
  const router = useRouter();

  useEffect(() => {
    // Redirect to the actual timeclock page
    router.replace('/timesheets/clock');
  }, [router]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100">
      <div className="text-center">
        <Loader2 className="w-12 h-12 text-blue-600 animate-spin mx-auto mb-4" />
        <p className="text-gray-600 dark:text-gray-400">Loading timeclock...</p>
      </div>
    </div>
  );
}
