'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import DashboardLayout from '@/components/dashboard-layout';
import AuthService from '@/lib/auth';
import APIService from '@/lib/api';
import { Clock, DollarSign, Calendar } from 'lucide-react';

interface WorkerHours {
  workerId: string;
  workerName: string;
  hoursThisWeek: number;
  hoursThisMonth: number;
  hourlyRate: number;
  totalEarnings: number;
}

export default function AllWorkersHours() {
  const router = useRouter();
  const [workers, setWorkers] = useState<any[]>([]);
  const [timesheets, setTimesheets] = useState<any[]>([]);
  const [workerHours, setWorkerHours] = useState<WorkerHours[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [dateRange, setDateRange] = useState<'week' | 'month' | 'all'>('month');

  useEffect(() => {
    if (!AuthService.isAuthenticated()) {
      router.push('/auth/signin');
    } else {
      loadData();
    }
  }, []);

  useEffect(() => {
    if (workers.length > 0 && timesheets.length > 0) {
      calculateWorkerHours();
    }
  }, [workers, timesheets, dateRange]);

  const loadData = async () => {
    try {
      setIsLoading(true);
      const [workersData, timesheetsData] = await Promise.all([
        APIService.fetchWorkers(),
        APIService.fetchTimesheets()
      ]);

      setWorkers(workersData);
      setTimesheets(timesheetsData);
    } catch (error) {
      // Silently fail - UI will show empty state
    } finally {
      setIsLoading(false);
    }
  };

  const calculateWorkerHours = () => {
    const now = new Date();
    const startOfWeek = new Date(now);
    startOfWeek.setDate(now.getDate() - now.getDay());
    startOfWeek.setHours(0, 0, 0, 0);

    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const hours: WorkerHours[] = workers.map(worker => {
      const workerTimesheets = timesheets.filter(t => t.user_id === worker.id);
      
      const hoursThisWeek = workerTimesheets
        .filter(t => new Date(t.date) >= startOfWeek)
        .reduce((sum, t) => sum + (t.hours || 0), 0);

      const hoursThisMonth = workerTimesheets
        .filter(t => new Date(t.date) >= startOfMonth)
        .reduce((sum, t) => sum + (t.hours || 0), 0);

      const hourlyRate = worker.hourly_rate || 0;
      
      let totalEarnings = 0;
      if (dateRange === 'week') {
        totalEarnings = hoursThisWeek * hourlyRate;
      } else if (dateRange === 'month') {
        totalEarnings = hoursThisMonth * hourlyRate;
      } else {
        const totalHours = workerTimesheets.reduce((sum, t) => sum + (t.hours || 0), 0);
        totalEarnings = totalHours * hourlyRate;
      }

      return {
        workerId: worker.id,
        workerName: worker.name,
        hoursThisWeek,
        hoursThisMonth,
        hourlyRate,
        totalEarnings
      };
    });

    setWorkerHours(hours);
  };

  const totalHours = workerHours.reduce((sum, w) => {
    if (dateRange === 'week') return sum + w.hoursThisWeek;
    if (dateRange === 'month') return sum + w.hoursThisMonth;
    return sum + w.hoursThisWeek + w.hoursThisMonth;
  }, 0);

  const totalEarnings = workerHours.reduce((sum, w) => sum + w.totalEarnings, 0);

  if (isLoading) {
    return (
      <DashboardLayout>
        <div className="flex items-center justify-center h-64">
          <div className="text-gray-500">Loading worker hours...</div>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <div className="max-w-7xl mx-auto space-y-6">
        <div className="flex items-center justify-between">
          <h1 className="text-3xl font-bold text-gray-900">All Workers Hours</h1>
          
          {/* Date Range Filter */}
          <div className="flex items-center gap-2 bg-gray-100 p-1 rounded-lg">
            <button
              onClick={() => setDateRange('week')}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition ${
                dateRange === 'week'
                  ? 'bg-white text-blue-600 shadow-sm'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              This Week
            </button>
            <button
              onClick={() => setDateRange('month')}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition ${
                dateRange === 'month'
                  ? 'bg-white text-blue-600 shadow-sm'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              This Month
            </button>
            <button
              onClick={() => setDateRange('all')}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition ${
                dateRange === 'all'
                  ? 'bg-white text-blue-600 shadow-sm'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              All Time
            </button>
          </div>
        </div>

        {/* Summary Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl p-6 text-white shadow-lg">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-blue-100 text-sm mb-1">Total Hours</p>
                <p className="text-3xl font-bold">{totalHours.toFixed(1)}</p>
              </div>
              <div className="p-3 bg-blue-400 rounded-lg">
                <Clock className="w-8 h-8" />
              </div>
            </div>
          </div>

          <div className="bg-gradient-to-br from-green-500 to-green-600 rounded-xl p-6 text-white shadow-lg">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-green-100 text-sm mb-1">Total Earnings</p>
                <p className="text-3xl font-bold">${totalEarnings.toFixed(2)}</p>
              </div>
              <div className="p-3 bg-green-400 rounded-lg">
                <DollarSign className="w-8 h-8" />
              </div>
            </div>
          </div>

          <div className="bg-gradient-to-br from-purple-500 to-purple-600 rounded-xl p-6 text-white shadow-lg">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-purple-100 text-sm mb-1">Active Workers</p>
                <p className="text-3xl font-bold">{workerHours.filter(w => w.hoursThisWeek > 0 || w.hoursThisMonth > 0).length}</p>
              </div>
              <div className="p-3 bg-purple-400 rounded-lg">
                <Calendar className="w-8 h-8" />
              </div>
            </div>
          </div>
        </div>

        {/* Workers Table */}
        <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Worker Name
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Hours This Week
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Hours This Month
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Hourly Rate
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Total Earnings ({dateRange})
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {workerHours.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="px-6 py-12 text-center text-gray-500">
                      No worker data available. Add workers to see hours and earnings.
                    </td>
                  </tr>
                ) : (
                  workerHours.map((worker) => (
                    <tr key={worker.workerId} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="flex items-center">
                          <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center text-blue-600 font-semibold">
                            {worker.workerName.charAt(0).toUpperCase()}
                          </div>
                          <div className="ml-3">
                            <p className="text-sm font-medium text-gray-900">{worker.workerName}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {worker.hoursThisWeek.toFixed(2)} hrs
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {worker.hoursThisMonth.toFixed(2)} hrs
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        ${worker.hourlyRate.toFixed(2)}/hr
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-semibold text-green-600">
                        ${worker.totalEarnings.toFixed(2)}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
}
