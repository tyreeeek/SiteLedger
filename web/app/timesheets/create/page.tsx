'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import DashboardLayout from '@/components/dashboard-layout';
import AuthService from '@/lib/auth';
import APIService from '@/lib/api';
import toast from '@/lib/toast';
import { ArrowLeft, Loader2, Clock } from 'lucide-react';

export default function AddTimesheet() {
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(false);
  const [jobs, setJobs] = useState<any[]>([]);
  const [workers, setWorkers] = useState<any[]>([]);
  const [formData, setFormData] = useState({
    jobID: '',
    workerID: '',
    date: new Date().toISOString().split('T')[0],
    clockIn: '',
    clockOut: '',
    hours: '',
    notes: ''
  });

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const [jobsData, workersData] = await Promise.all([
        APIService.fetchJobs(),
        APIService.fetchWorkers()
      ]);
      setJobs(jobsData);
      setWorkers(workersData);
    } catch (error) {
      // Silently fail - form will show empty dropdowns
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      const user = AuthService.getCurrentUser();
      if (!user) {
        toast.error('Please sign in');
        router.push('/auth/signin');
        return;
      }

      const timesheetData = {
        workerID: formData.workerID, // FIXED: Backend expects workerID not userID
        jobID: formData.jobID,
        clockIn: formData.clockIn ? `${formData.date}T${formData.clockIn}:00` : undefined,
        clockOut: formData.clockOut ? `${formData.date}T${formData.clockOut}:00` : undefined,
        hours: parseFloat(formData.hours) || undefined,
        notes: formData.notes || undefined
      };

      // Remove undefined fields
      Object.keys(timesheetData).forEach(key => 
        timesheetData[key as keyof typeof timesheetData] === undefined && delete timesheetData[key as keyof typeof timesheetData]
      );

      await APIService.createTimesheet(timesheetData);
      toast.success('Timesheet entry added successfully!');
      router.push('/timesheets');
    } catch (error: any) {
      toast.error(error.response?.data?.error || error.message || 'Failed to add timesheet. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  const calculateHours = () => {
    if (formData.clockIn && formData.clockOut) {
      const start = new Date(`2000-01-01T${formData.clockIn}`);
      const end = new Date(`2000-01-01T${formData.clockOut}`);
      const hours = (end.getTime() - start.getTime()) / (1000 * 60 * 60);
      if (hours > 0) {
        setFormData({ ...formData, hours: hours.toFixed(2) });
      }
    }
  };

  return (
    <DashboardLayout>
      <div className="max-w-3xl mx-auto space-y-6">
        <div className="flex items-center gap-4">
          <button
            onClick={() => router.back()}
            className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition"
            aria-label="Go back to timesheets list"
            title="Go back"
          >
            <ArrowLeft className="w-6 h-6 text-gray-900 dark:text-white" />
          </button>
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Add Timesheet Entry</h1>
            <p className="text-gray-600 dark:text-gray-400 mt-1">Log worker hours for a job</p>
          </div>
        </div>

        <form onSubmit={handleSubmit} className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm space-y-6">
          {/* Worker Selection */}
          <div>
            <label htmlFor="worker-select" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Worker <span className="text-red-500">*</span>
            </label>
            <select
              id="worker-select"
              required
              value={formData.workerID}
              onChange={(e) => setFormData({ ...formData, workerID: e.target.value })}
              className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-gray-900 dark:text-white bg-white dark:bg-gray-700"
              aria-label="Select worker"
            >
              <option value="">Select a worker</option>
              {workers.map((worker) => (
                <option key={worker.id} value={worker.id}>
                  {worker.name} - ${worker.hourlyRate}/hr
                </option>
              ))}
            </select>
          </div>

          {/* Job Selection */}
          <div>
            <label htmlFor="job-select" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Job <span className="text-red-500">*</span>
            </label>
            <select
              id="job-select"
              required
              value={formData.jobID}
              onChange={(e) => setFormData({ ...formData, jobID: e.target.value })}
              className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-gray-900 dark:text-white bg-white dark:bg-gray-700"
              aria-label="Select job"
            >
              <option value="">Select a job</option>
              {jobs.map((job) => (
                <option key={job.id} value={job.id}>
                  {job.jobName} - {job.clientName}
                </option>
              ))}
            </select>
          </div>

          {/* Date */}
          <div>
            <label htmlFor="timesheet-date" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Date <span className="text-red-500">*</span>
            </label>
            <input
              id="timesheet-date"
              type="date"
              required
              value={formData.date}
              onChange={(e) => setFormData({ ...formData, date: e.target.value })}
              className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-gray-900 dark:text-white bg-white dark:bg-gray-700"
              aria-label="Timesheet date"
            />
          </div>

          {/* Time */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div>
              <label htmlFor="clock-in" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Clock In
              </label>
              <input
                id="clock-in"
                type="time"
                value={formData.clockIn}
                onChange={(e) => setFormData({ ...formData, clockIn: e.target.value })}
                onBlur={calculateHours}
                className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-gray-900 dark:text-white bg-white dark:bg-gray-700"
                aria-label="Clock in time"
              />
            </div>
            <div>
              <label htmlFor="clock-out" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Clock Out
              </label>
              <input
                id="clock-out"
                type="time"
                value={formData.clockOut}
                onChange={(e) => setFormData({ ...formData, clockOut: e.target.value })}
                onBlur={calculateHours}
                className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-gray-900 dark:text-white bg-white dark:bg-gray-700"
                aria-label="Clock out time"
              />
            </div>
            <div>
              <label htmlFor="total-hours" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Total Hours <span className="text-red-500">*</span>
              </label>
              <input
                id="total-hours"
                type="number"
                step="0.01"
                required
                value={formData.hours}
                onChange={(e) => setFormData({ ...formData, hours: e.target.value })}
                placeholder="8.00"
                className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-gray-900 dark:text-white bg-white dark:bg-gray-700"
              />
            </div>
          </div>

          {/* Notes */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Notes
            </label>
            <textarea
              rows={3}
              value={formData.notes}
              onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
              placeholder="Additional notes about this timesheet entry..."
              className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-gray-900 dark:text-white bg-white dark:bg-gray-700"
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
              className="flex-1 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isLoading ? (
                <>
                  <Loader2 className="w-5 h-5 animate-spin" />
                  Adding...
                </>
              ) : (
                <>
                  <Clock className="w-5 h-5" />
                  Add Entry
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </DashboardLayout>
  );
}
