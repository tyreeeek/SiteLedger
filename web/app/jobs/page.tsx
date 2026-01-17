'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import APIService from '@/lib/api';
import AuthService from '@/lib/auth';
import DashboardLayout from '@/components/dashboard-layout';
import { Briefcase, Loader2, Search, Plus, DollarSign, MapPin, Calendar, AlertCircle } from 'lucide-react';

export default function Jobs() {
  const router = useRouter();
  const [isAuthChecked, setIsAuthChecked] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const user = AuthService.getCurrentUser();

  useEffect(() => {
    if (!AuthService.isAuthenticated()) {
      router.push('/auth/signin');
    } else if (user?.role === 'worker') {
      router.replace('/worker/jobs');
    } else {
      setIsAuthChecked(true);
    }
  }, [router, user]);

  // Early return for workers
  if (user?.role === 'worker') {
    return null;
  }

  const { data: jobs = [], isLoading } = useQuery({
    queryKey: ['jobs'],
    queryFn: () => APIService.fetchJobs(),
    enabled: isAuthChecked,
  });

  const { data: timesheets = [] } = useQuery({
    queryKey: ['timesheets'],
    queryFn: () => APIService.fetchTimesheets(),
    enabled: isAuthChecked,
  });

  const { data: receipts = [] } = useQuery({
    queryKey: ['receipts'],
    queryFn: () => APIService.fetchReceipts(),
    enabled: isAuthChecked,
  });

  // Only owners can fetch workers list
  const { data: workers = [] } = useQuery({
    queryKey: ['workers'],
    queryFn: () => APIService.fetchWorkers(),
    enabled: isAuthChecked && user?.role === 'owner',
  });

  if (!isAuthChecked) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
      </div>
    );
  }

  // Calculate job metrics
  const getJobMetrics = (job: any) => {
    const jobTimesheets = timesheets.filter((ts: any) => ts.jobID === job.id);
    const jobReceipts = receipts.filter((r: any) => r.jobID === job.id);

    const laborCost = jobTimesheets.reduce((sum: number, ts: any) => {
      const worker = workers.find((w: any) => w.id === ts.workerID);
      const hours = ts.hours || 0;
      const rate = worker?.hourlyRate || 0;
      return sum + (hours * rate);
    }, 0);

    const receiptExpenses = jobReceipts.reduce((sum: number, r: any) => sum + (r.amount || 0), 0);
    const profit = job.projectValue - laborCost - receiptExpenses;
    const remainingBalance = job.projectValue - (job.amountPaid || 0);

    return { laborCost, receiptExpenses, profit, remainingBalance };
  };

  const filteredJobs = jobs.filter((job: any) => {
    const matchesSearch = job.jobName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      job.clientName?.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesStatus = statusFilter === 'all' || job.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(value);
  };

  const getStatusBadge = (status: string) => {
    const styles: Record<string, string> = {
      active: 'bg-green-100 text-green-700',
      completed: 'bg-blue-100 text-blue-700',
      on_hold: 'bg-yellow-100 text-yellow-700',
      cancelled: 'bg-red-100 text-red-700',
    };
    return (
      <span className={`px-3 py-1 rounded-full text-xs font-medium ${styles[status] || 'bg-gray-100 text-gray-700'}`}>
        {status.replace('_', ' ').toUpperCase()}
      </span>
    );
  };

  if (isLoading) {
    return (
      <DashboardLayout>
        <div className="flex items-center justify-center min-h-[60vh]">
          <div className="text-center">
            <Loader2 className="w-12 h-12 text-blue-600 animate-spin mx-auto mb-4" />
            <p className="text-gray-600 dark:text-gray-400">Loading jobs...</p>
          </div>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
          <div>
            <h1 className="text-3xl lg:text-4xl font-bold text-gray-900">Jobs</h1>
            <p className="text-gray-600 mt-2">Manage your construction projects</p>
          </div>
          <button
            onClick={() => router.push('/jobs/create')}
            className="flex items-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition shadow-lg"
          >
            <Plus className="w-5 h-5" />
            New Job
          </button>
        </div>

        {/* Filters */}
        <div className="bg-white rounded-xl border border-gray-200 p-4 shadow-sm">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
              <input
                type="text"
                placeholder="Search jobs or clients..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
                aria-label="Search jobs or clients"
              />
            </div>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
              aria-label="Filter by job status"
            >
              <option value="all">All Statuses</option>
              <option value="active">Active</option>
              <option value="completed">Completed</option>
              <option value="on_hold">On Hold</option>
              <option value="cancelled">Cancelled</option>
            </select>
          </div>
        </div>

        {/* Stats Overview - Only for owners */}
        {user?.role === 'owner' && (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <div className="bg-white rounded-lg border border-gray-200 p-4 shadow-sm">
              <p className="text-sm text-gray-600">Total Jobs</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">{jobs.length}</p>
            </div>
            <div className="bg-white rounded-lg border border-gray-200 p-4 shadow-sm">
              <p className="text-sm text-gray-600">Active</p>
              <p className="text-2xl font-bold text-green-600 mt-1">
                {jobs.filter((j: any) => j.status === 'active').length}
              </p>
            </div>
            <div className="bg-white rounded-lg border border-gray-200 p-4 shadow-sm">
              <p className="text-sm text-gray-600">Completed</p>
              <p className="text-2xl font-bold text-blue-600 mt-1">
                {jobs.filter((j: any) => j.status === 'completed').length}
              </p>
            </div>
            <div className="bg-white rounded-lg border border-gray-200 p-4 shadow-sm">
              <p className="text-sm text-gray-600">Total Value</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">
                {formatCurrency(jobs.reduce((sum: number, j: any) => sum + (j.projectValue || 0), 0))}
              </p>
            </div>
          </div>
        )}

        {/* Jobs List */}
        {filteredJobs.length === 0 ? (
          <div className="bg-white rounded-xl border border-gray-200 p-12 shadow-sm text-center">
            <AlertCircle className="w-16 h-16 text-gray-400 mx-auto mb-4" />
            <h3 className="text-xl font-semibold text-gray-900 mb-2">No jobs found</h3>
            <p className="text-gray-600 mb-6">
              {searchQuery || statusFilter !== 'all'
                ? 'Try adjusting your filters'
                : 'Create your first job to get started'}
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-4">
            {filteredJobs.map((job: any) => {
              const metrics = getJobMetrics(job);
              return (
                <div
                  key={job.id}
                  className="bg-white rounded-xl border border-gray-200 p-6 shadow-sm hover:shadow-md transition cursor-pointer"
                  onClick={() => router.push(`/jobs/${job.id}`)}
                >
                  <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
                    <div className="flex-1">
                      <div className="flex items-start justify-between mb-2">
                        <div>
                          <h3 className="text-xl font-bold text-gray-900 dark:text-white">{job.jobName}</h3>
                          <p className="text-gray-600 dark:text-gray-400">{job.clientName}</p>
                        </div>
                        {getStatusBadge(job.status)}
                      </div>

                      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mt-4">
                        <div>
                          <p className="text-xs text-gray-500 mb-1">Contract Value</p>
                          <p className="font-semibold text-gray-900 dark:text-white">{formatCurrency(job.projectValue)}</p>
                        </div>
                        <div>
                          <p className="text-xs text-gray-500 mb-1">Paid</p>
                          <p className="font-semibold text-green-600">{formatCurrency(job.amountPaid || 0)}</p>
                        </div>
                        <div>
                          <p className="text-xs text-gray-500 mb-1">Remaining</p>
                          <p className="font-semibold text-amber-600">{formatCurrency(metrics.remainingBalance)}</p>
                        </div>
                        <div>
                          <p className="text-xs text-gray-500 mb-1">Profit</p>
                          <p className={`font-semibold ${metrics.profit >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                            {formatCurrency(metrics.profit)}
                          </p>
                        </div>
                      </div>

                      {job.address && (
                        <div className="flex items-center gap-2 mt-3 text-sm text-gray-600">
                          <MapPin className="w-4 h-4" />
                          {job.address}
                        </div>
                      )}

                      {(job.startDate || job.endDate) && (
                        <div className="flex items-center gap-4 mt-2 text-sm text-gray-600">
                          {job.startDate && (
                            <div className="flex items-center gap-1">
                              <Calendar className="w-4 h-4" />
                              Start: {new Date(job.startDate).toLocaleDateString()}
                            </div>
                          )}
                          {job.endDate && (
                            <div className="flex items-center gap-1">
                              <Calendar className="w-4 h-4" />
                              End: {new Date(job.endDate).toLocaleDateString()}
                            </div>
                          )}
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
