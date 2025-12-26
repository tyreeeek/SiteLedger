'use client';

import { useState, useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import DashboardLayout from '@/components/dashboard-layout';
import BackButton from '@/components/back-button';
import AuthService from '@/lib/auth';
import APIService from '@/lib/api';
import { Save, Loader2 } from 'lucide-react';

export default function EditJob() {
  const router = useRouter();
  const params = useParams();
  const queryClient = useQueryClient();
  const jobId = params?.id as string;

  const [formData, setFormData] = useState({
    jobName: '',
    clientName: '',
    address: '',
    projectValue: '',
    amountPaid: '',
    startDate: '',
    endDate: '',
    status: 'active',
    notes: '',
  });

  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!AuthService.isAuthenticated()) {
      router.push('/auth/signin');
      return;
    }
    if (jobId) {
      loadJob();
    }
  }, [jobId]);

  const loadJob = async () => {
    setIsLoading(true);
    try {
      const job = await APIService.fetchJob(jobId);
      setFormData({
        jobName: job.jobName || '',
        clientName: job.clientName || '',
        address: job.address || '',
        projectValue: job.projectValue?.toString() || '',
        amountPaid: job.amountPaid?.toString() || '0',
        startDate: job.startDate ? new Date(job.startDate).toISOString().split('T')[0] : '',
        endDate: job.endDate ? new Date(job.endDate).toISOString().split('T')[0] : '',
        status: job.status || 'active',
        notes: job.notes || '',
      });
    } catch (err) {
      setError('Failed to load job details');
    } finally {
      setIsLoading(false);
    }
  };

  const updateJobMutation = useMutation({
    mutationFn: async (data: any) => {
      return await APIService.updateJob(jobId, {
        jobName: data.jobName,
        clientName: data.clientName,
        address: data.address,
        projectValue: parseFloat(data.projectValue) || 0,
        amountPaid: parseFloat(data.amountPaid) || 0,
        startDate: data.startDate,
        endDate: data.endDate || null,
        status: data.status,
        notes: data.notes,
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['jobs'] });
      queryClient.invalidateQueries({ queryKey: ['job', jobId] });
      router.push(`/jobs/${jobId}`);
    },
    onError: (err: any) => {
      setError(err.response?.data?.message || err.message || 'Failed to update job');
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    // Validation
    if (!formData.jobName.trim()) {
      setError('Job name is required');
      return;
    }
    if (!formData.clientName.trim()) {
      setError('Client name is required');
      return;
    }
    if (!formData.address.trim()) {
      setError('Address is required');
      return;
    }
    if (!formData.projectValue || parseFloat(formData.projectValue) <= 0) {
      setError('Project value must be greater than 0');
      return;
    }
    if (!formData.startDate) {
      setError('Start date is required');
      return;
    }

    updateJobMutation.mutate(formData);
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    setFormData(prev => ({
      ...prev,
      [e.target.name]: e.target.value
    }));
  };

  if (isLoading) {
    return (
      <DashboardLayout>
        <div className="min-h-screen flex items-center justify-center">
          <Loader2 className="w-8 h-8 animate-spin text-[#007AFF] dark:text-[#3b82f6]" />
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <div className="max-w-4xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex items-center gap-4">
          <BackButton href={`/jobs/${jobId}`} />
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Edit Job</h1>
            <p className="text-gray-600 dark:text-gray-400 mt-1">Update job information</p>
          </div>
        </div>

        {/* Error Message */}
        {error && (
          <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 text-red-700 dark:text-red-400 px-4 py-3 rounded-lg">
            {error}
          </div>
        )}

        {/* Form */}
        <form onSubmit={handleSubmit} className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm space-y-6">
          {/* Job Name */}
          <div>
            <label htmlFor="jobName" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Job Name *
            </label>
            <input
              type="text"
              id="jobName"
              name="jobName"
              value={formData.jobName}
              onChange={handleChange}
              required
              className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-[#007AFF] dark:focus:ring-[#3b82f6] focus:border-transparent outline-none text-gray-900 dark:text-white bg-white dark:bg-gray-700"
              placeholder="Kitchen Remodel - 123 Main St"
            />
          </div>

          {/* Client Name */}
          <div>
            <label htmlFor="clientName" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Client Name *
            </label>
            <input
              type="text"
              id="clientName"
              name="clientName"
              value={formData.clientName}
              onChange={handleChange}
              required
              className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-[#007AFF] dark:focus:ring-[#3b82f6] focus:border-transparent outline-none text-gray-900 dark:text-white bg-white dark:bg-gray-700"
              placeholder="John Smith"
            />
          </div>

          {/* Address */}
          <div>
            <label htmlFor="address" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Address *
            </label>
            <input
              type="text"
              id="address"
              name="address"
              value={formData.address}
              onChange={handleChange}
              required
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
              placeholder="123 Main Street, City, State 12345"
            />
          </div>

          {/* Financial Information */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label htmlFor="projectValue" className="block text-sm font-medium text-gray-700 mb-2">
                Project Value *
              </label>
              <div className="relative">
                <span className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-500">$</span>
                <input
                  type="number"
                  id="projectValue"
                  name="projectValue"
                  value={formData.projectValue}
                  onChange={handleChange}
                  required
                  min="0"
                  step="0.01"
                  className="w-full pl-8 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
                  placeholder="50000"
                />
              </div>
            </div>

            <div>
              <label htmlFor="amountPaid" className="block text-sm font-medium text-gray-700 mb-2">
                Amount Paid
              </label>
              <div className="relative">
                <span className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-500">$</span>
                <input
                  type="number"
                  id="amountPaid"
                  name="amountPaid"
                  value={formData.amountPaid}
                  onChange={handleChange}
                  min="0"
                  step="0.01"
                  className="w-full pl-8 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
                  placeholder="0"
                />
              </div>
            </div>
          </div>

          {/* Dates */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label htmlFor="startDate" className="block text-sm font-medium text-gray-700 mb-2">
                Start Date *
              </label>
              <input
                type="date"
                id="startDate"
                name="startDate"
                value={formData.startDate}
                onChange={handleChange}
                required
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
              />
            </div>

            <div>
              <label htmlFor="endDate" className="block text-sm font-medium text-gray-700 mb-2">
                End Date (Optional)
              </label>
              <input
                type="date"
                id="endDate"
                name="endDate"
                value={formData.endDate}
                onChange={handleChange}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
              />
            </div>
          </div>

          {/* Status */}
          <div>
            <label htmlFor="status" className="block text-sm font-medium text-gray-700 mb-2">
              Status
            </label>
            <select
              id="status"
              name="status"
              value={formData.status}
              onChange={handleChange}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
            >
              <option value="active">Active</option>
              <option value="completed">Completed</option>
              <option value="on_hold">On Hold</option>
              <option value="cancelled">Cancelled</option>
            </select>
          </div>

          {/* Notes */}
          <div>
            <label htmlFor="notes" className="block text-sm font-medium text-gray-700 mb-2">
              Notes (Optional)
            </label>
            <textarea
              id="notes"
              name="notes"
              value={formData.notes}
              onChange={handleChange}
              rows={4}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none resize-none"
              placeholder="Additional notes or special instructions..."
            />
          </div>

          {/* Submit Button */}
          <div className="flex gap-4">
            <button
              type="button"
              onClick={() => router.push(`/jobs/${jobId}`)}
              className="flex-1 px-6 py-3 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={updateJobMutation.isPending}
              className="flex-1 flex items-center justify-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {updateJobMutation.isPending ? (
                <>
                  <Loader2 className="w-5 h-5 animate-spin" />
                  Updating...
                </>
              ) : (
                <>
                  <Save className="w-5 h-5" />
                  Update Job
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </DashboardLayout>
  );
}
