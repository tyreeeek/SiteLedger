'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import DashboardLayout from '@/components/dashboard-layout';
import AuthService from '@/lib/auth';
import { ArrowLeft, Save, Shield, Users, Edit2 } from 'lucide-react';

interface WorkerPermissions {
  canViewFinancials: boolean;
  canUploadReceipts: boolean;
  canApproveTimesheets: boolean;
  canSeeAIInsights: boolean;
  canViewAllJobs: boolean;
}

interface Worker {
  id: number;
  name: string;
  email: string;
  active: boolean;
  permissions: WorkerPermissions;
}

export default function RolesAndPermissions() {
  const router = useRouter();
  const [workers, setWorkers] = useState<Worker[]>([]);
  const [selectedWorker, setSelectedWorker] = useState<Worker | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [message, setMessage] = useState('');

  useEffect(() => {
    if (!AuthService.isAuthenticated()) {
      router.push('/auth/signin');
    }
    loadWorkers();
  }, []);

  const loadWorkers = async () => {
    setIsLoading(true);
    try {
      const token = localStorage.getItem('accessToken');
      const response = await fetch('https://api.siteledger.ai/api/permissions/workers', {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (response.ok) {
        const data = await response.json();
        setWorkers(data.workers || []);
      }
    } catch (error) {
      // Silently fail - UI will show empty state
    } finally {
      setIsLoading(false);
    }
  };

  const handleEditWorker = (worker: Worker) => {
    setSelectedWorker({ ...worker });
  };

  const handleSavePermissions = async () => {
    if (!selectedWorker) return;
    setIsSaving(true);
    setMessage('');
    try {
      const token = localStorage.getItem('accessToken');
      const response = await fetch(`https://api.siteledger.ai/api/permissions/worker/${selectedWorker.id}`, {
        method: 'PUT',
        headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ permissions: selectedWorker.permissions })
      });
      if (!response.ok) throw new Error('Failed to update permissions');
      setMessage('Permissions updated successfully!');
      setTimeout(() => setMessage(''), 3000);
      await loadWorkers();
      setSelectedWorker(null);
    } catch (error) {
      setMessage('Failed to save permissions. Please try again.');
    } finally {
      setIsSaving(false);
    }
  };

  const updatePermission = (key: keyof WorkerPermissions, value: boolean) => {
    if (selectedWorker) {
      setSelectedWorker({
        ...selectedWorker,
        permissions: { ...selectedWorker.permissions, [key]: value }
      });
    }
  };

  return (
    <DashboardLayout>
      <div className="max-w-4xl mx-auto space-y-6">
        <div className="flex items-center gap-4">
          <button onClick={() => router.back()} className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition" aria-label="Go back">
            <ArrowLeft className="w-6 h-6 text-gray-900 dark:text-white" />
          </button>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Roles & Permissions</h1>
        </div>

        {message && (
          <div className={`p-4 rounded-xl ${message.includes('Failed') ? 'bg-red-50 dark:bg-red-900/30 text-red-800 dark:text-red-300 border border-red-200 dark:border-red-800' : 'bg-green-50 dark:bg-green-900/30 text-green-800 dark:text-green-300 border border-green-200 dark:border-green-800'}`}>
            {message}
          </div>
        )}

        {isLoading ? (
          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-12 text-center">
            <p className="text-gray-600 dark:text-gray-400">Loading workers...</p>
          </div>
        ) : workers.length === 0 ? (
          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-12 text-center">
            <Users className="w-16 h-16 text-gray-400 mx-auto mb-4" />
            <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-2">No Workers Yet</h2>
            <p className="text-gray-600 dark:text-gray-400 mb-4">Add workers to your team to manage their permissions</p>
            <button onClick={() => router.push('/workers')} className="px-6 py-3 bg-blue-600 dark:bg-blue-700 text-white rounded-lg hover:bg-blue-700 dark:hover:bg-blue-600 transition font-medium">
              Add Worker
            </button>
          </div>
        ) : (
          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">
            <div className="flex items-center gap-3 mb-6">
              <Users className="w-6 h-6 text-gray-700 dark:text-gray-300" />
              <h2 className="text-xl font-bold text-gray-900 dark:text-white">Worker Permissions</h2>
            </div>
            <div className="space-y-3">
              {workers.map((worker) => (
                <div key={worker.id} className="flex items-center justify-between p-4 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition">
                  <div className="flex-1">
                    <p className="font-medium text-gray-900 dark:text-white">{worker.name}</p>
                    <p className="text-sm text-gray-600 dark:text-gray-400">{worker.email}</p>
                  </div>
                  <button onClick={() => handleEditWorker(worker)} className="ml-4 px-4 py-2 bg-blue-600 dark:bg-blue-700 text-white rounded-lg hover:bg-blue-700 dark:hover:bg-blue-600 transition flex items-center gap-2">
                    <Edit2 className="w-4 h-4" />
                    Edit
                  </button>
                </div>
              ))}
            </div>
          </div>
        )}

        {selectedWorker && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
            <div className="bg-white dark:bg-gray-800 rounded-xl p-6 max-w-2xl w-full max-h-[90vh] overflow-y-auto">
              <div className="flex items-center justify-between mb-6">
                <div>
                  <h2 className="text-2xl font-bold text-gray-900 dark:text-white">{selectedWorker.name}</h2>
                  <p className="text-sm text-gray-600 dark:text-gray-400">{selectedWorker.email}</p>
                </div>
                <button 
                  onClick={() => setSelectedWorker(null)} 
                  className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition"
                  aria-label="Close permissions dialog"
                  title="Close"
                >
                  <svg className="w-6 h-6 text-gray-900 dark:text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
              <div className="space-y-3 mb-6">
                {[
                  { key: 'canViewFinancials' as keyof WorkerPermissions, label: 'View Financials', desc: 'Can see project values and amounts paid' },
                  { key: 'canUploadReceipts' as keyof WorkerPermissions, label: 'Upload Receipts', desc: 'Can add and upload receipt images' },
                  { key: 'canApproveTimesheets' as keyof WorkerPermissions, label: 'Approve Timesheets', desc: 'Can approve or reject timesheet entries' },
                  { key: 'canSeeAIInsights' as keyof WorkerPermissions, label: 'See AI Insights', desc: 'Can view AI-generated insights' },
                  { key: 'canViewAllJobs' as keyof WorkerPermissions, label: 'View All Jobs', desc: 'Can see all jobs, not just assigned ones' }
                ].map((perm) => (
                  <label key={perm.key} className="flex items-center justify-between p-4 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 cursor-pointer transition">
                    <div className="flex-1">
                      <p className="font-medium text-gray-900 dark:text-white">{perm.label}</p>
                      <p className="text-sm text-gray-600 dark:text-gray-400">{perm.desc}</p>
                    </div>
                    <input type="checkbox" checked={selectedWorker.permissions[perm.key]} onChange={(e) => updatePermission(perm.key, e.target.checked)} className="w-6 h-6 text-blue-600 rounded focus:ring-2 focus:ring-blue-500" />
                  </label>
                ))}
              </div>
              <div className="flex gap-3">
                <button onClick={() => setSelectedWorker(null)} className="flex-1 py-3 border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition font-medium">
                  Cancel
                </button>
                <button onClick={handleSavePermissions} disabled={isSaving} className="flex-1 py-3 bg-blue-600 dark:bg-blue-700 text-white rounded-lg hover:bg-blue-700 dark:hover:bg-blue-600 transition flex items-center justify-center gap-2 font-medium disabled:opacity-50 disabled:cursor-not-allowed">
                  <Save className="w-5 h-5" />
                  {isSaving ? 'Saving...' : 'Save Permissions'}
                </button>
              </div>
            </div>
          </div>
        )}

        <div className="bg-blue-50 dark:bg-blue-900/30 border border-blue-200 dark:border-blue-800 rounded-xl p-4">
          <div className="flex items-start gap-3">
            <Shield className="w-5 h-5 text-blue-600 dark:text-blue-400 mt-0.5 flex-shrink-0" />
            <div className="text-sm text-blue-800 dark:text-blue-300">
              <p className="font-medium mb-1">About Permissions</p>
              <p>Control what each worker can access and do in the app. Changes take effect immediately after saving.</p>
            </div>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
}
