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
      
      // Find active timesheet (has clockIn but no clockOut)
      const active = timesheetsData.find((ts: any) => 
        ts.userID === AuthService.getCurrentUser()?.id && ts.clockIn && !ts.clockOut
      );
      setActiveTimesheet(active);
      
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
      if (!selectedJob) throw new Error('Please select a job');
      
      const timesheet = {
        userID: currentUser.id,
        jobID: selectedJob,
        clockIn: new Date().toISOString(),
        clockOut: null,
        hours: null,
        latitude: location?.lat || null,
        longitude: location?.lng || null,
        status: 'pending',
        createdAt: new Date().toISOString()
      };
      
      return APIService.createTimesheet(timesheet);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['timesheets'] });
      loadData();
    },
  });

  const clockOutMutation = useMutation({
    mutationFn: async () => {
      if (!activeTimesheet) throw new Error('No active timesheet');
      
      const clockIn = new Date(activeTimesheet.clockIn);
      const clockOut = new Date();
      const hours = (clockOut.getTime() - clockIn.getTime()) / (1000 * 60 * 60);
      
      return APIService.updateTimesheet(activeTimesheet.id, {
        ...activeTimesheet,
        clockOut: clockOut.toISOString(),
        hours: parseFloat(hours.toFixed(2))
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['timesheets'] });
      setActiveTimesheet(null);
      setElapsedTime('00:00:00');
    },
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
          <h1 className="text-3xl font-bold text-gray-900">Time Clock</h1>
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
            <h3 className="text-lg font-semibold text-gray-900">Start Work Session</h3>
            
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
        <div className="bg-white rounded-xl border border-gray-200 p-6 shadow-sm">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Today's Summary</h3>
          <div className="grid grid-cols-3 gap-4 text-center">
            <div>
              <p className="text-2xl font-bold text-gray-900">0</p>
              <p className="text-sm text-gray-600">Sessions</p>
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">0.0</p>
              <p className="text-sm text-gray-600">Hours</p>
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">$0</p>
              <p className="text-sm text-gray-600">Earned</p>
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
              <p className="font-semibold text-gray-900">{currentUser?.name}</p>
            </div>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
}
