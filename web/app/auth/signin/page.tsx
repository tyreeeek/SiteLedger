'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import AuthService from '@/lib/auth';
import { Loader2, LogIn, Apple } from 'lucide-react';

// Apple Sign In types
declare global {
  interface Window {
    AppleID?: {
      auth: {
        init: (config: any) => void;
        signIn: () => Promise<any>;
      };
    };
  }
}

export default function SignIn() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [appleLoaded, setAppleLoaded] = useState(false);

  // Load Apple Sign In SDK
  useEffect(() => {
    const script = document.createElement('script');
    script.src = 'https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/en_US/appleid.auth.js';
    script.async = true;
    script.onload = () => {
      if (window.AppleID) {
        window.AppleID.auth.init({
          clientId: 'ai.siteledger.web', // Service ID from Apple Developer
          scope: 'name email',
          redirectURI: 'https://siteledger.ai',
          state: 'signin',
          usePopup: true
        });
        setAppleLoaded(true);
      }
    };
    document.head.appendChild(script);
    
    return () => {
      document.head.removeChild(script);
    };
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const user = await AuthService.signIn(email, password);
      
      // Give localStorage time to persist before navigation
      await new Promise(resolve => setTimeout(resolve, 100));
      
      // Force reload to ensure auth state is fresh
      if (user.role === 'owner') {
        window.location.href = '/dashboard';
      } else {
        window.location.href = '/worker/timeclock';
      }
    } catch (err: any) {
      setError(err.message || 'Sign in failed');
      setLoading(false);
    }
  };

  const handleAppleSignIn = async () => {
    setError('');
    setLoading(true);
    
    try {
      if (!window.AppleID) {
        throw new Error('Apple Sign In not loaded');
      }

      const response = await window.AppleID.auth.signIn();
      
      // Send to backend with correct parameter names
      const result = await fetch('https://api.siteledger.ai/api/auth/apple', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          identityToken: response.authorization.id_token,
          authorizationCode: response.authorization.code,
          appleUserID: response.user,
          fullName: response.user?.name,
          email: response.user?.email
        })
      });

      if (!result.ok) {
        const errorData = await result.json();
        throw new Error(errorData.error || 'Apple Sign In failed');
      }

      const data = await result.json();
      
      // Store auth data
      localStorage.setItem('accessToken', data.accessToken);
      localStorage.setItem('currentUser', JSON.stringify(data.user));
      
      await new Promise(resolve => setTimeout(resolve, 100));
      
      // Redirect based on role
      if (data.user.role === 'owner') {
        window.location.href = '/dashboard';
      } else {
        window.location.href = '/worker/timeclock';
      }
    } catch (err: any) {
      setError(err.message || 'Apple Sign In failed');
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 px-4">
      <div className="max-w-md w-full space-y-8 bg-white p-8 rounded-2xl shadow-xl">
        {/* Header */}
        <div className="text-center">
          <div className="flex items-center justify-center mb-4">
            <img src="/siteledger-logo-light.png" alt="SiteLedger" className="h-24 w-24 rounded-2xl" />
          </div>
          <h1 className="text-4xl font-bold text-gray-900 mb-2">SiteLedger</h1>
          <p className="text-gray-600">Sign in to your account</p>
        </div>

        {/* Error Message */}
        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg text-sm">
            {error}
          </div>
        )}

        {/* Sign In Form */}
        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-1">
              Email
            </label>
            <input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              autoComplete="email"
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition text-gray-900 bg-white"
              placeholder="you@company.com"
            />
          </div>

          <div>
            <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-1">
              Password
            </label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              autoComplete="current-password"
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition text-gray-900 bg-white"
              placeholder="••••••••"
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-gradient-to-r from-blue-600 to-indigo-600 text-white py-3 rounded-lg font-medium hover:from-blue-700 hover:to-indigo-700 focus:ring-4 focus:ring-blue-300 transition disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center"
          >
            {loading ? (
              <Loader2 className="w-5 h-5 animate-spin" />
            ) : (
              <>
                <LogIn className="w-5 h-5 mr-2" />
                Sign In
              </>
            )}
          </button>
        </form>

        {/* Divider */}
        <div className="relative">
          <div className="absolute inset-0 flex items-center">
            <div className="w-full border-t border-gray-300"></div>
          </div>
          <div className="relative flex justify-center text-sm">
            <span className="px-2 bg-white text-gray-500">Or continue with</span>
          </div>
        </div>

        {/* Apple Sign In */}
        <button
          onClick={handleAppleSignIn}
          disabled={loading}
          className="w-full bg-black text-white py-3 rounded-lg font-medium hover:bg-gray-900 focus:ring-4 focus:ring-gray-300 transition disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center"
        >
          <Apple className="w-5 h-5 mr-2" fill="currentColor" />
          Sign in with Apple
        </button>

        {/* Links */}
        <div className="text-center space-y-2">
          <p className="text-sm text-gray-600">
            Don't have an account?{' '}
            <Link href="/auth/signup" className="text-blue-600 hover:text-blue-700 font-medium">
              Sign up
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}
