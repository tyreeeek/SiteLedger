'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import DashboardLayout from '@/components/dashboard-layout';
import AuthService from '@/lib/auth';
import { ArrowLeft, Calendar as CalendarIcon, Clock, Users, Briefcase } from 'lucide-react';

export default function Calendar() {
  const router = useRouter();

  useEffect(() => {
    if (!AuthService.isAuthenticated()) {
      router.push('/auth/signin');
    }
  }, []);

  return (
    <DashboardLayout>
      <div className="max-w-5xl mx-auto space-y-6">
        <div className="flex items-center gap-4">
          <button
            onClick={() => router.back()}
            className="p-2 hover:bg-gray-100 rounded-lg transition"
            aria-label="Go back"
          >
            <ArrowLeft className="w-6 h-6 text-gray-900" />
          </button>
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Calendar</h1>
            <p className="text-gray-600 mt-1">Schedule jobs and track deadlines</p>
          </div>
        </div>

        {/* Coming Soon Hero */}
        <div className="bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl p-12 text-white text-center shadow-lg">
          <div className="text-7xl mb-6">📅</div>
          <h2 className="text-4xl font-bold mb-4">Calendar View Coming Soon!</h2>
          <p className="text-xl text-blue-50 max-w-2xl mx-auto mb-8">
            We're building a powerful calendar to help you visualize job schedules, worker assignments, and project deadlines all in one place.
          </p>
          <button
            onClick={() => router.push('/jobs')}
            className="px-8 py-4 bg-white text-blue-600 rounded-lg hover:bg-gray-100 transition font-semibold text-lg shadow-lg"
          >
            View Jobs List
          </button>
        </div>

        {/* Upcoming Features */}
        <div className="bg-white rounded-xl border border-gray-200 p-8 shadow-sm">
          <h3 className="text-2xl font-bold text-gray-900 mb-6 text-center">What's Coming</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="flex items-start gap-4">
              <div className="p-3 bg-blue-100 rounded-lg flex-shrink-0">
                <CalendarIcon className="w-6 h-6 text-blue-600" />
              </div>
              <div>
                <h4 className="font-semibold text-gray-900 mb-2">Visual Job Timeline</h4>
                <p className="text-sm text-gray-600">
                  See all your jobs on a monthly, weekly, or daily calendar view with color-coded statuses
                </p>
              </div>
            </div>

            <div className="flex items-start gap-4">
              <div className="p-3 bg-green-100 rounded-lg flex-shrink-0">
                <Users className="w-6 h-6 text-green-600" />
              </div>
              <div>
                <h4 className="font-semibold text-gray-900 mb-2">Worker Scheduling</h4>
                <p className="text-sm text-gray-600">
                  Assign workers to jobs by drag-and-drop, track availability, and prevent double-booking
                </p>
              </div>
            </div>

            <div className="flex items-start gap-4">
              <div className="p-3 bg-purple-100 rounded-lg flex-shrink-0">
                <Clock className="w-6 h-6 text-purple-600" />
              </div>
              <div>
                <h4 className="font-semibold text-gray-900 mb-2">Deadline Tracking</h4>
                <p className="text-sm text-gray-600">
                  Set project milestones and get alerts when deadlines are approaching or overdue
                </p>
              </div>
            </div>

            <div className="flex items-start gap-4">
              <div className="p-3 bg-orange-100 rounded-lg flex-shrink-0">
                <Briefcase className="w-6 h-6 text-orange-600" />
              </div>
              <div>
                <h4 className="font-semibold text-gray-900 mb-2">Multi-Project View</h4>
                <p className="text-sm text-gray-600">
                  See all ongoing projects at once and identify scheduling conflicts before they happen
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Preview Mockup */}
        <div className="bg-white rounded-xl border border-gray-200 p-8 shadow-sm">
          <h3 className="text-xl font-bold text-gray-900 mb-4 text-center">Calendar Preview</h3>
          <div className="bg-gradient-to-br from-gray-50 to-gray-100 rounded-lg p-8 border-2 border-dashed border-gray-300">
            <div className="grid grid-cols-7 gap-2 mb-4">
              {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((day) => (
                <div key={day} className="text-center text-sm font-semibold text-gray-600 py-2">
                  {day}
                </div>
              ))}
            </div>
            <div className="grid grid-cols-7 gap-2">
              {Array.from({ length: 35 }).map((_, i) => (
                <div
                  key={i}
                  className="aspect-square bg-white rounded-lg border border-gray-200 p-2 hover:border-blue-300 transition"
                >
                  <div className="text-xs text-gray-400">{((i % 31) + 1)}</div>
                  {i % 7 === 2 && (
                    <div className="mt-1 text-[10px] bg-blue-100 text-blue-700 rounded px-1 py-0.5 truncate">
                      Job A
                    </div>
                  )}
                  {i % 7 === 4 && (
                    <div className="mt-1 text-[10px] bg-green-100 text-green-700 rounded px-1 py-0.5 truncate">
                      Job B
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Notify Me */}
        <div className="bg-gradient-to-br from-purple-50 to-blue-50 rounded-xl border border-gray-200 p-8 text-center">
          <h3 className="text-2xl font-bold text-gray-900 mb-3">Get Notified When Calendar Launches</h3>
          <p className="text-gray-600 mb-6">
            Want to be the first to know when the calendar feature is ready? Contact our support team to join the waitlist.
          </p>
          <button
            onClick={() => router.push('/support')}
            className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition font-medium"
          >
            Join Waitlist
          </button>
        </div>
      </div>
    </DashboardLayout>
  );
}
