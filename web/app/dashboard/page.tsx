'use client';

import { Suspense, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import APIService from '@/lib/api';
import AuthService from '@/lib/auth';
import DashboardLayout from '@/components/dashboard-layout';
import AuthGuard from '@/components/auth-guard';
import OwnerOnly from '@/components/owner-only';
import { calculateProfit, remainingBalance } from '@/types/models';
import {
  Briefcase,
  DollarSign,
  TrendingUp,
  Receipt as ReceiptIcon,
  Loader2,
  AlertCircle,
  Plus,
  Clock,
  Upload,
  Activity,
} from 'lucide-react';

// Disable Next.js page caching for dashboard (auth-protected)
export const dynamic = 'force-dynamic';

export default function Dashboard() {
  const router = useRouter();
  const user = AuthService.getCurrentUser();

  // Block workers from accessing owner dashboard
  useEffect(() => {
    if (user?.role === 'worker') {
      router.replace('/worker/dashboard');
    }
  }, [user, router]);

  // Early return for workers
  if (user?.role === 'worker') {
    return null;
  }

  const { data: jobs = [], isLoading: jobsLoading } = useQuery({
    queryKey: ['jobs'],
    queryFn: () => APIService.fetchJobs(),
    enabled: true, // AuthGuard blocks rendering until auth is confirmed
  });

  const { data: receipts = [], isLoading: receiptsLoading } = useQuery({
    queryKey: ['receipts'],
    queryFn: () => APIService.fetchReceipts(),
    enabled: true,
  });

  const { data: timesheets = [], isLoading: timesheetsLoading } = useQuery({
    queryKey: ['timesheets'],
    queryFn: () => APIService.fetchTimesheets(),
    enabled: true,
  });

  // Only fetch workers for owners (workers don't have permission)
  const { data: workers = [] } = useQuery({
    queryKey: ['workers'],
    queryFn: () => APIService.fetchWorkers(),
    enabled: user?.role === 'owner',
  });

  const isLoading = jobsLoading || receiptsLoading || timesheetsLoading;

  // USE EXACT BACKEND CALCULATIONS - NO CLIENT-SIDE ESTIMATION
  const activeJobs = jobs.filter((j: any) => j.status === 'active');

  // Backend provides exact calculations per job - just sum them up
  const totalProjectValue = jobs.reduce((sum: number, j: any) => sum + (j.projectValue || 0), 0);
  const totalPayments = jobs.reduce((sum: number, j: any) => sum + (j.amountPaid || 0), 0);
  const totalCost = jobs.reduce((sum: number, j: any) => sum + (j.totalCost || 0), 0);
  const totalProfit = jobs.reduce((sum: number, j: any) => sum + (j.profit || 0), 0);
  const totalRemaining = jobs.reduce((sum: number, j: any) => sum + (j.remainingBalance || 0), 0);

  // Format currency with EXACT amounts - no abbreviations
  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(value);
  };

  const today = new Date().toLocaleDateString('en-US', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });

  if (isLoading) {
    return (
      <Suspense fallback={
        <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100">
          <div className="text-center">
            <Loader2 className="w-12 h-12 text-blue-600 animate-spin mx-auto mb-4" />
            <p className="text-gray-600 dark:text-gray-400">Verifying session...</p>
          </div>
        </div>
      }>
        <AuthGuard>
          <DashboardLayout>
            <div className="flex items-center justify-center min-h-[60vh]">
              <div className="text-center">
                <Loader2 className="w-12 h-12 text-blue-600 animate-spin mx-auto mb-4" />
                <p className="text-gray-600 dark:text-gray-400">Loading dashboard...</p>
              </div>
            </div>
          </DashboardLayout>
        </AuthGuard>
      </Suspense>
    );
  }

  return (
    <Suspense fallback={
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100">
        <div className="text-center">
          <Loader2 className="w-12 h-12 text-blue-600 animate-spin mx-auto mb-4" />
          <p className="text-gray-600 dark:text-gray-400">Verifying session...</p>
        </div>
      </div>
    }>
      <AuthGuard>
        <DashboardLayout>
          <div className="fixed bottom-2 right-2 z-50 text-[10px] font-mono text-gray-500 bg-white/80 border border-gray-200 rounded px-2 py-1">
            build: 2025-12-31-authguard-v2
          </div>
          <div className="space-y-6">
            {/* Header with Quick Actions */}
            <div className="bg-gradient-to-r from-blue-600 to-indigo-600 rounded-2xl p-8 text-white shadow-lg">
              <h1 className="text-3xl lg:text-4xl font-bold mb-2">
                Welcome back, {user?.name || 'User'}!
              </h1>
              <p className="text-blue-100 mb-6">{today}</p>
              
              {/* Quick Actions - Moved under name */}
              <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
                <button
                  onClick={() => router.push('/jobs/create')}
                  className="flex flex-col items-center gap-2 p-4 bg-white/10 backdrop-blur-sm border border-white/20 rounded-lg hover:bg-white/20 transition text-center"
                >
                  <div className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
                    <Briefcase className="w-5 h-5 text-white" />
                  </div>
                  <span className="text-sm font-medium text-white">New Job</span>
                </button>
                <button
                  onClick={() => router.push('/receipts/create')}
                  className="flex flex-col items-center gap-2 p-4 bg-white/10 backdrop-blur-sm border border-white/20 rounded-lg hover:bg-white/20 transition text-center"
                >
                  <div className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
                    <ReceiptIcon className="w-5 h-5 text-white" />
                  </div>
                  <span className="text-sm font-medium text-white">Add Receipt</span>
                </button>
                <button
                  onClick={() => router.push('/timesheets/create')}
                  className="flex flex-col items-center gap-2 p-4 bg-white/10 backdrop-blur-sm border border-white/20 rounded-lg hover:bg-white/20 transition text-center"
                >
                  <div className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
                    <Clock className="w-5 h-5 text-white" />
                  </div>
                  <span className="text-sm font-medium text-white">Log Hours</span>
                </button>
                <button
                  onClick={() => router.push('/documents/upload')}
                  className="flex flex-col items-center gap-2 p-4 bg-white/10 backdrop-blur-sm border border-white/20 rounded-lg hover:bg-white/20 transition text-center"
                >
                  <div className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
                    <Upload className="w-5 h-5 text-white" />
                  </div>
                  <span className="text-sm font-medium text-white">Upload Doc</span>
                </button>
              </div>
            </div>

            {/* Stats Grid - Show all for owners, limited for workers */}
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
              <StatCard
                title="Active Jobs"
                value={activeJobs.length.toString()}
                icon={Briefcase}
                iconBg="bg-blue-100"
                iconColor="text-blue-600"
              />
              {user?.role === 'owner' && (
                <>
                  <StatCard
                    title="Total Contract Value"
                    value={formatCurrency(totalProjectValue)}
                    icon={DollarSign}
                    iconBg="bg-green-100"
                    iconColor="text-green-600"
                  />
                  <StatCard
                    title="Payments Received"
                    value={formatCurrency(totalPayments)}
                    icon={ReceiptIcon}
                    iconBg="bg-purple-100"
                    iconColor="text-purple-600"
                  />
                  <StatCard
                    title="Total Profit"
                    value={formatCurrency(totalProfit)}
                    icon={TrendingUp}
                    iconBg={totalProfit >= 0 ? 'bg-green-100' : 'bg-red-100'}
                    iconColor={totalProfit >= 0 ? 'text-green-600' : 'text-red-600'}
                  />
                </>
              )}
            </div>

            {/* Secondary Stats - Only for owners */}
            {user?.role === 'owner' && (
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
                <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">
                  <p className="text-sm font-medium text-gray-600 dark:text-gray-400 mb-2">Total Costs</p>
                  <p className="text-2xl font-bold text-gray-900 dark:text-white">{formatCurrency(totalCost)}</p>
                  <p className="text-xs text-gray-500 dark:text-gray-400 mt-2">Labor + Materials + Receipts</p>
                </div>
                <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">
                  <p className="text-sm font-medium text-gray-600 dark:text-gray-400 mb-2">Remaining Balance</p>
                  <p className="text-2xl font-bold text-amber-600 dark:text-amber-500">{formatCurrency(totalRemaining)}</p>
                  <p className="text-xs text-gray-500 dark:text-gray-400 mt-2">Unpaid from clients</p>
                </div>
                <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">
                  <p className="text-sm font-medium text-gray-600 dark:text-gray-400 mb-2">Profit Margin</p>
                  <p className="text-2xl font-bold text-gray-900 dark:text-white">
                    {totalProjectValue > 0 ? ((totalProfit / totalProjectValue) * 100).toFixed(1) : 0}%
                  </p>
                  <p className="text-xs text-gray-500 dark:text-gray-400 mt-2">Of total contract value</p>
                </div>
              </div>
            )}

            {/* Recent Activity */}
            <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">
              <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
                <Activity className="w-5 h-5 text-gray-900 dark:text-white" />
                Recent Activity
              </h2>
              <div className="space-y-3">
                {/* Recent Jobs */}
                {jobs.slice(0, 3).map((job: any) => (
                  <div key={`job-${job.id}`} className="flex items-center gap-3 p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                    <div className="w-10 h-10 bg-blue-100 dark:bg-blue-900 rounded-full flex items-center justify-center flex-shrink-0">
                      <Briefcase className="w-5 h-5 text-blue-600 dark:text-blue-400" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-gray-900 dark:text-white truncate">{job.jobName}</p>
                      <p className="text-xs text-gray-500 dark:text-gray-400">
                        Created {new Date(job.createdAt).toLocaleDateString()}
                      </p>
                    </div>
                    <span className={`px-2 py-1 text-xs font-medium rounded-full ${job.status === 'active' ? 'bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-300' :
                      job.status === 'completed' ? 'bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-300' :
                        'bg-gray-100 text-gray-700 dark:bg-gray-600 dark:text-gray-300'
                      }`}>
                      {job.status}
                    </span>
                  </div>
                ))}
                {/* Recent Receipts */}
                {receipts.slice(0, 2).map((receipt: any) => (
                  <div key={`receipt-${receipt.id}`} className="flex items-center gap-3 p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                    <div className="w-10 h-10 bg-green-100 dark:bg-green-900 rounded-full flex items-center justify-center flex-shrink-0">
                      <ReceiptIcon className="w-5 h-5 text-green-600 dark:text-green-400" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-gray-900 dark:text-white truncate">{receipt.vendor || 'Receipt'}</p>
                      <p className="text-xs text-gray-500 dark:text-gray-400">
                        {new Date(receipt.date).toLocaleDateString()}
                      </p>
                    </div>
                    <span className="text-sm font-semibold text-gray-900 dark:text-white">{formatCurrency(receipt.amount || 0)}</span>
                  </div>
                ))}
                {/* Recent Timesheets */}
                {timesheets.slice(0, 2).map((timesheet: any) => {
                  const worker = workers.find((w: any) => w.id === timesheet.workerID);
                  return (
                    <div key={`timesheet-${timesheet.id}`} className="flex items-center gap-3 p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                      <div className="w-10 h-10 bg-purple-100 dark:bg-purple-900 rounded-full flex items-center justify-center flex-shrink-0">
                        <Clock className="w-5 h-5 text-purple-600 dark:text-purple-400" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-gray-900 dark:text-white truncate">{worker?.name || 'Worker'}</p>
                        <p className="text-xs text-gray-500 dark:text-gray-400">
                          {new Date(timesheet.clockIn).toLocaleDateString()}
                        </p>
                      </div>
                      <span className="text-sm font-semibold text-gray-900 dark:text-white">{timesheet.hours?.toFixed(1) || '0.0'} hrs</span>
                    </div>
                  );
                })}
                {jobs.length === 0 && receipts.length === 0 && timesheets.length === 0 && (
                  <div className="text-center py-8">
                    <Activity className="w-12 h-12 text-gray-400 dark:text-gray-500 mx-auto mb-3" />
                    <p className="text-gray-600 dark:text-gray-400 text-sm">No recent activity</p>
                    <p className="text-gray-500 dark:text-gray-500 text-xs mt-1">Start by creating a job or adding a receipt</p>
                  </div>
                )}
              </div>
            </div>


            {/* Active Jobs List */}
            <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">
              <h2 className="text-xl font-bold text-gray-900 mb-4">Active Jobs</h2>
              {activeJobs.length === 0 ? (
                <div className="text-center py-12">
                  <AlertCircle className="w-12 h-12 text-gray-400 mx-auto mb-3" />
                  <p className="text-gray-600 dark:text-gray-400">No active jobs</p>
                  <a href="/jobs" className="text-blue-600 hover:text-blue-700 text-sm mt-2 inline-block">
                    Create your first job
                  </a>
                </div>
              ) : (
                <div className="space-y-3">
                  {activeJobs.slice(0, 5).map((job: any) => (
                    <a
                      key={job.id}
                      href={`/jobs/${job.id}`}
                      className="block p-4 border border-gray-200 rounded-lg hover:border-blue-500 hover:shadow-md transition"
                    >
                      <div className="flex justify-between items-start">
                        <div>
                          <h3 className="font-semibold text-gray-900 dark:text-white">{job.jobName}</h3>
                          <p className="text-sm text-gray-600">{job.clientName}</p>
                        </div>
                        <div className="text-right">
                          <p className="font-semibold text-gray-900 dark:text-white">{formatCurrency(job.projectValue)}</p>
                          <p className="text-xs text-gray-500">Contract Value</p>
                        </div>
                      </div>
                    </a>
                  ))}
                </div>
              )}
            </div>
          </div>
        </DashboardLayout>
      </AuthGuard>
    </Suspense>
  );
}

interface StatCardProps {
  title: string;
  value: string;
  icon: any;
  iconBg: string;
  iconColor: string;
}

function StatCard({ title, value, icon: Icon, iconBg, iconColor }: StatCardProps) {
  return (
    <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <p className="text-sm font-medium text-gray-600 dark:text-gray-400 mb-2">{title}</p>
          <p className="text-2xl lg:text-3xl font-bold text-gray-900 dark:text-white">{value}</p>
        </div>
        <div className={`${iconBg} dark:bg-opacity-20 p-3 rounded-lg`}>
          <Icon className={`w-6 h-6 ${iconColor} dark:opacity-90`} />
        </div>
      </div>
    </div>
  );
}
