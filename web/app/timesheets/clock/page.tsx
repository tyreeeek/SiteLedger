'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import DashboardLayout from '@/components/dashboard-layout';
import AuthService from '@/lib/auth';
import APIService from '@/lib/api';
import { Clock, MapPin, Briefcase, User, Calendar, Loader2, CheckCircle } from 'lucide-react';

export default function ClockInOut() {
  const router = useRouter();
  const queryClient = useQueryClient();
  
  const [currentUser, setCurrentUser] = useState<any>(null);
  const [activeTimesheet, setActiveTimesheet] = useState<any>(null);
  const [jobs, setJobs] = useState<any[]>([]);
  const [selectedJob, setSelectedJob] = useState('');
  const [location, setLocation] = useState<{ lat: number; lng: number } | null>(null);
  const [elapsedTime, setElapsedTime] = useState('00:00:00');
  const [isLoading, setIsLoading] = useState(true);
  const [todayStats, setTodayStats] = useState({ sessions: 0, hours: 0, earned: 0 });

  useEffect(() => {
    const user = AuthService.getCurrentUser();
    if (!user) {
      router.push('/auth/signin');
      return;
    }
    setCurrentUser(user);
    loadData();
  }, []);

  // Get current location
  useEffect(() => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setLocation({
            lat: position.coords.latitude,
            lng: position.coords.longitude
          });
        },
        () => {
          // Silently fail - location is optional
        }
      );
    }
  }, []);

  // Update elapsed time every second
  useEffect(() => {
    if (!activeTimesheet) return;

    const timer = setInterval(() => {
      const clockIn = new Date(activeTimesheet.clockIn);
      const now = new Date();
      const diff = now.getTime() - clockIn.getTime();
      
      const hours = Math.floor(diff / (1000 * 60 * 60));
      const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
      const seconds = Math.floor((diff % (1000 * 60)) / 1000);
      
      setElapsedTime(
        `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
      );
    }, 1000);

    return () => clearInterval(timer);
  }, [activeTimesheet]);

  const loadData = async () => {
    setIsLoading(true);
    try {
      const [timesheetsData, jobsData] = await Promise.all([
        APIService.fetchTimesheets(),
        APIService.fetchJobs()
      ]);
      
      // Find active timesheet (status='working' means clocked in)
      const currentUserId = AuthService.getCurrentUser()?.id;
      const active = timesheetsData.find((ts: any) => 
        ts.workerID === currentUserId && ts.status === 'working'
      );
      console.log('Active timesheet found:', active);
      setActiveTimesheet(active);
      
      // Calculate today's stats
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const todayTimesheets = timesheetsData.filter((ts: any) => {
        const clockInDate = new Date(ts.clockIn);
        clockInDate.setHours(0, 0, 0, 0);
        return ts.workerID === currentUserId && clockInDate.getTime() === today.getTime();
      });
      
      const sessions = todayTimesheets.length;
      const hours = todayTimesheets.reduce((sum: number, ts: any) => {
        // Use effectiveHours (calculated field) or hours field
        return sum + (ts.effectiveHours || ts.hours || 0);
      }, 0);
      const hourlyRate = AuthService.getCurrentUser()?.hourlyRate || 0;
      const earned = hours * hourlyRate;
      
      setTodayStats({ sessions, hours: parseFloat(hours.toFixed(1)), earned: parseFloat(earned.toFixed(2)) });
      
      // Filter active jobs
      const activeJobs = jobsData.filter((j: any) => j.status === 'active');
      setJobs(activeJobs);
      
      if (activeJobs.length > 0 && !selectedJob) {
        setSelectedJob(activeJobs[0].id);
      }
    } catch (error) {
      // Silently fail - UI will show loading state
    } finally {
      setIsLoading(false);
    }
  };

  const clockInMutation = useMutation({
    mutationFn: async () => {
      if (!selectedJob) {
        throw new Error('Please select a job');
      }
      
      // Use the clock-in endpoint with correct parameters
      const clockInData: any = {
        jobID: String(selectedJob), // Ensure it's a string
      };
      
      // Only include location data if available
      if (location?.lat !== undefined && location?.lng !== undefined) {
        clockInData.latitude = location.lat;
        clockInData.longitude = location.lng;
      }
      
      console.log('Clock in attempt:', clockInData);
      
      const response = await APIService.clockIn(clockInData);
      console.log('Clock in response:', response);
      return response;
    },
    onSuccess: (data) => {
      console.log('Clock in successful:', data);
      queryClient.invalidateQueries({ queryKey: ['timesheets'] });
      loadData();
    },
    onError: (error: any) => {
      console.error('Clock in error:', error);
      console.error('Error response:', error.response?.data);
      const errorMessage = error.response?.data?.error || 
                          error.response?.data?.errors?.[0]?.msg ||
                          error.message || 
                          'Failed to clock in. Please try again.';
      alert(errorMessage);
    }
  });

  const clockOutMutation = useMutation({
    mutationFn: async () => {
      if (!activeTimesheet) throw new Error('No active timesheet');
      
      console.log('Clock out attempt:', activeTimesheet.id);
      const response = await APIService.clockOut(activeTimesheet.id);
      console.log('Clock out response:', response);
      return response;
    },
    onSuccess: (data) => {
      console.log('Clock out successful:', data);
      queryClient.invalidateQueries({ queryKey: ['timesheets'] });
      setActiveTimesheet(null);
      setElapsedTime('00:00:00');
      // Reload data to show updated hours
      loadData();
    },
    onError: (error: any) => {
      console.error('Clock out error:', error);
      console.error('Error response:', error.response?.data);
      const errorMessage = error.response?.data?.error || 
                          error.message || 
                          'Failed to clock out. Please try again.';
      alert(errorMessage);
    }
  });

  const handleClockIn = () => {
    clockInMutation.mutate();
  };

  const handleClockOut = () => {
    clockOutMutation.mutate();
  };

  const getJobName = (jobID: string) => {
    return jobs.find(j => j.id === jobID)?.jobName || 'Unknown Job';
  };

  if (isLoading) {
    return (
      <DashboardLayout>
        <div className="min-h-screen flex items-center justify-center">
          <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <div className="max-w-2xl mx-auto space-y-6">
        {/* Header */}
        <div className="text-center">
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Time Clock</h1>
          <p className="text-gray-600 mt-2">Track your work hours</p>
        </div>

        {/* Current Time Display */}
        <div className="bg-gradient-to-br from-blue-500 to-blue-600 rounded-2xl p-8 shadow-xl text-white">
          <div className="text-center space-y-4">
            <Clock className="w-16 h-16 mx-auto opacity-90" />
            
            {activeTimesheet ? (
              <>
                <div>
                  <p className="text-sm opacity-90 mb-2">Active Session</p>
                  <div className="text-6xl font-bold tracking-tight mb-2">
                    {elapsedTime}
                  </div>
                  <p className="text-sm opacity-90">
                    Started at {new Date(activeTimesheet.clockIn).toLocaleTimeString('en-US', {
                      hour: 'numeric',
                      minute: '2-digit'
                    })}
                  </p>
                </div>
                
                <div className="flex items-center justify-center gap-2 bg-white/20 backdrop-blur-sm rounded-lg px-4 py-2 max-w-xs mx-auto">
                  <Briefcase className="w-4 h-4" />
                  <span className="font-medium">{getJobName(activeTimesheet.jobID)}</span>
                </div>
                
                <button
                  onClick={handleClockOut}
                  disabled={clockOutMutation.isPending}
                  className="mt-6 w-full max-w-xs mx-auto px-8 py-4 bg-white text-blue-600 font-semibold rounded-xl hover:bg-blue-50 transition shadow-lg disabled:opacity-50 flex items-center justify-center gap-2"
                >
                  {clockOutMutation.isPending ? (
                    <>
                      <Loader2 className="w-5 h-5 animate-spin" />
                      Clocking Out...
                    </>
                  ) : (
                    <>
                      <CheckCircle className="w-5 h-5" />
                      Clock Out
                    </>
                  )}
                </button>
              </>
            ) : (
              <>
                <div className="text-6xl font-bold tracking-tight">
                  {new Date().toLocaleTimeString('en-US', {
                    hour: 'numeric',
                    minute: '2-digit',
                    second: '2-digit'
                  })}
                </div>
                <p className="text-lg opacity-90">
                  {new Date().toLocaleDateString('en-US', {
                    weekday: 'long',
                    month: 'long',
                    day: 'numeric'
                  })}
                </p>
              </>
            )}
          </div>
        </div>

        {/* Clock In Form */}
        {!activeTimesheet && (
          <div className="bg-white rounded-xl border border-gray-200 p-6 shadow-sm space-y-4">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Start Work Session</h3>
            
            {/* Job Selection */}
            <div className="space-y-2">
              <label htmlFor="clock-job-select" className="flex items-center gap-2 text-sm font-medium text-gray-700">
                <Briefcase className="w-4 h-4" />
                Select Job
              </label>
              <select
                id="clock-job-select"
                value={selectedJob}
                onChange={(e) => setSelectedJob(e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                aria-label="Select job for time tracking"
              >
                <option value="">Choose a job...</option>
                {jobs.map(job => (
                  <option key={job.id} value={job.id}>
                    {job.jobName} - {job.clientName}
                  </option>
                ))}
              </select>
            </div>

            {/* Location Status */}
            {location && (
              <div className="flex items-center gap-2 text-sm text-gray-600 bg-green-50 border border-green-200 rounded-lg px-3 py-2">
                <MapPin className="w-4 h-4 text-green-600" />
                <span>Location tracking enabled</span>
              </div>
            )}

            {/* Clock In Button */}
            <button
              onClick={handleClockIn}
              disabled={!selectedJob || clockInMutation.isPending}
              className="w-full px-6 py-4 bg-blue-600 text-white font-semibold rounded-xl hover:bg-blue-700 transition disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              {clockInMutation.isPending ? (
                <>
                  <Loader2 className="w-5 h-5 animate-spin" />
                  Clocking In...
                </>
              ) : (
                <>
                  <Clock className="w-5 h-5" />
                  Clock In
                </>
              )}
            </button>

            {clockInMutation.isError && (
              <p className="text-sm text-red-600">
                Failed to clock in. Please try again.
              </p>
            )}
          </div>
        )}

        {/* Quick Stats */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">Today's Summary</h3>
          <div className="grid grid-cols-3 gap-4 text-center">
            <div>
              <p className="text-2xl font-bold text-gray-900 dark:text-white">{todayStats.sessions}</p>
              <p className="text-sm text-gray-600 dark:text-gray-400">Sessions</p>
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900 dark:text-white">{todayStats.hours}</p>
              <p className="text-sm text-gray-600 dark:text-gray-400">Hours</p>
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900 dark:text-white">${todayStats.earned}</p>
              <p className="text-sm text-gray-600 dark:text-gray-400">Earned</p>
            </div>
          </div>
        </div>

        {/* User Info */}
        <div className="bg-gray-50 rounded-xl border border-gray-200 p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-blue-100 rounded-lg">
              <User className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <p className="text-sm text-gray-600">Signed in as</p>
              <p className="font-semibold text-gray-900 dark:text-white">{currentUser?.name}</p>
            </div>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
}
