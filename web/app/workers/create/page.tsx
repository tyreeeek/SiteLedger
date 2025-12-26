'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import DashboardLayout from '@/components/dashboard-layout';
import BackButton from '@/components/back-button';
import AuthService from '@/lib/auth';
import APIService from '@/lib/api';
import toast from '@/lib/toast';
import { Loader2, UserPlus } from 'lucide-react';

export default function AddWorker() {
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(false);
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    hourlyRate: ''
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      const user = AuthService.getCurrentUser();
      if (!user) {
        toast.error('Please sign in to add a worker');
        router.push('/auth/signin');
        return;
      }

      const workerData = {
        name: formData.name,
        email: formData.email,
        phone: formData.phone || undefined,
        hourlyRate: parseFloat(formData.hourlyRate) || 0,
        sendEmail: true  // Flag to trigger email with auto-generated password
      };

      const response = await APIService.createWorker(workerData);
      toast.success(`Worker added successfully! Password has been emailed to ${formData.email}`);
      router.push('/workers');
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to add worker. Please try again.';
      toast.error(errorMessage);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <DashboardLayout>
      <div className="max-w-3xl mx-auto space-y-6">
        <div className="flex items-center gap-4">
          <BackButton href="/workers" />
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Add New Worker</h1>
            <p className="text-gray-600 dark:text-gray-400 mt-1">Create a new team member account</p>
          </div>
        </div>

        <form onSubmit={handleSubmit} className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm space-y-6">
          {/* Name */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Full Name <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              required
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              placeholder="e.g., John Smith"
              className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-[#007AFF] dark:focus:ring-[#3b82f6] focus:border-transparent text-gray-900 dark:text-white bg-white dark:bg-gray-700 outline-none"
            />
          </div>

          {/* Email */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Email Address <span className="text-red-500">*</span>
            </label>
            <input
              type="email"
              required
              value={formData.email}
              onChange={(e) => setFormData({ ...formData, email: e.target.value })}
              placeholder="worker@example.com"
              className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-[#007AFF] dark:focus:ring-[#3b82f6] focus:border-transparent text-gray-900 dark:text-white bg-white dark:bg-gray-700 outline-none"
            />
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-2">
              📧 A temporary password will be auto-generated and emailed to this address
            </p>
          </div>

          {/* Phone */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Phone Number
            </label>
            <input
              type="tel"
              value={formData.phone}
              onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
              placeholder="(555) 123-4567"
              className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-[#007AFF] dark:focus:ring-[#3b82f6] focus:border-transparent text-gray-900 dark:text-white bg-white dark:bg-gray-700 outline-none"
            />
          </div>

          {/* Hourly Rate */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Hourly Rate ($) <span className="text-red-500">*</span>
            </label>
            <input
              type="number"
              step="0.01"
              required
              value={formData.hourlyRate}
              onChange={(e) => setFormData({ ...formData, hourlyRate: e.target.value })}
              placeholder="25.00"
              className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-[#007AFF] dark:focus:ring-[#3b82f6] focus:border-transparent text-gray-900 dark:text-white bg-white dark:bg-gray-700 outline-none"
            />
          </div>

          {/* Submit Button */}
          <div className="flex gap-4 pt-4">
            <button
              type="button"
              onClick={() => router.back()}
              className="flex-1 px-6 py-3 border-2 border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition"
              disabled={isLoading}
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isLoading}
              className="flex-1 px-6 py-3 bg-[#007AFF] dark:bg-[#3b82f6] text-white rounded-lg hover:bg-[#0062CC] dark:hover:bg-[#2563eb] transition flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isLoading ? (
                <>
                  <Loader2 className="w-5 h-5 animate-spin" />
                  Adding...
                </>
              ) : (
                <>
                  <UserPlus className="w-5 h-5" />
                  Add Worker
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </DashboardLayout>
  );
}
