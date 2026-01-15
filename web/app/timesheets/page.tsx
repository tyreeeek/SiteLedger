'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import APIService from '@/lib/api';
import AuthService from '@/lib/auth';
import DashboardLayout from '@/components/dashboard-layout';
import { Clock, Loader2, Search, Plus, Calendar, User, AlertCircle } from 'lucide-react';

export default function Timesheets() {
  const router = useRouter();
  const [isAuthChecked, setIsAuthChecked] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [user, setUser] = useState<any>(null);

  useEffect(() => {
    if (!AuthService.isAuthenticated()) {
      router.push('/auth/signin');
    } else {
      const currentUser = AuthService.getCurrentUser();
      setUser(currentUser);
      setIsAuthChecked(true);
    }
  }, [router]);

  const { data: timesheets = [], isLoading } = useQuery({
    queryKey: ['timesheets'],
    queryFn: () => APIService.fetchTimesheets(),
    enabled: isAuthChecked,
  });

  // Only fetch workers and jobs if user is an owner
  const { data: workers = [] } = useQuery({
    queryKey: ['workers'],
    queryFn: () => APIService.fetchWorkers(),
    enabled: isAuthChecked && user?.role === 'owner',
  });

  const { data: jobs = [] } = useQuery({
    queryKey: ['jobs'],
    queryFn: () => APIService.fetchJobs(),
    enabled: isAuthChecked && user?.role === 'owner',
  });

  if (!isAuthChecked) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
      </div>
    );
  }

  const filteredTimesheets = timesheets.filter((ts: any) => {
    if (!searchQuery) return true;
    
    // For workers, search by job name in timesheet or search query
    if (user?.role === 'worker') {
      return ts.jobName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
             ts.workerName?.toLowerCase().includes(searchQuery.toLowerCase());
    }
    
    // For owners, search by worker name or job name
    const worker = workers.find((w: any) => w.id === ts.workerID);
    const job = jobs.find((j: any) => j.id === ts.jobID);
    return worker?.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
           job?.jobName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
           ts.workerName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
           ts.jobName?.toLowerCase().includes(searchQuery.toLowerCase());
  });

  const totalHours = timesheets.reduce((sum: number, ts: any) => sum + (ts.hours || 0), 0);
  const totalCost = timesheets.reduce((sum: number, ts: any) => {
    const worker = workers.find((w: any) => w.id === ts.workerID);
    // Use hourlyRate from timesheet if workers array is empty (for worker users)
    const rate = worker?.hourlyRate || ts.hourlyRate || 0;
    return sum + ((ts.hours || 0) * rate);
  }, 0);

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('en-US', { 
      style: 'currency', 
      currency: 'USD',
      minimumFractionDigits: 0,
    }).format(value);
  };

  if (isLoading) {
    return (
      <DashboardLayout>
        <div className="flex items-center justify-center min-h-[60vh]">
          <div className="text-center">
            <Loader2 className="w-12 h-12 text-blue-600 animate-spin mx-auto mb-4" />
            <p className="text-gray-600 dark:text-gray-400">Loading timesheets...</p>
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
            <h1 className="text-3xl lg:text-4xl font-bold text-gray-900 dark:text-white">Timesheets</h1>
            <p className="text-gray-600 dark:text-gray-400 mt-2">Track worker hours and labor costs</p>
          </div>
          <button 
            onClick={() => router.push('/timesheets/create')}
            className="flex items-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition shadow-lg"
          >
            <Plus className="w-5 h-5" />
            Add Entry
          </button>
        </div>

        {/* Search */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-4 shadow-sm">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 dark:text-gray-500 w-5 h-5" />
            <input
              type="text"
              placeholder="Search by worker or job..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none bg-white dark:bg-gray-700 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400"
            />
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4 shadow-sm">
            <p className="text-sm text-gray-600 dark:text-gray-400">Total Entries</p>
            <p className="text-2xl font-bold text-gray-900 dark:text-white mt-1">{timesheets.length}</p>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4 shadow-sm">
            <p className="text-sm text-gray-600 dark:text-gray-400">Total Hours</p>
            <p className="text-2xl font-bold text-blue-600 dark:text-blue-400 mt-1">{totalHours.toFixed(1)}h</p>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4 shadow-sm">
            <p className="text-sm text-gray-600 dark:text-gray-400">Labor Cost</p>
            <p className="text-2xl font-bold text-red-600 dark:text-red-400 mt-1">{formatCurrency(totalCost)}</p>
          </div>
        </div>

        {/* Timesheets List */}
        {filteredTimesheets.length === 0 ? (
          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-12 shadow-sm text-center">
            <AlertCircle className="w-16 h-16 text-gray-400 dark:text-gray-500 mx-auto mb-4" />
            <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">No timesheets found</h3>
            <p className="text-gray-600 dark:text-gray-400">
              {searchQuery ? 'Try adjusting your search' : 'Add your first timesheet entry'}
            </p>
          </div>
        ) : (
          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-gray-50 dark:bg-gray-700 border-b border-gray-200 dark:border-gray-600">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                      Worker
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Job
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Date
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Hours
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Cost
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                  {filteredTimesheets.map((ts: any) => {
                    const worker = workers.find((w: any) => w.id === ts.workerID);
                    const job = jobs.find((j: any) => j.id === ts.jobID);
                    // Use workerName from timesheet if workers array is empty (for worker users)
                    const workerName = worker?.name || ts.workerName || 'Unknown';
                    const workerRate = worker?.hourlyRate || ts.hourlyRate || 0;
                    const jobName = job?.jobName || ts.jobName || 'No Job';
                    const cost = (ts.hours || 0) * workerRate;
                    
                    return (
                      <tr key={ts.id} className="hover:bg-gray-50 dark:hover:bg-gray-700">
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="flex items-center">
                            <div className="flex-shrink-0 h-10 w-10 bg-blue-100 dark:bg-blue-900/30 rounded-full flex items-center justify-center">
                              <User className="h-5 w-5 text-blue-600 dark:text-blue-400" />
                            </div>
                            <div className="ml-4">
                              <div className="text-sm font-medium text-gray-900 dark:text-white">{workerName}</div>
                            </div>
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="text-sm text-gray-900 dark:text-white">{jobName}</div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="text-sm text-gray-500 dark:text-gray-400">
                            {ts.clockIn ? new Date(ts.clockIn).toLocaleDateString() : 'N/A'}
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="text-sm font-semibold text-gray-900 dark:text-white">{(ts.hours || 0).toFixed(2)}h</div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="text-sm font-semibold text-red-600 dark:text-red-400">{formatCurrency(cost)}</div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
