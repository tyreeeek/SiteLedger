# Manual Deployment Instructions

## Quick Deploy (Password Validation Fix)

Since SSH keys aren't set up, here's how to deploy manually:

### Option 1: Direct File Edit on Server (FASTEST)

SSH into the server and edit the file directly:

```bash
ssh root@68.183.25.130
```

Then run these commands:

```bash
cd /var/www/siteledger.ai

# Edit the signup page
cat > app/auth/signup/page.tsx << 'EOF'
'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import AuthService from '@/lib/auth';
import { Loader2, UserPlus } from 'lucide-react';

export default function SignUp() {
  const router = useRouter();
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState('owner');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    // Validate password requirements
    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$/;
    if (!passwordRegex.test(password)) {
      setError('Password must be 8+ characters and contain uppercase, lowercase, and a number');
      setLoading(false);
      return;
    }

    try {
      const user = await AuthService.signUp(name, email, password, role);
      
      // Route based on role
      if (user.role === 'owner') {
        router.push('/dashboard');
      } else {
        router.push('/worker/timeclock');
      }
    } catch (err: any) {
      setError(err.message || 'Sign up failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 px-4 py-12">
      <div className="max-w-md w-full space-y-8 bg-white p-8 rounded-2xl shadow-xl">
        {/* Header */}
        <div className="text-center">
          <h1 className="text-4xl font-bold text-gray-900 mb-2">SiteLedger</h1>
          <p className="text-gray-600">Create your account</p>
        </div>

        {/* Error Message */}
        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg text-sm">
            {error}
          </div>
        )}

        {/* Sign Up Form */}
        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label htmlFor="name" className="block text-sm font-medium text-gray-700 mb-1">
              Full Name
            </label>
            <input
              id="name"
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition"
              placeholder="John Doe"
            />
          </div>

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
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition"
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
              minLength={8}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition"
              placeholder="••••••••"
            />
            <p className="mt-1 text-xs text-gray-500">
              Must be 8+ characters with uppercase, lowercase, and number
            </p>
          </div>

          <div>
            <label htmlFor="role" className="block text-sm font-medium text-gray-700 mb-1">
              I am a...
            </label>
            <select
              id="role"
              value={role}
              onChange={(e) => setRole(e.target.value)}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition"
            >
              <option value="owner">Business Owner</option>
              <option value="worker">Worker</option>
            </select>
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
                <UserPlus className="w-5 h-5 mr-2" />
                Sign Up
              </>
            )}
          </button>
        </form>

        {/* Links */}
        <div className="text-center space-y-2">
          <p className="text-sm text-gray-600">
            Already have an account?{' '}
            <Link href="/auth/signin" className="text-blue-600 hover:text-blue-700 font-medium">
              Sign in
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}
EOF

# Rebuild and restart
npm run build
pm2 restart siteledger-web
pm2 logs siteledger-web --lines 10
```

### Option 2: Upload via SFTP/File Manager

If you have an SFTP client or file manager:

1. Connect to: `68.183.25.130`
2. Navigate to: `/var/www/siteledger.ai/app/auth/signup/`
3. Upload the local file: `/Users/zia/Desktop/SiteLedger/web/app/auth/signup/page.tsx`
4. SSH in and run:
   ```bash
   cd /var/www/siteledger.ai
   npm run build
   pm2 restart siteledger-web
   ```

## What Was Fixed

✅ **Password Validation**: Added client-side validation for password requirements
✅ **User Feedback**: Shows requirement hint below password field
✅ **Better Error Messages**: Catches validation errors before API call

## Test Signup

Try creating an account with:
- Password: `Test123456` (has uppercase, lowercase, number)
- Email: Your email
- Name: Your name
- Role: Business Owner

🚀 Site: https://siteledger.ai
