'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import DashboardLayout from '@/components/dashboard-layout';
import AuthService from '@/lib/auth';
import toast from 'react-hot-toast';
import { ArrowLeft, Save, Loader2 } from 'lucide-react';

export default function AIThresholds() {
  const router = useRouter();
  const [aiConfidence, setAiConfidence] = useState(85);
  const [flagLowConfidence, setFlagLowConfidence] = useState(true);
  const [flagUnusualHours, setFlagUnusualHours] = useState(true);
  const [maxDailyHours, setMaxDailyHours] = useState(12);
  const [budgetThreshold, setBudgetThreshold] = useState(75);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (!AuthService.isAuthenticated()) {
      router.push('/auth/signin');
      return;
    }
    loadSettings();
  }, [router]);

  const loadSettings = async () => {
    setIsLoading(true);
    try {
      const token = localStorage.getItem('accessToken');
      const response = await fetch('https://api.siteledger.ai/api/preferences/ai-automation', {
        headers: { 'Authorization': `Bearer ${token}` }
      });

      if (response.ok) {
        const data = await response.json();
        if (data.aiConfidence !== undefined) setAiConfidence(data.aiConfidence);
        if (data.flagLowConfidence !== undefined) setFlagLowConfidence(data.flagLowConfidence);
        if (data.flagUnusualHours !== undefined) setFlagUnusualHours(data.flagUnusualHours);
        if (data.maxDailyHours !== undefined) setMaxDailyHours(data.maxDailyHours);
        if (data.budgetThreshold !== undefined) setBudgetThreshold(data.budgetThreshold);
      }
    } catch (error) {
      console.error('Error loading settings:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSave = async () => {
    setIsSaving(true);
    try {
      const token = localStorage.getItem('accessToken');
      const response = await fetch('https://api.siteledger.ai/api/preferences/ai-automation', {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          aiConfidence,
          flagLowConfidence,
          flagUnusualHours,
          maxDailyHours,
          budgetThreshold
        })
      });

      if (!response.ok) {
        throw new Error('Failed to save settings');
      }

      toast.success('AI Thresholds saved successfully!');
    } catch (error) {
      console.error('Error saving settings:', error);
      toast.error('Failed to save settings. Please try again.');
    } finally {
      setIsSaving(false);
    }
  };

  if (isLoading) {
    return (
      <DashboardLayout>
        <div className="max-w-4xl mx-auto flex items-center justify-center py-20">
          <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <div className="max-w-4xl mx-auto space-y-6">
        <div className="flex items-center gap-4">
          <button
            onClick={() => router.back()}
            className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition"
            aria-label="Go back to settings"
            title="Go back"
          >
            <ArrowLeft className="w-6 h-6 text-gray-900 dark:text-white" />
          </button>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">AI Thresholds</h1>
        </div>

        {/* AI Confidence Section */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">
          <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4">AI Confidence</h2>
          
          <div className="space-y-6">
            <div>
              <div className="flex items-center justify-between mb-3">
                <label htmlFor="ai-confidence" className="text-sm font-medium text-gray-700 dark:text-gray-300">
                  Minimum confidence for auto-apply
                </label>
                <span className="text-2xl font-bold text-blue-600 dark:text-blue-400">{aiConfidence}%</span>
              </div>
              
              <input
                id="ai-confidence"
                type="range"
                min="0"
                max="100"
                value={aiConfidence}
                onChange={(e) => setAiConfidence(parseInt(e.target.value))}
                className="w-full h-3 bg-gray-200 dark:bg-gray-700 rounded-lg appearance-none cursor-pointer accent-blue-600"
                aria-label="AI confidence threshold"
              />
              
              <p className="text-sm text-gray-500 dark:text-gray-400 mt-2">
                Lower = more automation, Higher = more accuracy
              </p>
            </div>

            <label className="flex items-center justify-between p-4 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 cursor-pointer transition">
              <div>
                <p className="font-medium text-gray-900 dark:text-white">Flag low-confidence items</p>
                <p className="text-sm text-gray-600 dark:text-gray-400">Mark items that need manual review</p>
              </div>
              <input
                type="checkbox"
                checked={flagLowConfidence}
                onChange={(e) => setFlagLowConfidence(e.target.checked)}
                className="w-6 h-6 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
              />
            </label>
          </div>
        </div>

        {/* Labor Monitoring Section */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">
          <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4">Labor Monitoring</h2>
          
          <div className="space-y-6">
            <label className="flex items-center justify-between p-4 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 cursor-pointer transition">
              <div>
                <p className="font-medium text-gray-900 dark:text-white">Flag unusual worker hours</p>
                <p className="text-sm text-gray-600 dark:text-gray-400">Alert when hours exceed normal limits</p>
              </div>
              <input
                type="checkbox"
                checked={flagUnusualHours}
                onChange={(e) => setFlagUnusualHours(e.target.checked)}
                className="w-6 h-6 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
              />
            </label>

            <div>
              <div className="flex items-center justify-between mb-3">
                <label htmlFor="max-daily-hours" className="text-sm font-medium text-gray-700 dark:text-gray-300">
                  Max daily hours before alert
                </label>
                <span className="text-2xl font-bold text-blue-600 dark:text-blue-400">{maxDailyHours}h</span>
              </div>
              
              <input
                id="max-daily-hours"
                type="range"
                min="4"
                max="24"
                value={maxDailyHours}
                onChange={(e) => setMaxDailyHours(parseInt(e.target.value))}
                className="w-full h-3 bg-gray-200 dark:bg-gray-700 rounded-lg appearance-none cursor-pointer accent-blue-600"
                aria-label="Maximum daily hours threshold"
              />
            </div>
          </div>
        </div>

        {/* Budget Monitoring Section */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">
          <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4">Budget Monitoring</h2>
          
          <div>
            <div className="flex items-center justify-between mb-3">
              <label htmlFor="budget-threshold" className="text-sm font-medium text-gray-700 dark:text-gray-300">
                Alert when job cost reaches
              </label>
              <span className="text-2xl font-bold text-orange-600 dark:text-orange-400">{budgetThreshold}%</span>
            </div>
            
            <input
              id="budget-threshold"
              type="range"
              min="0"
              max="100"
              value={budgetThreshold}
              onChange={(e) => setBudgetThreshold(parseInt(e.target.value))}
              className="w-full h-3 bg-gray-200 dark:bg-gray-700 rounded-lg appearance-none cursor-pointer accent-orange-600"
              aria-label="Budget threshold percentage"
            />
            
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-2">
              Percentage of contract value
            </p>
          </div>
        </div>

        {/* Save Button */}
        <button
          onClick={handleSave}
          disabled={isSaving}
          className="w-full py-4 bg-blue-600 dark:bg-blue-700 text-white rounded-xl hover:bg-blue-700 dark:hover:bg-blue-600 transition flex items-center justify-center gap-2 font-medium shadow-lg disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isSaving ? (
            <>
              <Loader2 className="w-5 h-5 animate-spin" />
              Saving...
            </>
          ) : (
            <>
              <Save className="w-5 h-5" />
              Save Thresholds
            </>
          )}
        </button>
      </div>
    </DashboardLayout>
  );
}
