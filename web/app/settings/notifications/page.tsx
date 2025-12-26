'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import DashboardLayout from '@/components/dashboard-layout';
import AuthService from '@/lib/auth';
import { ArrowLeft, Save, Bell, AlertTriangle, DollarSign, Clock, TrendingUp, Users } from 'lucide-react';

export default function SmartNotifications() {
  const router = useRouter();
  const [budgetAlerts, setBudgetAlerts] = useState(true);
  const [paymentReminders, setPaymentReminders] = useState(true);
  const [timesheetAnomalies, setTimesheetAnomalies] = useState(true);
  const [profitAlerts, setProfitAlerts] = useState(false);
  const [lowConfidenceAlerts, setLowConfidenceAlerts] = useState(true);
  const [workerActivityAlerts, setWorkerActivityAlerts] = useState(false);
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
        const response = await fetch('https://api.siteledger.ai/api/preferences/notifications', {
          headers: {
            'Authorization': `Bearer ${token}`
          }
        });

        if (response.ok) {
          const data = await response.json();
          setBudgetAlerts(data.budgetAlerts ?? true);
          setPaymentReminders(data.paymentReminders ?? true);
          setTimesheetAnomalies(data.timesheetAnomalies ?? true);
          setProfitAlerts(data.profitAlerts ?? false);
          setLowConfidenceAlerts(data.lowConfidenceAlerts ?? true);
          setWorkerActivityAlerts(data.workerActivityAlerts ?? false);
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
      const settings = {
        budgetAlerts,
        paymentReminders,
        timesheetAnomalies,
        profitAlerts,
        lowConfidenceAlerts,
        workerActivityAlerts
      };

      const response = await fetch('https://api.siteledger.ai/api/preferences/notifications', {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(settings)
      });

      if (!response.ok) {
        throw new Error('Failed to save notification settings');
      }

      setMessage('Notification settings saved successfully!');
      setTimeout(() => setMessage(''), 3000);
    } catch (error) {
      setMessage('Failed to save notification settings. Please try again.');
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
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Smart Notifications</h1>
        </div>

        {/* Notification Types */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">
          <div className="flex items-center gap-3 mb-4">
            <Bell className="w-6 h-6 text-blue-600 dark:text-blue-400" />
            <h2 className="text-xl font-bold text-gray-900 dark:text-white">Alert Types</h2>
          </div>
          
          <div className="space-y-4">
            <label className="flex items-center justify-between p-4 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 cursor-pointer transition">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-orange-100 dark:bg-orange-900/30 rounded-lg">
                  <AlertTriangle className="w-5 h-5 text-orange-600 dark:text-orange-400" />
                </div>
                <div>
                  <p className="font-medium text-gray-900 dark:text-white">Budget Alerts</p>
                  <p className="text-sm text-gray-600 dark:text-gray-400">Notify when job expenses exceed budget threshold</p>
                </div>
              </div>
              <input
                type="checkbox"
                checked={budgetAlerts}
                onChange={(e) => setBudgetAlerts(e.target.checked)}
                className="w-6 h-6 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
              />
            </label>

            <label className="flex items-center justify-between p-4 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 cursor-pointer transition">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-green-100 dark:bg-green-900/30 rounded-lg">
                  <DollarSign className="w-5 h-5 text-green-600 dark:text-green-400" />
                </div>
                <div>
                  <p className="font-medium text-gray-900 dark:text-white">Payment Reminders</p>
                  <p className="text-sm text-gray-600 dark:text-gray-400">Alert when client payments are overdue or pending</p>
                </div>
              </div>
              <input
                type="checkbox"
                checked={paymentReminders}
                onChange={(e) => setPaymentReminders(e.target.checked)}
                className="w-6 h-6 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
              />
            </label>

            <label className="flex items-center justify-between p-4 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 cursor-pointer transition">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg">
                  <Clock className="w-5 h-5 text-purple-600 dark:text-purple-400" />
                </div>
                <div>
                  <p className="font-medium text-gray-900 dark:text-white">Timesheet Anomalies</p>
                  <p className="text-sm text-gray-600 dark:text-gray-400">Detect unusual work hours or missing clock-outs</p>
                </div>
              </div>
              <input
                type="checkbox"
                checked={timesheetAnomalies}
                onChange={(e) => setTimesheetAnomalies(e.target.checked)}
                className="w-6 h-6 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
              />
            </label>

            <label className="flex items-center justify-between p-4 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 cursor-pointer transition">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                  <TrendingUp className="w-5 h-5 text-blue-600 dark:text-blue-400" />
                </div>
                <div>
                  <p className="font-medium text-gray-900 dark:text-white">Profit Alerts</p>
                  <p className="text-sm text-gray-600 dark:text-gray-400">Notify when job profit margins fall below target</p>
                </div>
              </div>
              <input
                type="checkbox"
                checked={profitAlerts}
                onChange={(e) => setProfitAlerts(e.target.checked)}
                className="w-6 h-6 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
              />
            </label>

            <label className="flex items-center justify-between p-4 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 cursor-pointer transition">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-yellow-100 dark:bg-yellow-900/30 rounded-lg">
                  <svg className="w-5 h-5 text-yellow-600 dark:text-yellow-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                  </svg>
                </div>
                <div>
                  <p className="font-medium text-gray-900 dark:text-white">Low Confidence Alerts</p>
                  <p className="text-sm text-gray-600 dark:text-gray-400">Flag AI categorizations with low confidence scores</p>
                </div>
              </div>
              <input
                type="checkbox"
                checked={lowConfidenceAlerts}
                onChange={(e) => setLowConfidenceAlerts(e.target.checked)}
                className="w-6 h-6 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
              />
            </label>

            <label className="flex items-center justify-between p-4 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 cursor-pointer transition">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-indigo-100 dark:bg-indigo-900/30 rounded-lg">
                  <Users className="w-5 h-5 text-indigo-600 dark:text-indigo-400" />
                </div>
                <div>
                  <p className="font-medium text-gray-900 dark:text-white">Worker Activity Alerts</p>
                  <p className="text-sm text-gray-600 dark:text-gray-400">Monitor worker check-ins, check-outs, and GPS locations</p>
                </div>
              </div>
              <input
                type="checkbox"
                checked={workerActivityAlerts}
                onChange={(e) => setWorkerActivityAlerts(e.target.checked)}
                className="w-6 h-6 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
              />
            </label>
          </div>
        </div>

        {/* Info Banner */}
        <div className="bg-blue-50 dark:bg-blue-900/30 border border-blue-200 dark:border-blue-800 rounded-xl p-4">
          <div className="flex items-start gap-3">
            <svg className="w-5 h-5 text-blue-600 dark:text-blue-400 mt-0.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
            </svg>
            <div className="text-sm text-blue-800 dark:text-blue-300">
              <p className="font-medium mb-1">Smart notifications use AI to detect patterns</p>
              <p>You'll receive alerts via email and in-app notifications when the AI detects important events or anomalies.</p>
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
          {loading ? 'Saving...' : 'Save Notification Settings'}
        </button>
      </div>
    </DashboardLayout>
  );
}
