'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import AuthService from '@/lib/auth';
import { Loader2 } from 'lucide-react';

export default function Home() {
  const router = useRouter();

  useEffect(() => {
    const checkAuth = async () => {
      if (AuthService.isAuthenticated()) {
        const user = AuthService.getCurrentUser();
        if (user?.role === 'owner') {
          router.push('/dashboard');
        } else {
          router.push('/worker/timeclock');
        }
      } else {
        router.push('/auth/signin');
      }
    };

    checkAuth();
  }, [router]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100">
      <div className="text-center">
        <Loader2 className="w-12 h-12 text-blue-600 animate-spin mx-auto mb-4" />
        <p className="text-gray-600">Loading SiteLedger...</p>
      </div>
    </div>
  );
}
