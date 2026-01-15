'use client';

import { useEffect, useRef, Suspense } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import APIService from '@/lib/api';
import AuthService from '@/lib/auth';
import { Loader2 } from 'lucide-react';

// Force dynamic rendering - no caching
export const dynamic = 'force-dynamic';

function AppleCallbackContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const processed = useRef(false);

  useEffect(() => {
    if (processed.current) return;
    processed.current = true;

    const processCallback = async () => {
      const code = searchParams.get('code');
      const state = searchParams.get('state');

      console.log('[APPLE CALLBACK] Processing', { code: !!code, state });

      if (!code) {
        console.error('[APPLE CALLBACK] No code found');
        router.push('/auth/signin?error=apple_no_code');
        return;
      }

      try {
        console.log('[APPLE CALLBACK] Calling backend...');
        const result = await fetch('https://api.siteledger.ai/api/auth/apple', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ authorizationCode: code })
        });

        console.log('[APPLE CALLBACK] Backend response status:', result.status);

        if (!result.ok) {
          const errorData = await result.json().catch(() => ({ error: 'Server error' }));
          throw new Error(errorData.error || 'Apple Sign In failed');
        }

        const data = await result.json();
        console.log('[APPLE CALLBACK] Got user data:', { userId: data.user?.id, hasToken: !!data.accessToken });

        const token = data.accessToken || data.token;
        
        if (!token || !data.user) {
          throw new Error('Invalid response from server');
        }
        
        // Store auth data
        localStorage.setItem('accessToken', token);
        localStorage.setItem('current_user', JSON.stringify(data.user));
        APIService.setAccessToken(token);
        
        if (AuthService.saveCurrentUser) {
          AuthService.saveCurrentUser(data.user);
        }

        console.log('[APPLE CALLBACK] Auth stored, redirecting to dashboard');

        // Redirect to dashboard
        const redirectPath = data.user.role === 'owner' ? '/dashboard' : '/worker/dashboard';
        router.push(redirectPath);
        
      } catch (err: any) {
        console.error('[APPLE CALLBACK] Error:', err);
        router.push(`/auth/signin?error=${encodeURIComponent(err.message || 'Apple Sign In failed')}`);
      }
    };

    processCallback();
  }, [searchParams, router]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100">
      <div className="text-center">
        <Loader2 className="w-12 h-12 text-blue-600 animate-spin mx-auto mb-4" />
        <p className="text-gray-600">Completing Apple Sign In...</p>
      </div>
    </div>
  );
}

export default function AppleCallback() {
  return (
    <Suspense fallback={
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100">
        <div className="text-center">
          <Loader2 className="w-12 h-12 text-blue-600 animate-spin mx-auto mb-4" />
          <p className="text-gray-600">Loading...</p>
        </div>
      </div>
    }>
      <AppleCallbackContent />
    </Suspense>
  );
}
