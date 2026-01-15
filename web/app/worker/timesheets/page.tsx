'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import APIService from '@/lib/api';
import AuthService from '@/lib/auth';
import DashboardLayout from '@/components/dashboard-layout';
import { Clock, Loader2, Search, Calendar, MapPin, DollarSign, CheckCircle, AlertCircle, XCircle } from 'lucide-react';

export default function WorkerTimesheets() {
  const router = useRouter();
  const [isAuthChecked, setIsAuthChecked] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [user, setUser] = useState<any>(null);
  const [filterStatus, setFilterStatus] = useState<string>('all');

  useEffect(() => {
    if (!AuthService.isAuthenticated()) {
      router.push('/auth/signin');
    } else {
      const currentUser = AuthService.getCurrentUser();
      if (!currentUser || currentUser.role !== 'worker') {
        router.push('/dashboard');
        return;
      }
      setUser(currentUser);
      setIsAuthChecked(true);
    }
  }, [router]);

  const { data: timesheetsData = [], isLoading, refetch } = useQuery({
    queryKey: ['worker-timesheets', user?.id],
    queryFn: () => APIService.fetchTimesheets(),
    enabled: isAuthChecked && !!user,
  });

  if (!isAuthChecked) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
      </div>
    );
  }

  // Filter to show only current worker's timesheets
  const myTimesheets = Array.isArray(timesheetsData) 
    ? timesheetsData.filter((ts: any) => ts.userID === user?.id || ts.workerID === user?.id)
    : [];

  const filteredTimesheets = myTimesheets.filter((ts: any) => {
    // Filter by status
    if (filterStatus !== 'all' && ts.status !== filterStatus) {
      return false;
    }

    // Filter by search query
    if (!searchQuery) return true;
    return ts.jobName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
           ts.notes?.toLowerCase().includes(searchQuery.toLowerCase());
  });

  // Calculate stats
  const stats = {
    totalHours: myTimesheets.reduce((sum: number, ts: any) => sum + (ts.hours || 0), 0),
    totalEarnings: myTimesheets.reduce((sum: number, ts: any) => {
      const hours = ts.hours || 0;
      const rate = user?.hourlyRate || ts.hourlyRate || 0;
      return sum + (hours * rate);
    }, 0),
    thisWeek: myTimesheets.filter((ts: any) => {
      const weekAgo = new Date();
      weekAgo.setDate(weekAgo.getDate() - 7);
      return new Date(ts.clockIn) > weekAgo;
    }).reduce((sum: number, ts: any) => sum + (ts.hours || 0), 0),
    thisMonth: myTimesheets.filter((ts: any) => {
      const monthAgo = new Date();
      monthAgo.setMonth(monthAgo.getMonth() - 1);
      return new Date(ts.clockIn) > monthAgo;
    }).reduce((sum: number, ts: any) => sum + (ts.hours || 0), 0),
  };

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('en-US', { 
      style: 'currency', 
      currency: 'USD',
      minimumFractionDigits: 2,
    }).format(value);
  };

  const formatDate = (dateString: string) => {
    if (!dateString) return 'N/A';
    
    try {
      const date = new Date(dateString);
      
      // Check if date is valid
      if (isNaN(date.getTime())) {
        return 'Invalid Date';
      }
      
      return date.toLocaleDateString('en-US', { 
        month: 'short', 
        day: 'numeric', 
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      });
    } catch (error) {
      return 'Invalid Date';
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'working':
        return (
          <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
            <Clock className="w-4 h-4 mr-1" />
            Working
          </span>
        );
      case 'completed':
        return (
          <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200">
            <CheckCircle className="w-4 h-4 mr-1" />
            Completed
          </span>
        );
      case 'flagged':
        return (
          <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200">
            <AlertCircle className="w-4 h-4 mr-1" />
            Flagged
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200">
            {status}
          </span>
        );
    }
  };

  if (isLoading) {
    return (
      <DashboardLayout>
        <div className="flex items-center justify-center min-h-[60vh]">
          <div className="text-center">
            <Loader2 className="w-12 h-12 text-blue-600 animate-spin mx-auto mb-4" />
            <p className="text-gray-600 dark:text-gray-400">Loading your timesheets...</p>
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
            <h1 className="text-3xl lg:text-4xl font-bold text-gray-900 dark:text-white">My Timesheets</h1>
            <p className="text-gray-600 dark:text-gray-400 mt-2">View your work hours and earnings</p>
          </div>
          <button 
            onClick={() => router.push('/timesheets/clock')}
            className="flex items-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition shadow-lg"
          >
            <Clock className="w-5 h-5" />
            Clock In/Out
          </button>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl p-6 text-white shadow-lg">
            <div className="flex items-center justify-between mb-2">
              <p className="text-blue-100">Total Hours</p>
              <Clock className="w-8 h-8 text-blue-200" />
            </div>
            <p className="text-4xl font-bold">{stats.totalHours.toFixed(1)}</p>
            <p className="text-blue-100 text-sm mt-2">All time</p>
          </div>

          <div className="bg-gradient-to-br from-green-500 to-green-600 rounded-xl p-6 text-white shadow-lg">
            <div className="flex items-center justify-between mb-2">
              <p className="text-green-100">Total Earnings</p>
              <DollarSign className="w-8 h-8 text-green-200" />
            </div>
            <p className="text-4xl font-bold">{formatCurrency(stats.totalEarnings)}</p>
            <p className="text-green-100 text-sm mt-2">All time</p>
          </div>

          <div className="bg-gradient-to-br from-purple-500 to-purple-600 rounded-xl p-6 text-white shadow-lg">
            <div className="flex items-center justify-between mb-2">
              <p className="text-purple-100">This Week</p>
              <Calendar className="w-8 h-8 text-purple-200" />
            </div>
            <p className="text-4xl font-bold">{stats.thisWeek.toFixed(1)}</p>
            <p className="text-purple-100 text-sm mt-2">hours</p>
          </div>

          <div className="bg-gradient-to-br from-orange-500 to-orange-600 rounded-xl p-6 text-white shadow-lg">
            <div className="flex items-center justify-between mb-2">
              <p className="text-orange-100">This Month</p>
              <Calendar className="w-8 h-8 text-orange-200" />
            </div>
            <p className="text-4xl font-bold">{stats.thisMonth.toFixed(1)}</p>
            <p className="text-orange-100 text-sm mt-2">hours</p>
          </div>
        </div>

        {/* Filters */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-4 shadow-sm">
          <div className="flex flex-col lg:flex-row gap-4">
            {/* Search */}
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 dark:text-gray-500 w-5 h-5" />
              <input
                type="text"
                placeholder="Search by job name or notes..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none bg-white dark:bg-gray-700 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400"
              />
            </div>

            {/* Status Filter */}
            <div className="flex gap-2">
              <button
                onClick={() => setFilterStatus('all')}
                className={`px-4 py-2 rounded-lg font-medium transition ${
                  filterStatus === 'all'
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
                }`}
              >
                All
              </button>
              <button
                onClick={() => setFilterStatus('working')}
                className={`px-4 py-2 rounded-lg font-medium transition ${
                  filterStatus === 'working'
                    ? 'bg-green-600 text-white'
                    : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
                }`}
              >
                Working
              </button>
              <button
                onClick={() => setFilterStatus('completed')}
                className={`px-4 py-2 rounded-lg font-medium transition ${
                  filterStatus === 'completed'
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
                }`}
              >
                Completed
              </button>
            </div>
          </div>
        </div>

        {/* Timesheets List */}
        {filteredTimesheets.length === 0 ? (
          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-12 text-center">
            <Clock className="w-16 h-16 text-gray-400 dark:text-gray-600 mx-auto mb-4" />
            <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">
              {searchQuery || filterStatus !== 'all' ? 'No timesheets found' : 'No timesheets yet'}
            </h3>
            <p className="text-gray-600 dark:text-gray-400 mb-6">
              {searchQuery || filterStatus !== 'all' 
                ? 'Try adjusting your filters' 
                : 'Clock in to start tracking your work hours'}
            </p>
            {!searchQuery && filterStatus === 'all' && (
              <button 
                onClick={() => router.push('/timesheets/clock')}
                className="inline-flex items-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
              >
                <Clock className="w-5 h-5" />
                Clock In Now
              </button>
            )}
          </div>
        ) : (
          <div className="space-y-4">
            {filteredTimesheets.map((timesheet: any) => {
              const earnings = (timesheet.hours || 0) * (user?.hourlyRate || timesheet.hourlyRate || 0);
              
              return (
                <div 
                  key={timesheet.id} 
                  className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm"
                >
                  <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
                    <div className="flex-1">
                      <div className="flex items-start justify-between mb-3">
                        <div>
                          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-1">
                            {timesheet.jobName || 'Unknown Job'}
                          </h3>
                          {timesheet.jobAddress && (
                            <div className="flex items-center text-sm text-gray-600 dark:text-gray-400">
                              <MapPin className="w-4 h-4 mr-1" />
                              {timesheet.jobAddress}
                            </div>
                          )}
                        </div>
                        {getStatusBadge(timesheet.status)}
                      </div>

                      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 text-sm">
                        <div>
                          <p className="text-gray-600 dark:text-gray-400">Clock In</p>
                          <p className="text-gray-900 dark:text-white font-medium">
                            {formatDate(timesheet.clockIn)}
                          </p>
                        </div>
                        {timesheet.clockOut && (
                          <div>
                            <p className="text-gray-600 dark:text-gray-400">Clock Out</p>
                            <p className="text-gray-900 dark:text-white font-medium">
                              {formatDate(timesheet.clockOut)}
                            </p>
                          </div>
                        )}
                        <div>
                          <p className="text-gray-600 dark:text-gray-400">Hours</p>
                          <p className="text-blue-600 dark:text-blue-400 font-bold text-lg">
                            {timesheet.hours?.toFixed(2) || '0.00'}h
                          </p>
                        </div>
                      </div>

                      {timesheet.notes && (
                        <div className="mt-3 pt-3 border-t border-gray-200 dark:border-gray-700">
                          <p className="text-sm text-gray-600 dark:text-gray-400">
                            <span className="font-medium">Notes:</span> {timesheet.notes}
                          </p>
                        </div>
                      )}
                    </div>

                    <div className="lg:text-right">
                      <p className="text-sm text-gray-600 dark:text-gray-400 mb-1">Earnings</p>
                      <p className="text-2xl font-bold text-green-600 dark:text-green-400">
                        {formatCurrency(earnings)}
                      </p>
                      <p className="text-xs text-gray-500 dark:text-gray-500 mt-1">
                        @ {formatCurrency(user?.hourlyRate || timesheet.hourlyRate || 0)}/hr
                      </p>
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
