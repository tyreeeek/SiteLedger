'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import DashboardLayout from '@/components/dashboard-layout';
import AuthService from '@/lib/auth';
import { ArrowLeft, Save, AlertTriangle, Database } from 'lucide-react';

type RetentionPeriod = 'forever' | '1year' | '2years' | '5years';

export default function DataRetention() {
  const router = useRouter();
  const [retentionPeriod, setRetentionPeriod] = useState<RetentionPeriod>('forever');
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');

  useEffect(() => {
    if (!AuthService.isAuthenticated()) {
      router.push('/auth/signin');
    }

    // Load settings from backend
    const loadSettings = async () => {
      try {
        const token = localStorage.getItem('accessToken');
        const response = await fetch('https://api.siteledger.ai/api/preferences/data-retention', {
          headers: {
            'Authorization': `Bearer ${token}`
          }
        });

        if (response.ok) {
          const data = await response.json();
          if (data.dataRetentionPolicy) {
            setRetentionPeriod(data.dataRetentionPolicy as RetentionPeriod);
          }
        }
      } catch (error) {
        // Silently fail - use defaults
      }
    };

    loadSettings();
  }, []);

  const handleSave = async () => {
    setLoading(true);
    setMessage('');
    
    try {
      const token = localStorage.getItem('accessToken');
      const response = await fetch('https://api.siteledger.ai/api/preferences/data-retention', {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ dataRetentionPolicy: retentionPeriod })
      });

      if (!response.ok) {
        throw new Error('Failed to save data retention settings');
      }

      setMessage('Data retention settings saved successfully!');
      setTimeout(() => setMessage(''), 3000);
    } catch (error) {
      setMessage('Failed to save settings. Please try again.');
    } finally {
      setLoading(false);
    }
  };

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
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Data Retention</h1>
        </div>

        {/* Retention Options */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">
          <div className="flex items-center gap-3 mb-4">
            <Database className="w-6 h-6 text-gray-700 dark:text-gray-300" />
            <h2 className="text-xl font-bold text-gray-900 dark:text-white">Data Retention Period</h2>
          </div>
          
          <div className="space-y-3">
            <label className={`flex items-center gap-4 p-4 border-2 rounded-xl cursor-pointer transition ${
              retentionPeriod === 'forever' ? 'border-blue-600 bg-blue-50 dark:bg-blue-900/30' : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'
            }`}>
              <input
                type="radio"
                name="retention"
                value="forever"
                checked={retentionPeriod === 'forever'}
                onChange={() => setRetentionPeriod('forever')}
                className="w-5 h-5 text-blue-600"
              />
              <div className="flex-1">
                <p className="font-semibold text-gray-900 dark:text-white">Keep data forever</p>
                <p className="text-sm text-gray-600 dark:text-gray-400">All data will be stored permanently (recommended)</p>
              </div>
            </label>

            <label className={`flex items-center gap-4 p-4 border-2 rounded-xl cursor-pointer transition ${
              retentionPeriod === '1year' ? 'border-blue-600 bg-blue-50 dark:bg-blue-900/30' : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'
            }`}>
              <input
                type="radio"
                name="retention"
                value="1year"
                checked={retentionPeriod === '1year'}
                onChange={() => setRetentionPeriod('1year')}
                className="w-5 h-5 text-blue-600"
              />
              <div className="flex-1">
                <p className="font-semibold text-gray-900 dark:text-white">Auto-delete after 1 year</p>
                <p className="text-sm text-gray-600 dark:text-gray-400">Data older than 1 year will be automatically deleted</p>
              </div>
            </label>

            <label className={`flex items-center gap-4 p-4 border-2 rounded-xl cursor-pointer transition ${
              retentionPeriod === '2years' ? 'border-blue-600 bg-blue-50 dark:bg-blue-900/30' : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'
            }`}>
              <input
                type="radio"
                name="retention"
                value="2years"
                checked={retentionPeriod === '2years'}
                onChange={() => setRetentionPeriod('2years')}
                className="w-5 h-5 text-blue-600"
              />
              <div className="flex-1">
                <p className="font-semibold text-gray-900 dark:text-white">Auto-delete after 2 years</p>
                <p className="text-sm text-gray-600 dark:text-gray-400">Data older than 2 years will be automatically deleted</p>
              </div>
            </label>

            <label className={`flex items-center gap-4 p-4 border-2 rounded-xl cursor-pointer transition ${
              retentionPeriod === '5years' ? 'border-blue-600 bg-blue-50 dark:bg-blue-900/30' : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'
            }`}>
              <input
                type="radio"
                name="retention"
                value="5years"
                checked={retentionPeriod === '5years'}
                onChange={() => setRetentionPeriod('5years')}
                className="w-5 h-5 text-blue-600"
              />
              <div className="flex-1">
                <p className="font-semibold text-gray-900 dark:text-white">Auto-delete after 5 years</p>
                <p className="text-sm text-gray-600 dark:text-gray-400">Data older than 5 years will be automatically deleted</p>
              </div>
            </label>
          </div>
        </div>

        {/* Warning */}
        {retentionPeriod !== 'forever' && (
          <div className="bg-red-50 dark:bg-red-900/30 border-2 border-red-200 dark:border-red-800 rounded-xl p-4">
            <div className="flex items-start gap-3">
              <AlertTriangle className="w-6 h-6 text-red-600 dark:text-red-400 flex-shrink-0 mt-0.5" />
              <div className="text-sm text-red-800 dark:text-red-300">
                <p className="font-semibold mb-1">Warning: Permanent Deletion</p>
                <p>When data is auto-deleted, it cannot be recovered. Make sure to export important data before the retention period expires.</p>
              </div>
            </div>
          </div>
        )}

        {/* Info */}
        <div className="bg-blue-50 dark:bg-blue-900/30 border border-blue-200 dark:border-blue-800 rounded-xl p-4">
          <div className="flex items-start gap-3">
            <svg className="w-5 h-5 text-blue-600 dark:text-blue-400 mt-0.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
            </svg>
            <div className="text-sm text-blue-800 dark:text-blue-300">
              <p className="font-medium mb-1">What data is affected?</p>
              <ul className="list-disc list-inside space-y-1">
                <li>Jobs and project details</li>
                <li>Receipts and expense records</li>
                <li>Timesheet entries</li>
                <li>Documents and photos</li>
              </ul>
            </div>
          </div>
        </div>

        {/* Success/Error Message */}
        {message && (
          <div className={`p-4 rounded-xl ${message.includes('Failed') ? 'bg-red-50 dark:bg-red-900/30 text-red-800 dark:text-red-300 border border-red-200 dark:border-red-800' : 'bg-green-50 dark:bg-green-900/30 text-green-800 dark:text-green-300 border border-green-200 dark:border-green-800'}`}>
            {message}
          </div>
        )}

        {/* Save Button */}
        <button
          onClick={handleSave}
          disabled={loading}
          className="w-full py-4 bg-blue-600 dark:bg-blue-700 text-white rounded-xl hover:bg-blue-700 dark:hover:bg-blue-600 transition flex items-center justify-center gap-2 font-medium shadow-lg disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <Save className="w-5 h-5" />
          {loading ? 'Saving...' : 'Save Retention Settings'}
        </button>
      </div>
    </DashboardLayout>
  );
}
