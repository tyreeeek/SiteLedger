'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useEffect, useState, ReactNode } from 'react';
import APIService from '@/lib/api';
import AuthService from '@/lib/auth';

export default function Providers({ children }: { children: ReactNode }) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            // Cache data for 5 minutes (reduces API calls)
            staleTime: 5 * 60 * 1000, // 5 minutes
            // Keep unused data in cache for 10 minutes
            gcTime: 10 * 60 * 1000, // 10 minutes (formerly cacheTime)
            // Don't refetch on window focus (reduces unnecessary requests)
            refetchOnWindowFocus: false,
            // Retry failed requests once
            retry: 1,
          },
        },
      })
  );

  // Rehydrate auth on client boot so guards/pages see the token before routing.
  useEffect(() => {
    if (typeof window === 'undefined') return;

    const token = localStorage.getItem('accessToken');
    if (token) {
      APIService.setAccessToken(token);
    }

    const userJSON = localStorage.getItem('current_user');
    if (userJSON) {
      try {
        const user = JSON.parse(userJSON);
        AuthService.saveCurrentUser(user as any);
      } catch (err) {
        // ignore parse errors; user will be re-fetched on demand
      }
    }
  }, []);

  return (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  );
}
