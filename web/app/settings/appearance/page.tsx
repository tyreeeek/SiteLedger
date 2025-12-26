'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import DashboardLayout from '@/components/dashboard-layout';
import AuthService from '@/lib/auth';
import { useTheme } from '@/components/theme-provider';
import { ArrowLeft, Save, Sun, Moon, Monitor, Palette } from 'lucide-react';

type Theme = 'light' | 'dark' | 'system';
type AccentColor = 'blue' | 'green' | 'purple' | 'orange' | 'red' | 'pink';

export default function AppearanceSettings() {
  const router = useRouter();
  const [mounted, setMounted] = useState(false);
  const [localTheme, setLocalTheme] = useState<Theme>('light');
  const [accentColor, setAccentColor] = useState<AccentColor>('blue');
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');

  // Access theme context only on client
  let theme: Theme = localTheme;
  let setTheme: (theme: Theme) => void = setLocalTheme;
  
  try {
    const themeContext = useTheme();
    if (mounted) {
      theme = themeContext.theme;
      setTheme = themeContext.setTheme;
    }
  } catch (e) {
    // Theme context not available during SSR
  }

  useEffect(() => {
    setMounted(true);
  }, []);

  useEffect(() => {
    if (!AuthService.isAuthenticated()) {
      router.push('/auth/signin');
      return;
    }

    // Load accent color from localStorage (UI only)
    const saved = localStorage.getItem('appearanceSettings');
    if (saved) {
      const settings = JSON.parse(saved);
      const color = settings.accentColor || 'blue';
      setAccentColor(color);
      
      // Apply accent color to document root
      applyAccentColor(color);
    }
  }, [router]);

  const applyAccentColor = (color: AccentColor) => {
    // Remove existing accent color classes
    document.documentElement.classList.remove('accent-blue', 'accent-green', 'accent-purple', 'accent-orange', 'accent-red', 'accent-pink');
    // Add new accent color class
    document.documentElement.classList.add(`accent-${color}`);
    // Store for persistence
    document.documentElement.setAttribute('data-accent', color);
  };

  const handleSave = async () => {
    setLoading(true);
    setMessage('');
    
    try {
      const token = localStorage.getItem('accessToken');
      
      // Save theme to backend
      const themeResponse = await fetch('https://api.siteledger.ai/api/preferences/theme', {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ theme })
      });

      if (!themeResponse.ok) {
        throw new Error('Failed to save theme preference');
      }

      // Save accent color to localStorage and apply it
      const settings = { theme, accentColor };
      localStorage.setItem('appearanceSettings', JSON.stringify(settings));
      applyAccentColor(accentColor);
      
      setMessage('Appearance settings saved successfully! Theme applied.');
    } catch (error) {
      setMessage('Failed to save settings. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const colorOptions: { color: AccentColor; name: string; gradient: string }[] = [
    { color: 'blue', name: 'Blue', gradient: 'from-blue-500 to-blue-600' },
    { color: 'green', name: 'Green', gradient: 'from-green-500 to-green-600' },
    { color: 'purple', name: 'Purple', gradient: 'from-purple-500 to-purple-600' },
    { color: 'orange', name: 'Orange', gradient: 'from-orange-500 to-orange-600' },
    { color: 'red', name: 'Red', gradient: 'from-red-500 to-red-600' },
    { color: 'pink', name: 'Pink', gradient: 'from-pink-500 to-pink-600' }
  ];

  return (
    <DashboardLayout>
      <div className="max-w-4xl mx-auto space-y-6">
        <div className="flex items-center gap-4">
          <button
            onClick={() => router.back()}
            className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition"
            aria-label="Go back"
          >
            <ArrowLeft className="w-6 h-6 text-gray-900 dark:text-white" />
          </button>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Appearance</h1>
        </div>

        {/* Success/Error Message */}
        {message && (
          <div className={`border rounded-xl p-4 ${
            message.includes('success') ? 'bg-green-50 border-green-200 text-green-800' : 'bg-red-50 border-red-200 text-red-800'
          }`}>
            {message}
          </div>
        )}

        {/* Theme Selection */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">
          <h2 className="text-xl font-bold text-gray-900 mb-4">Theme</h2>
          
          <div className="grid grid-cols-3 gap-4">
            <label className={`flex flex-col items-center gap-3 p-4 border-2 rounded-xl cursor-pointer transition ${
              theme === 'light' ? 'border-blue-600 bg-blue-50' : 'border-gray-200 hover:border-gray-300'
            }`}>
              <input
                type="radio"
                name="theme"
                value="light"
                checked={theme === 'light'}
                onChange={() => setTheme('light')}
                className="hidden"
              />
              <div className="p-3 bg-yellow-100 rounded-full">
                <Sun className="w-8 h-8 text-yellow-600" />
              </div>
              <p className="font-semibold text-gray-900 dark:text-white">Light</p>
            </label>

            <label className={`flex flex-col items-center gap-3 p-4 border-2 rounded-xl cursor-pointer transition ${
              theme === 'dark' ? 'border-blue-600 bg-blue-50' : 'border-gray-200 hover:border-gray-300'
            }`}>
              <input
                type="radio"
                name="theme"
                value="dark"
                checked={theme === 'dark'}
                onChange={() => setTheme('dark')}
                className="hidden"
              />
              <div className="p-3 bg-gray-800 rounded-full">
                <Moon className="w-8 h-8 text-gray-200" />
              </div>
              <p className="font-semibold text-gray-900 dark:text-white">Dark</p>
            </label>

            <label className={`flex flex-col items-center gap-3 p-4 border-2 rounded-xl cursor-pointer transition ${
              theme === 'system' ? 'border-blue-600 bg-blue-50' : 'border-gray-200 hover:border-gray-300'
            }`}>
              <input
                type="radio"
                name="theme"
                value="system"
                checked={theme === 'system'}
                onChange={() => setTheme('system')}
                className="hidden"
              />
              <div className="p-3 bg-purple-100 rounded-full">
                <Monitor className="w-8 h-8 text-purple-600" />
              </div>
              <p className="font-semibold text-gray-900 dark:text-white">System</p>
            </label>
          </div>
        </div>

        {/* Accent Color */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">
          <div className="flex items-center gap-3 mb-4">
            <Palette className="w-6 h-6 text-gray-700" />
            <h2 className="text-xl font-bold text-gray-900 dark:text-white">Accent Color</h2>
          </div>
          
          <div className="grid grid-cols-3 gap-4">
            {colorOptions.map((option) => (
              <label
                key={option.color}
                className={`flex flex-col items-center gap-3 p-4 border-2 rounded-xl cursor-pointer transition ${
                  accentColor === option.color ? 'border-blue-600 bg-blue-50' : 'border-gray-200 hover:border-gray-300'
                }`}
              >
                <input
                  type="radio"
                  name="accentColor"
                  value={option.color}
                  checked={accentColor === option.color}
                  onChange={() => setAccentColor(option.color)}
                  className="hidden"
                />
                <div className={`w-16 h-16 rounded-full bg-gradient-to-br ${option.gradient} shadow-lg`} />
                <p className="font-semibold text-gray-900 dark:text-white">{option.name}</p>
              </label>
            ))}
          </div>
        </div>

        {/* Preview */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">
          <h2 className="text-xl font-bold text-gray-900 mb-4">Preview</h2>
          
          <div className={`bg-gradient-to-br ${colorOptions.find(c => c.color === accentColor)?.gradient} rounded-xl p-6 text-white`}>
            <h3 className="text-2xl font-bold mb-2">Sample Card</h3>
            <p className="mb-4">This is how your accent color will look throughout the app.</p>
            <button className="px-4 py-2 bg-white text-gray-900 rounded-lg font-medium">
              Sample Button
            </button>
          </div>
        </div>

        {/* Info */}
        <div className="bg-blue-50 border border-blue-200 rounded-xl p-4">
          <div className="flex items-start gap-3">
            <svg className="w-5 h-5 text-blue-600 mt-0.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
            </svg>
            <div className="text-sm text-blue-800">
              <p className="font-medium mb-1">Note</p>
              <p>You may need to refresh the page after saving to see appearance changes take effect.</p>
            </div>
          </div>
        </div>

        {/* Save Button */}
        <button
          onClick={handleSave}
          disabled={loading}
          className="w-full py-4 bg-blue-600 text-white rounded-xl hover:bg-blue-700 transition flex items-center justify-center gap-2 font-medium shadow-lg disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <Save className="w-5 h-5" />
          {loading ? 'Saving...' : 'Save Appearance Settings'}
        </button>
      </div>
    </DashboardLayout>
  );
}
