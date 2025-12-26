'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import DashboardLayout from '@/components/dashboard-layout';
import AuthService from '@/lib/auth';
import { ArrowLeft, Save, Hand, UserCheck, Cpu } from 'lucide-react';

type AutomationLevel = 'manual' | 'assist' | 'auto-pilot';

export default function AIAutomation() {
  const router = useRouter();
  const [automationLevel, setAutomationLevel] = useState<AutomationLevel>('assist');
  const [autoFillReceipts, setAutoFillReceipts] = useState(true);
  const [autoAssignJobs, setAutoAssignJobs] = useState(true);
  const [autoCalculateLaborCosts, setAutoCalculateLaborCosts] = useState(true);
  const [autoGenerateSummaries, setAutoGenerateSummaries] = useState(false);
  const [autoGenerateInsights, setAutoGenerateInsights] = useState(true);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');

  useEffect(() => {
    if (!AuthService.isAuthenticated()) {
      router.push('/auth/signin');
      return;
    }

    // Load settings from backend
    const loadSettings = async () => {
      try {
        const token = localStorage.getItem('accessToken');
        const response = await fetch('https://api.siteledger.ai/api/preferences/ai-automation', {
          headers: { 'Authorization': `Bearer ${token}` }
        });
        
        if (response.ok) {
          const data = await response.json();
          setAutomationLevel(data.automationLevel || 'assist');
          setAutoFillReceipts(data.autoFillReceipts !== false);
          setAutoAssignJobs(data.autoAssignJobs !== false);
          setAutoCalculateLaborCosts(data.autoCalculateLaborCosts !== false);
          setAutoGenerateSummaries(data.autoGenerateSummaries || false);
          setAutoGenerateInsights(data.autoGenerateInsights !== false);
        }
      } catch (error) {
        // Silently fail - use defaults
      }
    };

    loadSettings();
  }, [router]);

  const handleSave = async () => {
    setLoading(true);
    setMessage('');
    
    try {
      const token = localStorage.getItem('accessToken');
      const settings = {
        automationLevel,
        autoFillReceipts,
        autoAssignJobs,
        autoCalculateLaborCosts,
        autoGenerateSummaries,
        autoGenerateInsights
      };

      const response = await fetch('https://api.siteledger.ai/api/preferences/ai-automation', {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(settings)
      });

      if (!response.ok) {
        throw new Error('Failed to save settings');
      }

      setMessage('AI Automation settings saved successfully!');
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
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">AI Automation</h1>
        </div>

        {/* AI Automation Level */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">
          <h2 className="text-xl font-bold text-gray-900 mb-4">AI Automation Level</h2>
          
          <div className="space-y-3">
            <label
              className={`flex items-center gap-4 p-4 border-2 rounded-xl cursor-pointer transition ${
                automationLevel === 'manual'
                  ? 'border-blue-600 bg-blue-50'
                  : 'border-gray-200 hover:border-gray-300'
              }`}
            >
              <input
                type="radio"
                name="automation"
                value="manual"
                checked={automationLevel === 'manual'}
                onChange={() => setAutomationLevel('manual')}
                className="w-5 h-5 text-blue-600"
              />
              <div className="p-3 bg-gray-100 rounded-lg">
                <Hand className="w-6 h-6 text-gray-700" />
              </div>
              <div className="flex-1">
                <p className="font-semibold text-gray-900 dark:text-white">Manual</p>
                <p className="text-sm text-gray-600">AI only suggests, never changes data</p>
              </div>
              {automationLevel === 'manual' && (
                <div className="w-6 h-6 bg-blue-600 rounded-full flex items-center justify-center">
                  <svg className="w-4 h-4 text-white" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                  </svg>
                </div>
              )}
            </label>

            <label
              className={`flex items-center gap-4 p-4 border-2 rounded-xl cursor-pointer transition ${
                automationLevel === 'assist'
                  ? 'border-blue-600 bg-blue-50'
                  : 'border-gray-200 hover:border-gray-300'
              }`}
            >
              <input
                type="radio"
                name="automation"
                value="assist"
                checked={automationLevel === 'assist'}
                onChange={() => setAutomationLevel('assist')}
                className="w-5 h-5 text-blue-600"
              />
              <div className="p-3 bg-blue-100 rounded-lg">
                <UserCheck className="w-6 h-6 text-blue-700" />
              </div>
              <div className="flex-1">
                <p className="font-semibold text-gray-900 dark:text-white">Assist</p>
                <p className="text-sm text-gray-600">AI auto-fills but requires approval</p>
              </div>
              {automationLevel === 'assist' && (
                <div className="w-6 h-6 bg-blue-600 rounded-full flex items-center justify-center">
                  <svg className="w-4 h-4 text-white" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                  </svg>
                </div>
              )}
            </label>

            <label
              className={`flex items-center gap-4 p-4 border-2 rounded-xl cursor-pointer transition ${
                automationLevel === 'auto-pilot'
                  ? 'border-blue-600 bg-blue-50'
                  : 'border-gray-200 hover:border-gray-300'
              }`}
            >
              <input
                type="radio"
                name="automation"
                value="auto-pilot"
                checked={automationLevel === 'auto-pilot'}
                onChange={() => setAutomationLevel('auto-pilot')}
                className="w-5 h-5 text-blue-600"
              />
              <div className="p-3 bg-purple-100 rounded-lg">
                <Cpu className="w-6 h-6 text-purple-700" />
              </div>
              <div className="flex-1">
                <p className="font-semibold text-gray-900 dark:text-white">Auto-Pilot</p>
                <p className="text-sm text-gray-600">AI applies changes automatically</p>
              </div>
              {automationLevel === 'auto-pilot' && (
                <div className="w-6 h-6 bg-blue-600 rounded-full flex items-center justify-center">
                  <svg className="w-4 h-4 text-white" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                  </svg>
                </div>
              )}
            </label>
          </div>
        </div>

        {/* AI Features */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">
          <h2 className="text-xl font-bold text-gray-900 mb-4">AI Features</h2>
          
          <div className="space-y-4">
            <label className="flex items-center justify-between p-4 border border-gray-200 rounded-lg hover:bg-gray-50 cursor-pointer transition">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-blue-100 rounded-lg">
                  <svg className="w-5 h-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                </div>
                <div>
                  <p className="font-medium text-gray-900">Auto-fill receipts from photos</p>
                  <p className="text-sm text-gray-600">Extract data from receipt images</p>
                </div>
              </div>
              <input
                type="checkbox"
                checked={autoFillReceipts}
                onChange={(e) => setAutoFillReceipts(e.target.checked)}
                className="w-6 h-6 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
              />
            </label>

            <label className="flex items-center justify-between p-4 border border-gray-200 rounded-lg hover:bg-gray-50 cursor-pointer transition">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-indigo-100 rounded-lg">
                  <svg className="w-5 h-5 text-indigo-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                  </svg>
                </div>
                <div>
                  <p className="font-medium text-gray-900">Auto-assign receipts to jobs</p>
                  <p className="text-sm text-gray-600">Link expenses to relevant projects</p>
                </div>
              </div>
              <input
                type="checkbox"
                checked={autoAssignJobs}
                onChange={(e) => setAutoAssignJobs(e.target.checked)}
                className="w-6 h-6 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
              />
            </label>

            <label className="flex items-center justify-between p-4 border border-gray-200 rounded-lg hover:bg-gray-50 cursor-pointer transition">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-purple-100 rounded-lg">
                  <svg className="w-5 h-5 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
                  </svg>
                </div>
                <div>
                  <p className="font-medium text-gray-900">Auto-calculate labor costs</p>
                  <p className="text-sm text-gray-600">Compute wages from timesheets</p>
                </div>
              </div>
              <input
                type="checkbox"
                checked={autoCalculateLaborCosts}
                onChange={(e) => setAutoCalculateLaborCosts(e.target.checked)}
                className="w-6 h-6 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
              />
            </label>

            <label className="flex items-center justify-between p-4 border border-gray-200 rounded-lg hover:bg-gray-50 cursor-pointer transition">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-cyan-100 rounded-lg">
                  <svg className="w-5 h-5 text-cyan-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                  </svg>
                </div>
                <div>
                  <p className="font-medium text-gray-900">Auto-generate job summaries</p>
                  <p className="text-sm text-gray-600">Create project status reports</p>
                </div>
              </div>
              <input
                type="checkbox"
                checked={autoGenerateSummaries}
                onChange={(e) => setAutoGenerateSummaries(e.target.checked)}
                className="w-6 h-6 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
              />
            </label>

            <label className="flex items-center justify-between p-4 border border-gray-200 rounded-lg hover:bg-gray-50 cursor-pointer transition">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-yellow-100 rounded-lg">
                  <svg className="w-5 h-5 text-yellow-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                  </svg>
                </div>
                <div>
                  <p className="font-medium text-gray-900">Auto-generate business insights</p>
                  <p className="text-sm text-gray-600">AI recommendations and trends</p>
                </div>
              </div>
              <input
                type="checkbox"
                checked={autoGenerateInsights}
                onChange={(e) => setAutoGenerateInsights(e.target.checked)}
                className="w-6 h-6 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
              />
            </label>
          </div>
        </div>

        {/* Success/Error Message */}
        {message && (
          <div className={`p-4 rounded-lg ${message.includes('success') ? 'bg-green-50 text-green-800 border border-green-200' : 'bg-red-50 text-red-800 border border-red-200'}`}>
            {message}
          </div>
        )}

        {/* Save Button */}
        <button
          onClick={handleSave}
          disabled={loading}
          className="w-full py-4 bg-blue-600 text-white rounded-xl hover:bg-blue-700 transition flex items-center justify-center gap-2 font-medium shadow-lg disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <Save className="w-5 h-5" />
          {loading ? 'Saving...' : 'Save Automation Settings'}
        </button>
      </div>
    </DashboardLayout>
  );
}
