'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import AuthService from '@/lib/auth';
import toast from '@/lib/toast';
import { Loader2, UserPlus, Upload, Building2 } from 'lucide-react';
import { BRANDING } from '@/lib/branding';

export default function SignUp() {
  const router = useRouter();
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [companyName, setCompanyName] = useState('');
  const [addressStreet, setAddressStreet] = useState('');
  const [addressCity, setAddressCity] = useState('');
  const [addressState, setAddressState] = useState('');
  const [addressZip, setAddressZip] = useState('');
  const [companyLogo, setCompanyLogo] = useState<File | null>(null);
  const [companyLogoPreview, setCompanyLogoPreview] = useState<string>('');
  const [loading, setLoading] = useState(false);

  const handleLogoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      // Validate file type
      if (!['image/jpeg', 'image/png', 'image/jpg'].includes(file.type)) {
        toast.error('Please upload a JPEG or PNG image');
        return;
      }
      // Validate file size (max 5MB)
      if (file.size > 5 * 1024 * 1024) {
        toast.error('Image must be less than 5MB');
        return;
      }
      setCompanyLogo(file);
      // Create preview
      const reader = new FileReader();
      reader.onloadend = () => {
        setCompanyLogoPreview(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    // Validate password requirements
    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$/;
    if (!passwordRegex.test(password)) {
      toast.error('Password must be 8+ characters with uppercase, lowercase, and number');
      setLoading(false);
      return;
    }

    try {
      // First, create the account
      const signupData = await AuthService.signUp(name, email, password, 'owner', {
        companyName,
        addressStreet,
        addressCity,
        addressState,
        addressZip
      });

      // If logo provided, upload it
      if (companyLogo && signupData.accessToken) {
        try {
          const formData = new FormData();
          formData.append('file', companyLogo);
          
          const response = await fetch('https://api.siteledger.ai/api/upload/company-logo', {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${signupData.accessToken}`
            },
            body: formData
          });

          if (!response.ok) {
            console.error('Logo upload failed, but account created');
          }
        } catch (logoError) {
          console.error('Logo upload error:', logoError);
          // Don't fail signup if logo upload fails
        }
      }

      toast.success('Account created successfully!');

      // Redirect to dashboard
      setTimeout(() => {
        window.location.href = '/dashboard';
      }, 500);
    } catch (err: any) {
      toast.error(err.message || 'Sign up failed');
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 px-4 py-12">
      <div className="max-w-md w-full space-y-8 bg-white p-8 rounded-2xl shadow-xl">
        {/* Header */}
        <div className="text-center">
          <div className="flex items-center justify-center mb-4">
            <img src={BRANDING.LOGO_URL} alt={BRANDING.APP_NAME} className="h-24 w-24 rounded-2xl" />
          </div>
          <h1 className="text-4xl font-bold text-gray-900 mb-2">{BRANDING.APP_NAME}</h1>
          <p className="text-gray-600">Create your account</p>
        </div>

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
              autoComplete="name"
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition text-gray-900 bg-white"
              placeholder="John Doe"
            />
          </div>

          {/* Company Information Section */}
          <div className="bg-blue-50 p-4 rounded-lg space-y-4">
            <div className="flex items-center gap-2 mb-2">
              <Building2 className="w-5 h-5 text-blue-600" />
              <h3 className="text-sm font-semibold text-gray-900">Company Information</h3>
            </div>

            <div>
              <label htmlFor="companyName" className="block text-sm font-medium text-gray-700 mb-1">
                Company Name <span className="text-red-500">*</span>
              </label>
              <input
                id="companyName"
                type="text"
                value={companyName}
                onChange={(e) => setCompanyName(e.target.value)}
                required
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition text-gray-900 bg-white"
                placeholder="Your Construction Co."
              />
            </div>

            <div>
              <label htmlFor="companyLogo" className="block text-sm font-medium text-gray-700 mb-2">
                Company Logo
              </label>
              <div className="flex items-center gap-4">
                {companyLogoPreview && (
                  <img 
                    src={companyLogoPreview} 
                    alt="Company logo preview" 
                    className="w-16 h-16 rounded-lg object-cover border-2 border-gray-300"
                  />
                )}
                <label className="flex-1 cursor-pointer">
                  <div className="flex items-center justify-center px-4 py-3 border-2 border-dashed border-gray-300 rounded-lg hover:border-blue-500 transition text-gray-600 hover:text-blue-600">
                    <Upload className="w-5 h-5 mr-2" />
                    <span className="text-sm">{companyLogo ? companyLogo.name : 'Upload Logo'}</span>
                  </div>
                  <input
                    id="companyLogo"
                    type="file"
                    accept="image/png,image/jpeg,image/jpg"
                    onChange={handleLogoChange}
                    className="hidden"
                  />
                </label>
              </div>
              <p className="mt-1 text-xs text-gray-500">PNG or JPEG, max 5MB</p>
            </div>

            <div>
              <label htmlFor="addressStreet" className="block text-sm font-medium text-gray-700 mb-1">
                Street Address
              </label>
              <input
                id="addressStreet"
                type="text"
                value={addressStreet}
                onChange={(e) => setAddressStreet(e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition text-gray-900 bg-white"
                placeholder="123 Builder Lane"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label htmlFor="addressCity" className="block text-sm font-medium text-gray-700 mb-1">
                  City
                </label>
                <input
                  id="addressCity"
                  type="text"
                  value={addressCity}
                  onChange={(e) => setAddressCity(e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition text-gray-900 bg-white"
                  placeholder="City"
                />
              </div>
              <div>
                <label htmlFor="addressState" className="block text-sm font-medium text-gray-700 mb-1">
                  State
                </label>
                <input
                  id="addressState"
                  type="text"
                  value={addressState}
                  onChange={(e) => setAddressState(e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition text-gray-900 bg-white"
                  placeholder="ST"
                />
              </div>
            </div>

            <div>
              <label htmlFor="addressZip" className="block text-sm font-medium text-gray-700 mb-1">
                Zip Code
              </label>
              <input
                id="addressZip"
                type="text"
                value={addressZip}
                onChange={(e) => setAddressZip(e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition text-gray-900 bg-white"
                placeholder="12345"
              />
            </div>
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
              minLength={8}
              autoComplete="new-password"
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition text-gray-900 bg-white"
              placeholder="••••••••"
            />
            <p className="mt-1 text-xs text-gray-500">
              Must be 8+ characters with uppercase, lowercase, and number
            </p>
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
                Create Account
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
