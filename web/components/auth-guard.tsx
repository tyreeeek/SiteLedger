'use client';

import React, { useEffect, useMemo, useState } from 'react';
import { usePathname, useRouter, useSearchParams } from 'next/navigation';
import APIService from '@/lib/api';
import AuthService from '@/lib/auth';

type AuthGuardProps = {
  children: React.ReactNode;
};

function safeJsonParse<T>(value: string | null): T | null {
  if (!value) return null;
  try {
    return JSON.parse(value) as T;
  } catch {
    return null;
  }
}

/**
 * Client-side AuthGuard
 * - Hydrates auth from URL query params (auth_token/auth_user) when present
 * - Falls back to localStorage
 * - Verifies the token with /auth/me
 * - Redirects to /auth/signin if invalid
 */
export default function AuthGuard({ children }: AuthGuardProps) {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();

  const [ready, setReady] = useState(false);

  const urlToken = useMemo(() => searchParams.get('auth_token'), [searchParams]);
  const urlUser = useMemo(() => searchParams.get('auth_user'), [searchParams]);

  useEffect(() => {
    let cancelled = false;

    const run = async () => {
      try {
        // 1) Hydrate from URL if present
        if (urlToken) {
          APIService.setAccessToken(urlToken);
          localStorage.setItem('accessToken', urlToken);
        }

        if (urlUser) {
          // Persist as-is to match other flows
          localStorage.setItem('current_user', urlUser);
          const parsed = safeJsonParse<any>(urlUser);
          if (parsed) {
            AuthService.saveCurrentUser(parsed);
          }
        }

        // 2) Load token from storage
        const token = localStorage.getItem('accessToken');
        if (!token) {
          throw new Error('SL_AUTH_MISSING_TOKEN');
        }

        APIService.setAccessToken(token);

        // 3) Verify session via backend
        const resp = await fetch('https://api.siteledger.ai/api/auth/me', {
          headers: { Authorization: `Bearer ${token}` },
        });

        if (!resp.ok) {
          const errText = await resp.text().catch(() => '');
          const errBody = safeJsonParse<{ error?: string }>(errText) || { error: undefined };
          throw new Error(`SL_AUTH_ME_${resp.status}:${errBody.error || 'Session verify failed'}`);
        }

        // Some backends return { user: {...} }, others return the user directly.
        const bodyText = await resp.text();
        const parsed = safeJsonParse<any>(bodyText);
        const verifiedUser = parsed?.user ?? parsed;

        if (!verifiedUser || typeof verifiedUser !== 'object') {
          throw new Error('SL_AUTH_ME_BAD_BODY');
        }

        AuthService.saveCurrentUser(verifiedUser);
        localStorage.setItem('current_user', JSON.stringify(verifiedUser));

        // 4) Clean up URL if we used URL params
        if (urlToken || urlUser) {
          const cleanUrl = pathname;
          window.history.replaceState({}, document.title, cleanUrl);
        }

        if (!cancelled) setReady(true);
      } catch (err: any) {
        // Hard reset to avoid loops
        try {
          localStorage.removeItem('accessToken');
          localStorage.removeItem('current_user');
        } catch {
          // ignore
        }

        APIService.clearToken?.();

        if (!cancelled) {
          const next = encodeURIComponent(pathname);
          const reason = encodeURIComponent(String(err?.message || 'SL_AUTH_UNKNOWN'));
          router.replace(`/auth/signin?next=${next}&authError=${reason}`);
        }
      }
    };

    run();

    return () => {
      cancelled = true;
    };
  }, [pathname, router, urlToken, urlUser]);

  if (!ready) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100">
        <div className="text-center">
          <p className="text-gray-700">Verifying session…</p>
        </div>
      </div>
    );
  }

  return <>{children}</>;
}
