'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import DashboardLayout from '@/components/dashboard-layout';
import AuthService from '@/lib/auth';
import APIService from '@/lib/api';
import { Check, X, Clock } from 'lucide-react';

type TimesheetStatus = 'pending' | 'approved' | 'rejected';

interface TimesheetWithWorker {
  id: string;
  worker_name: string;
  job_name: string;
  date: string;
  hours: number;
  status: TimesheetStatus;
  clock_in?: string;
  clock_out?: string;
}

export default function ApproveTimesheets() {
  const router = useRouter();
  const [activeTab, setActiveTab] = useState<TimesheetStatus>('pending');
  const [timesheets, setTimesheets] = useState<TimesheetWithWorker[]>([]);
  const [workers, setWorkers] = useState<any[]>([]);
  const [jobs, setJobs] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    if (!AuthService.isAuthenticated()) {
      router.push('/auth/signin');
    } else {
      loadData();
    }
  }, []);

  const loadData = async () => {
    try {
      setIsLoading(true);
      const [timesheetsData, workersData, jobsData] = await Promise.all([
        APIService.fetchTimesheets(),
        APIService.fetchWorkers(),
        APIService.fetchJobs()
      ]);

      setWorkers(workersData);
      setJobs(jobsData);

      // Combine data
      const combined: TimesheetWithWorker[] = timesheetsData.map(t => {
        const worker = workersData.find(w => w.id === t.user_id);
        const job = jobsData.find(j => j.id === t.job_id);
        return {
          id: t.id,
          worker_name: worker?.name || 'Unknown Worker',
          job_name: job?.job_name || 'Unknown Job',
          date: t.date || new Date().toISOString(),
          hours: t.hours || 0,
          status: (t.status || 'pending') as TimesheetStatus,
          clock_in: t.clock_in,
          clock_out: t.clock_out
        };
      });

      setTimesheets(combined);
    } catch (error) {
      // Silently fail - UI will show empty state
    } finally {
      setIsLoading(false);
    }
  };

  const handleApprove = async (timesheetId: string) => {
    try {
      const timesheet = timesheets.find(t => t.id === timesheetId);
      if (!timesheet) return;
      
      await APIService.updateTimesheet(timesheetId, { status: 'approved' });
      
      setTimesheets(prev => prev.map(t =>
        t.id === timesheetId ? { ...t, status: 'approved' as const } : t
      ));
    } catch (error) {
      // Silently fail - UI stays unchanged
    }
  };

  const handleReject = async (timesheetId: string) => {
    try {
      const timesheet = timesheets.find(t => t.id === timesheetId);
      if (!timesheet) return;
      
      await APIService.updateTimesheet(timesheetId, { status: 'rejected' });
      
      setTimesheets(prev => prev.map(t =>
        t.id === timesheetId ? { ...t, status: 'rejected' as const } : t
      ));
    } catch (error) {
      // Silently fail - UI stays unchanged
    }
  };

  const handleBatchApprove = async () => {
    const pendingIds = filteredTimesheets.map(t => t.id);
    
    try {
      // Approve all pending timesheets
      await Promise.all(
        pendingIds.map(id => APIService.updateTimesheet(id, { status: 'approved' }))
      );
      
      setTimesheets(prev => prev.map(t =>
        pendingIds.includes(t.id) ? { ...t, status: 'approved' as const } : t
      ));
    } catch (error) {
      // Silently fail - UI shows partial updates
    }
  };

  const filteredTimesheets = timesheets.filter(t => t.status === activeTab);

  if (isLoading) {
    return (
      <DashboardLayout>
        <div className="flex items-center justify-center h-64">
          <div className="text-gray-500">Loading timesheets...</div>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <div className="max-w-7xl mx-auto space-y-6">
        <div className="flex items-center justify-between">
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Approve Timesheets</h1>
          {activeTab === 'pending' && filteredTimesheets.length > 0 && (
            <button
              onClick={handleBatchApprove}
              className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition"
            >
              <Check className="w-5 h-5" />
              Approve All ({filteredTimesheets.length})
            </button>
          )}
        </div>

        {/* Tabs */}
        <div className="bg-white rounded-xl border border-gray-200 shadow-sm">
          <div className="flex border-b border-gray-200">
            <button
              onClick={() => setActiveTab('pending')}
              className={`flex-1 px-6 py-4 text-sm font-medium transition ${
                activeTab === 'pending'
                  ? 'text-blue-600 border-b-2 border-blue-600'
                  : 'text-gray-500 hover:text-gray-700'
              }`}
            >
              Pending ({timesheets.filter(t => t.status === 'pending').length})
            </button>
            <button
              onClick={() => setActiveTab('approved')}
              className={`flex-1 px-6 py-4 text-sm font-medium transition ${
                activeTab === 'approved'
                  ? 'text-green-600 border-b-2 border-green-600'
                  : 'text-gray-500 hover:text-gray-700'
              }`}
            >
              Approved ({timesheets.filter(t => t.status === 'approved').length})
            </button>
            <button
              onClick={() => setActiveTab('rejected')}
              className={`flex-1 px-6 py-4 text-sm font-medium transition ${
                activeTab === 'rejected'
                  ? 'text-red-600 border-b-2 border-red-600'
                  : 'text-gray-500 hover:text-gray-700'
              }`}
            >
              Rejected ({timesheets.filter(t => t.status === 'rejected').length})
            </button>
          </div>

          {/* Timesheets List */}
          <div className="divide-y divide-gray-200">
            {filteredTimesheets.length === 0 ? (
              <div className="p-12 text-center text-gray-500">
                <Clock className="w-16 h-16 mx-auto mb-4 text-gray-300" />
                <p className="text-lg font-medium">No {activeTab} timesheets</p>
                <p className="text-sm mt-1">
                  {activeTab === 'pending' && 'All timesheets have been reviewed.'}
                  {activeTab === 'approved' && 'No approved timesheets yet.'}
                  {activeTab === 'rejected' && 'No rejected timesheets yet.'}
                </p>
              </div>
            ) : (
              filteredTimesheets.map((timesheet) => (
                <div key={timesheet.id} className="p-6 hover:bg-gray-50 transition">
                  <div className="flex items-center justify-between">
                    <div className="flex items-start gap-4 flex-1">
                      <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center text-blue-600 font-semibold">
                        {timesheet.worker_name.charAt(0).toUpperCase()}
                      </div>
                      <div className="flex-1">
                        <div className="flex items-center gap-3 mb-2">
                          <h3 className="text-lg font-semibold text-gray-900 dark:text-white">{timesheet.worker_name}</h3>
                          <span className="px-2 py-1 bg-gray-100 text-gray-700 text-xs font-medium rounded">
                            {timesheet.job_name}
                          </span>
                        </div>
                        <div className="flex items-center gap-6 text-sm text-gray-600">
                          <div className="flex items-center gap-2">
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                            </svg>
                            {new Date(timesheet.date).toLocaleDateString('en-US', {
                              month: 'short',
                              day: 'numeric',
                              year: 'numeric'
                            })}
                          </div>
                          <div className="flex items-center gap-2">
                            <Clock className="w-4 h-4" />
                            {timesheet.hours.toFixed(2)} hours
                          </div>
                          {timesheet.clock_in && (
                            <div className="flex items-center gap-2">
                              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                              </svg>
                              {new Date(timesheet.clock_in).toLocaleTimeString('en-US', {
                                hour: '2-digit',
                                minute: '2-digit'
                              })}
                              {timesheet.clock_out && (
                                <> - {new Date(timesheet.clock_out).toLocaleTimeString('en-US', {
                                  hour: '2-digit',
                                  minute: '2-digit'
                                })}</>
                              )}
                            </div>
                          )}
                        </div>
                      </div>
                    </div>

                    {/* Actions */}
                    {activeTab === 'pending' && (
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => handleApprove(timesheet.id)}
                          className="flex items-center gap-1 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition"
                        >
                          <Check className="w-4 h-4" />
                          Approve
                        </button>
                        <button
                          onClick={() => handleReject(timesheet.id)}
                          className="flex items-center gap-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition"
                        >
                          <X className="w-4 h-4" />
                          Reject
                        </button>
                      </div>
                    )}

                    {activeTab === 'approved' && (
                      <span className="px-3 py-1 bg-green-100 text-green-800 text-sm font-semibold rounded-full">
                        ✓ Approved
                      </span>
                    )}

                    {activeTab === 'rejected' && (
                      <span className="px-3 py-1 bg-red-100 text-red-800 text-sm font-semibold rounded-full">
                        ✗ Rejected
                      </span>
                    )}
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
}
