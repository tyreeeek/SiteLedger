'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import AuthService from '@/lib/auth';
import { Loader2 } from 'lucide-react';

/**
 * OwnerOnly Component
 * Protects routes from being accessed by workers
 * Redirects workers to their dashboard
 */
export default function OwnerOnly({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const user = AuthService.getCurrentUser();

  useEffect(() => {
    if (user?.role === 'worker') {
      console.warn('🚫 Access denied: Workers cannot access owner pages');
      router.replace('/worker/dashboard');
    }
  }, [user, router]);

  // Show loading while redirecting workers
  if (user?.role === 'worker') {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900">
        <div className="text-center">
          <Loader2 className="w-8 h-8 animate-spin text-blue-600 mx-auto mb-4" />
          <p className="text-gray-600 dark:text-gray-400">Redirecting...</p>
        </div>
      </div>
    );
  }

  // Render children for owners
  return <>{children}</>;
}
