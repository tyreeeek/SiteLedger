'use client';

import { useEffect, useState } from 'react';
import AuthService from '@/lib/auth';

export default function DebugAuth() {
  const [data, setData] = useState<any>(null);

  useEffect(() => {
    if (typeof window !== 'undefined') {
  const token = localStorage.getItem('accessToken');
      const user = localStorage.getItem('current_user');
      const parsedUser = user ? JSON.parse(user) : null;
      
      setData({
        hasToken: !!token,
        tokenLength: token?.length || 0,
        hasUser: !!user,
        userString: user,
        parsedUser: parsedUser,
        isAuthenticated: AuthService.isAuthenticated(),
        currentUser: AuthService.getCurrentUser()
      });
    }
  }, []);

  return (
    <div className="min-h-screen p-8 bg-gray-100">
      <div className="max-w-4xl mx-auto bg-white p-6 rounded-lg shadow">
        <h1 className="text-2xl font-bold mb-4">Auth Debug Info</h1>
        <pre className="bg-gray-900 text-green-400 p-4 rounded overflow-auto">
          {JSON.stringify(data, null, 2)}
        </pre>
        <div className="mt-4">
          <button 
            onClick={() => window.location.href = '/auth/signin'}
            className="bg-blue-600 text-white px-4 py-2 rounded"
          >
            Back to Sign In
          </button>
          <button 
            onClick={() => window.location.href = '/dashboard'}
            className="bg-green-600 text-white px-4 py-2 rounded ml-2"
          >
            Try Dashboard
          </button>
        </div>
      </div>
    </div>
  );
}
