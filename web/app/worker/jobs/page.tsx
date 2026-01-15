'use client';

import { useEffect, useState } from 'react';
import DashboardLayout from '@/components/dashboard-layout';
import APIService from '@/lib/api';
import { Briefcase, MapPin, DollarSign, Calendar, Clock, User } from 'lucide-react';

interface Job {
  id: number;
  name: string;
  clientName: string;
  address: string;
  status: string;
  projectValue: number;
  startDate: string;
  estimatedCompletionDate: string;
}

export default function WorkerJobsPage() {
  const [loading, setLoading] = useState(true);
  const [jobs, setJobs] = useState<Job[]>([]);

  useEffect(() => {
    loadJobs();
  }, []);

  const loadJobs = async () => {
    try {
      setLoading(true);
      const response = await APIService.fetchJobs();
      
      // Handle both array and nested object responses
      const jobsData = Array.isArray(response) 
        ? response 
        : (response as any).jobs || [];
      
      // Filter for active jobs only
      const activeJobs = jobsData.filter((job: Job) => job.status === 'active');
      
      setJobs(activeJobs);
    } catch (error) {
      console.error('Error loading jobs:', error);
    } finally {
      setLoading(false);
    }
  };

  const formatDate = (dateString: string) => {
    if (!dateString) return 'Not set';
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(amount);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active':
        return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200';
      case 'completed':
        return 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200';
      case 'on_hold':
        return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200';
      default:
        return 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200';
    }
  };

  return (
    <DashboardLayout>
      <div className="space-y-6">
        {/* Header */}
        <div>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">My Jobs</h1>
          <p className="text-gray-600 dark:text-gray-400 mt-2">
            View your assigned construction jobs
          </p>
        </div>

        {/* Loading State */}
        {loading && (
          <div className="flex justify-center items-center h-64">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#007AFF]"></div>
          </div>
        )}

        {/* Empty State */}
        {!loading && jobs.length === 0 && (
          <div className="text-center py-12 bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
            <Briefcase className="w-16 h-16 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
              No Active Jobs
            </h3>
            <p className="text-gray-600 dark:text-gray-400">
              You don't have any active job assignments yet.
            </p>
          </div>
        )}

        {/* Jobs List */}
        {!loading && jobs.length > 0 && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {jobs.map((job) => (
              <div
                key={job.id}
                className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6 hover:shadow-lg transition-shadow"
              >
                {/* Job Header */}
                <div className="flex items-start justify-between mb-4">
                  <div className="flex items-start gap-3">
                    <div className="p-2 bg-[#007AFF] bg-opacity-10 rounded-lg">
                      <Briefcase className="w-6 h-6 text-[#007AFF]" />
                    </div>
                    <div>
                      <h3 className="font-semibold text-gray-900 dark:text-white text-lg">
                        {job.name}
                      </h3>
                      <p className="text-sm text-gray-600 dark:text-gray-400 flex items-center gap-1 mt-1">
                        <User className="w-4 h-4" />
                        {job.clientName}
                      </p>
                    </div>
                  </div>
                </div>

                {/* Status Badge */}
                <div className="mb-4">
                  <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-medium ${getStatusColor(job.status)}`}>
                    {job.status === 'active' ? 'Active' : job.status === 'on_hold' ? 'On Hold' : 'Completed'}
                  </span>
                </div>

                {/* Job Details */}
                <div className="space-y-3">
                  {/* Address */}
                  <div className="flex items-start gap-2 text-sm">
                    <MapPin className="w-4 h-4 text-gray-400 mt-0.5 flex-shrink-0" />
                    <span className="text-gray-600 dark:text-gray-400">{job.address}</span>
                  </div>

                  {/* Project Value */}
                  {job.projectValue > 0 && (
                    <div className="flex items-center gap-2 text-sm">
                      <DollarSign className="w-4 h-4 text-gray-400 flex-shrink-0" />
                      <span className="text-gray-600 dark:text-gray-400">
                        {formatCurrency(job.projectValue)}
                      </span>
                    </div>
                  )}

                  {/* Start Date */}
                  {job.startDate && (
                    <div className="flex items-center gap-2 text-sm">
                      <Calendar className="w-4 h-4 text-gray-400 flex-shrink-0" />
                      <span className="text-gray-600 dark:text-gray-400">
                        Started: {formatDate(job.startDate)}
                      </span>
                    </div>
                  )}

                  {/* Estimated Completion */}
                  {job.estimatedCompletionDate && (
                    <div className="flex items-center gap-2 text-sm">
                      <Clock className="w-4 h-4 text-gray-400 flex-shrink-0" />
                      <span className="text-gray-600 dark:text-gray-400">
                        Due: {formatDate(job.estimatedCompletionDate)}
                      </span>
                    </div>
                  )}
                </div>

                {/* Action Button */}
                <div className="mt-6 pt-4 border-t border-gray-200 dark:border-gray-700">
                  <a
                    href={`/timesheets/clock?jobId=${job.id}`}
                    className="flex items-center justify-center gap-2 w-full px-4 py-2 bg-[#007AFF] text-white rounded-lg hover:bg-[#0056b3] transition-colors"
                  >
                    <Clock className="w-4 h-4" />
                    Clock In
                  </a>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
