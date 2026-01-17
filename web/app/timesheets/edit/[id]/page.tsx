'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import DashboardLayout from '@/components/dashboard-layout';
import AuthService from '@/lib/auth';
import APIService from '@/lib/api';
import toast from 'react-hot-toast';
import { ArrowLeft, Loader2, Save } from 'lucide-react';

export default function EditTimesheet({ params }: { params: { id: string } }) {
    const router = useRouter();
    const [isLoading, setIsLoading] = useState(false);
    const [isFetching, setIsFetching] = useState(true);
    const [jobs, setJobs] = useState<any[]>([]);
    const [workers, setWorkers] = useState<any[]>([]);
    const [formData, setFormData] = useState({
        jobID: '',
        workerID: '',
        date: '',
        clockIn: '',
        clockOut: '',
        hours: '',
        notes: '',
        status: ''
    });

    useEffect(() => {
        loadData();
    }, []);

    const loadData = async () => {
        try {
            setIsFetching(true);
            const [jobsData, workersData, timesheet] = await Promise.all([
                APIService.fetchJobs(),
                APIService.fetchWorkers(),
                APIService.fetchTimesheet(params.id)
            ]);

            setJobs(jobsData);
            setWorkers(workersData);

            // Populate form
            const clockInDate = timesheet.clockIn ? new Date(timesheet.clockIn) : null;
            const clockOutDate = timesheet.clockOut ? new Date(timesheet.clockOut) : null;

            setFormData({
                jobID: timesheet.jobID,
                workerID: timesheet.workerID,
                date: clockInDate ? clockInDate.toISOString().split('T')[0] : new Date().toISOString().split('T')[0],
                clockIn: clockInDate ? formatTime(clockInDate) : '',
                clockOut: clockOutDate ? formatTime(clockOutDate) : '',
                hours: timesheet.hours ? timesheet.hours.toString() : '',
                notes: timesheet.notes || '',
                status: timesheet.status
            });

        } catch (error) {
            console.error('Failed to load data:', error);
            toast.error('Failed to load timesheet details');
            router.push('/timesheets');
        } finally {
            setIsFetching(false);
        }
    };

    const formatTime = (date: Date) => {
        return date.toTimeString().slice(0, 5);
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setIsLoading(true);

        try {
            const timesheetData: any = {
                hours: parseFloat(formData.hours) || undefined,
                notes: formData.notes || undefined,
                // Allow updating status if needed, though usually handled via Approve/Deny
                status: formData.status
            };

            // Only include clock times if they changed and are valid
            if (formData.clockIn) {
                timesheetData.clockIn = `${formData.date}T${formData.clockIn}:00`;
            }
            if (formData.clockOut) {
                timesheetData.clockOut = `${formData.date}T${formData.clockOut}:00`;
            }

            await APIService.updateTimesheet(params.id, timesheetData);
            toast.success('Timesheet updated successfully!');
            router.push('/timesheets');
        } catch (error: any) {
            toast.error(error.response?.data?.error || error.message || 'Failed to update timesheet.');
        } finally {
            setIsLoading(false);
        }
    };

    const calculateHours = () => {
        if (formData.clockIn && formData.clockOut) {
            const start = new Date(`2000-01-01T${formData.clockIn}`);
            const end = new Date(`2000-01-01T${formData.clockOut}`);
            let hours = (end.getTime() - start.getTime()) / (1000 * 60 * 60);
            if (hours < 0) hours += 24; // Handle overnight
            if (hours > 0) {
                setFormData({ ...formData, hours: hours.toFixed(2) });
            }
        }
    };

    if (isFetching) {
        return (
            <DashboardLayout>
                <div className="min-h-[60vh] flex items-center justify-center">
                    <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
                </div>
            </DashboardLayout>
        );
    }

    return (
        <DashboardLayout>
            <div className="max-w-3xl mx-auto space-y-6">
                <div className="flex items-center gap-4">
                    <button
                        onClick={() => router.back()}
                        className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition"
                        aria-label="Go back"
                        title="Go back"
                    >
                        <ArrowLeft className="w-6 h-6 text-gray-900 dark:text-white" />
                    </button>
                    <div>
                        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Edit Timesheet</h1>
                        <p className="text-gray-600 dark:text-gray-400 mt-1">Update details for this entry</p>
                    </div>
                </div>

                <form onSubmit={handleSubmit} className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm space-y-6">
                    {/* Worker Info (Read Only) */}
                    <div>
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                            Worker
                        </label>
                        <div className="w-full px-4 py-3 border border-gray-200 dark:border-gray-700 rounded-lg bg-gray-50 dark:bg-gray-900 text-gray-500 dark:text-gray-400">
                            {workers.find(w => w.id === formData.workerID)?.name || 'Unknown Worker'}
                        </div>
                    </div>

                    {/* Job Info (Read Only) */}
                    <div>
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                            Job
                        </label>
                        <div className="w-full px-4 py-3 border border-gray-200 dark:border-gray-700 rounded-lg bg-gray-50 dark:bg-gray-900 text-gray-500 dark:text-gray-400">
                            {jobs.find(j => j.id === formData.jobID)?.jobName || 'Unknown Job'}
                        </div>
                    </div>

                    {/* Date */}
                    <div>
                        <label htmlFor="timesheet-date" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                            Date
                        </label>
                        <input
                            id="timesheet-date"
                            type="date"
                            required
                            value={formData.date}
                            onChange={(e) => setFormData({ ...formData, date: e.target.value })}
                            className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-gray-900 dark:text-white bg-white dark:bg-gray-700"
                        />
                    </div>

                    {/* Time */}
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                        <div>
                            <label htmlFor="clock-in" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                                Clock In
                            </label>
                            <input
                                id="clock-in"
                                type="time"
                                value={formData.clockIn}
                                onChange={(e) => setFormData({ ...formData, clockIn: e.target.value })}
                                onBlur={calculateHours}
                                className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-gray-900 dark:text-white bg-white dark:bg-gray-700"
                            />
                        </div>
                        <div>
                            <label htmlFor="clock-out" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                                Clock Out
                            </label>
                            <input
                                id="clock-out"
                                type="time"
                                value={formData.clockOut}
                                onChange={(e) => setFormData({ ...formData, clockOut: e.target.value })}
                                onBlur={calculateHours}
                                className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-gray-900 dark:text-white bg-white dark:bg-gray-700"
                            />
                        </div>
                        <div>
                            <label htmlFor="total-hours" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                                Total Hours
                            </label>
                            <input
                                id="total-hours"
                                type="number"
                                step="0.01"
                                required
                                value={formData.hours}
                                onChange={(e) => setFormData({ ...formData, hours: e.target.value })}
                                className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-gray-900 dark:text-white bg-white dark:bg-gray-700"
                            />
                        </div>
                    </div>

                    {/* Notes */}
                    <div>
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                            Notes
                        </label>
                        <textarea
                            rows={3}
                            value={formData.notes}
                            onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                            className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-gray-900 dark:text-white bg-white dark:bg-gray-700"
                        />
                    </div>

                    {/* Status (Optional Override) */}
                    <div>
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                            Status for Payroll
                        </label>
                        <select
                            value={formData.status}
                            onChange={(e) => setFormData({ ...formData, status: e.target.value })}
                            className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-gray-900 dark:text-white bg-white dark:bg-gray-700"
                        >
                            <option value="working">Working</option>
                            <option value="completed">Completed (Pending Approval)</option>
                            <option value="approved">Approved</option>
                            <option value="rejected">Rejected</option>
                        </select>
                    </div>

                    {/* Submit Buttons */}
                    <div className="flex gap-4 pt-4">
                        <button
                            type="button"
                            onClick={() => router.back()}
                            className="flex-1 px-6 py-3 border-2 border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition"
                            disabled={isLoading}
                        >
                            Cancel
                        </button>
                        <button
                            type="submit"
                            disabled={isLoading}
                            className="flex-1 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                            {isLoading ? (
                                <>
                                    <Loader2 className="w-5 h-5 animate-spin" />
                                    Saving...
                                </>
                            ) : (
                                <>
                                    <Save className="w-5 h-5" />
                                    Save Changes
                                </>
                            )}
                        </button>
                    </div>
                </form>
            </div>
        </DashboardLayout>
    );
}
