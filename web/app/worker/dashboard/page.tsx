'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import DashboardLayout from '@/components/dashboard-layout';
import AuthService from '@/lib/auth';
import APIService from '@/lib/api';
import { Briefcase, Clock, DollarSign, Calendar, TrendingUp, MapPin } from 'lucide-react';

export default function WorkerDashboard() {
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [user, setUser] = useState<any>(null);
  const [stats, setStats] = useState({
    hoursToday: 0,
    hoursWeek: 0,
    hoursMonth: 0,
    earningsWeek: 0,
    earningsMonth: 0,
    activeJobs: 0,
    currentlyClocked: false,
    currentJob: null as any
  });
  const [recentJobs, setRecentJobs] = useState<any[]>([]);

  useEffect(() => {
    loadDashboard();
  }, []);

  const loadDashboard = async () => {
    try {
      const currentUser = AuthService.getCurrentUser();
      if (!currentUser || currentUser.role !== 'worker') {
        router.push('/auth/signin');
        return;
      }
      setUser(currentUser);

      // Load worker stats
      const [timesheetsData, jobsData] = await Promise.all([
        APIService.fetchTimesheets().catch(() => ({ timesheets: [] })),
        APIService.fetchJobs().catch(() => ({ jobs: [] }))
      ]);

      const timesheets = Array.isArray(timesheetsData) ? timesheetsData : timesheetsData.timesheets || [];
      const jobs = Array.isArray(jobsData) ? jobsData : jobsData.jobs || [];

      // Calculate hours and earnings
      const now = new Date();
      const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      const weekStart = new Date(today);
      weekStart.setDate(today.getDate() - today.getDay());
      const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

      const workerTimesheets = timesheets.filter((ts: any) => 
        ts.userID === currentUser.id
      ) || [];

      let hoursToday = 0, hoursWeek = 0, hoursMonth = 0;
      let earningsWeek = 0, earningsMonth = 0;
      let currentlyClocked = false;
      let currentJob = null;

      workerTimesheets.forEach((ts: any) => {
        const clockIn = new Date(ts.clockInTime);
        const hours = ts.hours || 0;
        const earnings = hours * (currentUser.hourlyRate || 0);

        if (ts.status === 'working') {
          currentlyClocked = true;
          currentJob = jobs.find((j: any) => j.id === ts.jobID);
        }

        if (clockIn >= today) {
          hoursToday += hours;
        }
        if (clockIn >= weekStart) {
          hoursWeek += hours;
          earningsWeek += earnings;
        }
        if (clockIn >= monthStart) {
          hoursMonth += hours;
          earningsMonth += earnings;
        }
      });

      // Get active jobs (jobs worker is assigned to)
      const activeJobs = jobs.filter((job: any) => job.status === 'active');
      setRecentJobs(activeJobs.slice(0, 5));

      setStats({
        hoursToday,
        hoursWeek,
        hoursMonth,
        earningsWeek,
        earningsMonth,
        activeJobs: activeJobs.length,
        currentlyClocked,
        currentJob
      });

      setLoading(false);
    } catch (error) {
      console.error('Failed to load dashboard:', error);
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <DashboardLayout>
        <div className="flex items-center justify-center min-h-screen">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
            Welcome back, {user?.name}!
          </h1>
          <p className="text-gray-600 dark:text-gray-400 mt-1">
            {new Date().toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}
          </p>
        </div>

        {/* Currently Clocked In Alert */}
        {stats.currentlyClocked && stats.currentJob && (
          <div className="mb-6 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4">
            <div className="flex items-start">
              <Clock className="h-5 w-5 text-blue-600 dark:text-blue-400 mt-0.5 mr-3" />
              <div className="flex-1">
                <h3 className="text-sm font-medium text-blue-900 dark:text-blue-100">
                  Currently clocked in
                </h3>
                <p className="text-sm text-blue-700 dark:text-blue-300 mt-1">
                  {stats.currentJob.jobName} - {stats.currentJob.clientName}
                </p>
              </div>
              <button
                onClick={() => router.push('/timesheets/clock')}
                className="ml-3 text-sm font-medium text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300"
              >
                View
              </button>
            </div>
          </div>
        )}

        {/* Quick Actions */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
          <button
            onClick={() => router.push('/timesheets/clock')}
            className="flex items-center p-4 bg-white dark:bg-gray-800 rounded-lg shadow hover:shadow-md transition-shadow"
          >
            <div className="flex-shrink-0 bg-blue-100 dark:bg-blue-900/30 rounded-lg p-3">
              <Clock className="h-6 w-6 text-blue-600 dark:text-blue-400" />
            </div>
            <div className="ml-4 text-left">
              <p className="text-sm font-medium text-gray-900 dark:text-white">Clock In/Out</p>
              <p className="text-xs text-gray-500 dark:text-gray-400">Track your time</p>
            </div>
          </button>

          <button
            onClick={() => router.push('/workers/hours')}
            className="flex items-center p-4 bg-white dark:bg-gray-800 rounded-lg shadow hover:shadow-md transition-shadow"
          >
            <div className="flex-shrink-0 bg-green-100 dark:bg-green-900/30 rounded-lg p-3">
              <Calendar className="h-6 w-6 text-green-600 dark:text-green-400" />
            </div>
            <div className="ml-4 text-left">
              <p className="text-sm font-medium text-gray-900 dark:text-white">My Hours</p>
              <p className="text-xs text-gray-500 dark:text-gray-400">View timesheets</p>
            </div>
          </button>

          <button
            onClick={() => router.push('/receipts')}
            className="flex items-center p-4 bg-white dark:bg-gray-800 rounded-lg shadow hover:shadow-md transition-shadow"
          >
            <div className="flex-shrink-0 bg-purple-100 dark:bg-purple-900/30 rounded-lg p-3">
              <DollarSign className="h-6 w-6 text-purple-600 dark:text-purple-400" />
            </div>
            <div className="ml-4 text-left">
              <p className="text-sm font-medium text-gray-900 dark:text-white">Receipts</p>
              <p className="text-xs text-gray-500 dark:text-gray-400">Submit expenses</p>
            </div>
          </button>

          <button
            onClick={() => router.push('/settings')}
            className="flex items-center p-4 bg-white dark:bg-gray-800 rounded-lg shadow hover:shadow-md transition-shadow"
          >
            <div className="flex-shrink-0 bg-gray-100 dark:bg-gray-700 rounded-lg p-3">
              <TrendingUp className="h-6 w-6 text-gray-600 dark:text-gray-400" />
            </div>
            <div className="ml-4 text-left">
              <p className="text-sm font-medium text-gray-900 dark:text-white">Profile</p>
              <p className="text-xs text-gray-500 dark:text-gray-400">Settings & more</p>
            </div>
          </button>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
          {/* Hours Today */}
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">Hours Today</h3>
              <Clock className="h-5 w-5 text-gray-400" />
            </div>
            <p className="text-3xl font-bold text-gray-900 dark:text-white">
              {stats.hoursToday.toFixed(1)}
            </p>
            <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">hours worked</p>
          </div>

          {/* Hours This Week */}
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">This Week</h3>
              <Calendar className="h-5 w-5 text-gray-400" />
            </div>
            <p className="text-3xl font-bold text-gray-900 dark:text-white">
              {stats.hoursWeek.toFixed(1)}
            </p>
            <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
              ${stats.earningsWeek.toFixed(2)} earned
            </p>
          </div>

          {/* Hours This Month */}
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">This Month</h3>
              <TrendingUp className="h-5 w-5 text-gray-400" />
            </div>
            <p className="text-3xl font-bold text-gray-900 dark:text-white">
              {stats.hoursMonth.toFixed(1)}
            </p>
            <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
              ${stats.earningsMonth.toFixed(2)} earned
            </p>
          </div>
        </div>

        {/* My Jobs */}
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow">
          <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
              My Active Jobs
            </h2>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
              {stats.activeJobs} {stats.activeJobs === 1 ? 'job' : 'jobs'} assigned to you
            </p>
          </div>

          {recentJobs.length > 0 ? (
            <ul className="divide-y divide-gray-200 dark:divide-gray-700">
              {recentJobs.map((job: any) => (
                <li key={job.id} className="px-6 py-4 hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors">
                  <div className="flex items-center justify-between">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center">
                        <Briefcase className="h-5 w-5 text-gray-400 mr-3 flex-shrink-0" />
                        <div>
                          <h3 className="text-sm font-medium text-gray-900 dark:text-white truncate">
                            {job.jobName}
                          </h3>
                          <p className="text-sm text-gray-500 dark:text-gray-400">
                            {job.clientName}
                          </p>
                          {job.address && (
                            <div className="flex items-center mt-1 text-xs text-gray-500 dark:text-gray-400">
                              <MapPin className="h-3 w-3 mr-1" />
                              {job.address}
                            </div>
                          )}
                        </div>
                      </div>
                    </div>
                    <div className="ml-4 flex-shrink-0">
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400">
                        Active
                      </span>
                    </div>
                  </div>
                </li>
              ))}
            </ul>
          ) : (
            <div className="px-6 py-12 text-center">
              <Briefcase className="mx-auto h-12 w-12 text-gray-400" />
              <h3 className="mt-2 text-sm font-medium text-gray-900 dark:text-white">No active jobs</h3>
              <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
                You haven't been assigned to any jobs yet.
              </p>
            </div>
          )}
        </div>
      </div>
    </DashboardLayout>
  );
}
