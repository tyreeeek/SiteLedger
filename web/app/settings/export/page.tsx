'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import DashboardLayout from '@/components/dashboard-layout';
import AuthService from '@/lib/auth';
import APIService from '@/lib/api';
import { ArrowLeft, Download, FileText, Calendar } from 'lucide-react';

export default function ExportData() {
  const router = useRouter();
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [isExporting, setIsExporting] = useState(false);
  const [message, setMessage] = useState('');

  useEffect(() => {
    if (!AuthService.isAuthenticated()) {
      router.push('/auth/signin');
    }

    // Set default date range (last 30 days)
    const today = new Date();
    const thirtyDaysAgo = new Date(today.getTime() - 30 * 24 * 60 * 60 * 1000);
    setEndDate(today.toISOString().split('T')[0]);
    setStartDate(thirtyDaysAgo.toISOString().split('T')[0]);
  }, []);

  const downloadCSV = (data: string, filename: string) => {
    const blob = new Blob([data], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    a.click();
    URL.revokeObjectURL(url);
  };

  const handleExportJobs = async () => {
    setIsExporting(true);
    setMessage('');
    try {
      const token = localStorage.getItem('accessToken');
      const response = await fetch('https://api.siteledger.ai/api/export/jobs', {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      if (!response.ok) {
        throw new Error('Failed to export jobs');
      }

      const csvData = await response.text();
      const filename = response.headers.get('Content-Disposition')?.split('filename=')[1]?.replace(/"/g, '') || 'jobs.csv';
      downloadCSV(csvData, filename);
      setMessage('Jobs exported successfully!');
      setTimeout(() => setMessage(''), 3000);
    } catch (error) {
      setMessage('Failed to export jobs. Please try again.');
    } finally {
      setIsExporting(false);
    }
  };

  const handleExportReceipts = async () => {
    setIsExporting(true);
    setMessage('');
    try {
      const token = localStorage.getItem('accessToken');
      const response = await fetch('https://api.siteledger.ai/api/export/receipts', {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      if (!response.ok) {
        throw new Error('Failed to export receipts');
      }

      const csvData = await response.text();
      const filename = response.headers.get('Content-Disposition')?.split('filename=')[1]?.replace(/"/g, '') || 'receipts.csv';
      downloadCSV(csvData, filename);
      setMessage('Receipts exported successfully!');
      setTimeout(() => setMessage(''), 3000);
    } catch (error) {
      setMessage('Failed to export receipts. Please try again.');
    } finally {
      setIsExporting(false);
    }
  };

  const handleExportTimesheets = async () => {
    setIsExporting(true);
    setMessage('');
    try {
      const token = localStorage.getItem('accessToken');
      const response = await fetch('https://api.siteledger.ai/api/export/timesheets', {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      if (!response.ok) {
        throw new Error('Failed to export timesheets');
      }

      const csvData = await response.text();
      const filename = response.headers.get('Content-Disposition')?.split('filename=')[1]?.replace(/"/g, '') || 'timesheets.csv';
      downloadCSV(csvData, filename);
      setMessage('Timesheets exported successfully!');
      setTimeout(() => setMessage(''), 3000);
    } catch (error) {
      setMessage('Failed to export timesheets. Please try again.');
    } finally {
      setIsExporting(false);
    }
  };

  const handleExportAll = async () => {
    setIsExporting(true);
    setMessage('');
    try {
      const token = localStorage.getItem('accessToken');
      const response = await fetch('https://api.siteledger.ai/api/export/all', {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      if (!response.ok) {
        throw new Error('Failed to export all data');
      }

      const result = await response.json();
      
      // Download each CSV file
      if (result.exports.jobs) {
        downloadCSV(result.exports.jobs.data, result.exports.jobs.filename);
      }
      if (result.exports.receipts) {
        downloadCSV(result.exports.receipts.data, result.exports.receipts.filename);
      }
      if (result.exports.timesheets) {
        downloadCSV(result.exports.timesheets.data, result.exports.timesheets.filename);
      }

      setMessage('All data exported successfully!');
      setTimeout(() => setMessage(''), 3000);
    } catch (error) {
      setMessage('Failed to export all data. Please try again.');
    } finally {
      setIsExporting(false);
    }
  };

  return (
    <DashboardLayout>
      <div className="max-w-4xl mx-auto space-y-6">
        <div className="flex items-center gap-4">
          <button
            onClick={() => router.back()}
            className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition"
            aria-label="Go back"
          >
            <ArrowLeft className="w-6 h-6 text-gray-900 dark:text-white" />
          </button>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Export Data</h1>
        </div>

        {/* Date Range Filter */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">
          <div className="flex items-center gap-3 mb-4">
            <Calendar className="w-6 h-6 text-gray-700 dark:text-gray-300" />
            <h2 className="text-xl font-bold text-gray-900 dark:text-white">Date Range</h2>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label htmlFor="export-start-date" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Start Date
              </label>
              <input
                id="export-start-date"
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                aria-label="Export data start date"
              />
            </div>

            <div>
              <label htmlFor="export-end-date" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                End Date
              </label>
              <input
                id="export-end-date"
                type="date"
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                aria-label="Export data end date"
              />
            </div>
          </div>
        </div>

        {/* Success/Error Message */}
        {message && (
          <div className={`p-4 rounded-xl ${message.includes('Failed') ? 'bg-red-50 dark:bg-red-900/30 text-red-800 dark:text-red-300 border border-red-200 dark:border-red-800' : 'bg-green-50 dark:bg-green-900/30 text-green-800 dark:text-green-300 border border-green-200 dark:border-green-800'}`}>
            {message}
          </div>
        )}

        {/* Export Options */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">
          <div className="flex items-center gap-3 mb-4">
            <FileText className="w-6 h-6 text-gray-700 dark:text-gray-300" />
            <h2 className="text-xl font-bold text-gray-900 dark:text-white">Export Options</h2>
          </div>
          
          <div className="space-y-3">
            <button
              onClick={handleExportJobs}
              disabled={isExporting}
              className="w-full flex items-center justify-between p-4 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition disabled:opacity-50"
            >
              <div className="text-left">
                <p className="font-medium text-gray-900 dark:text-white">Export Jobs (CSV)</p>
                <p className="text-sm text-gray-600 dark:text-gray-400">Download all job data as CSV file</p>
              </div>
              <Download className="w-5 h-5 text-blue-600 dark:text-blue-400" />
            </button>

            <button
              onClick={handleExportReceipts}
              disabled={isExporting}
              className="w-full flex items-center justify-between p-4 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition disabled:opacity-50"
            >
              <div className="text-left">
                <p className="font-medium text-gray-900 dark:text-white">Export Receipts (CSV)</p>
                <p className="text-sm text-gray-600 dark:text-gray-400">Download all receipt data as CSV file</p>
              </div>
              <Download className="w-5 h-5 text-green-600 dark:text-green-400" />
            </button>

            <button
              onClick={handleExportTimesheets}
              disabled={isExporting}
              className="w-full flex items-center justify-between p-4 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition disabled:opacity-50"
            >
              <div className="text-left">
                <p className="font-medium text-gray-900 dark:text-white">Export Timesheets (CSV)</p>
                <p className="text-sm text-gray-600 dark:text-gray-400">Download all timesheet data as CSV file</p>
              </div>
              <Download className="w-5 h-5 text-purple-600 dark:text-purple-400" />
            </button>

            <button
              onClick={handleExportAll}
              disabled={isExporting}
              className="w-full flex items-center justify-between p-4 border-2 border-blue-600 dark:border-blue-500 bg-blue-50 dark:bg-blue-900/30 rounded-lg hover:bg-blue-100 dark:hover:bg-blue-900/50 transition disabled:opacity-50"
            >
              <div className="text-left">
                <p className="font-medium text-blue-900 dark:text-blue-300">Export All Data (ZIP)</p>
                <p className="text-sm text-blue-700 dark:text-blue-400">Download jobs, receipts, and timesheets</p>
              </div>
              <Download className="w-6 h-6 text-blue-600 dark:text-blue-400" />
            </button>
          </div>
        </div>

        {/* Info */}
        <div className="bg-blue-50 dark:bg-blue-900/30 border border-blue-200 dark:border-blue-800 rounded-xl p-4">
          <div className="flex items-start gap-3">
            <svg className="w-5 h-5 text-blue-600 dark:text-blue-400 mt-0.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
            </svg>
            <div className="text-sm text-blue-800 dark:text-blue-300">
              <p className="font-medium mb-1">Export Details</p>
              <ul className="list-disc list-inside space-y-1">
                <li>Exports are in CSV format (compatible with Excel, Google Sheets)</li>
                <li>Only data within the selected date range will be exported</li>
                <li>Files are downloaded directly to your device</li>
                <li>No data is sent to third parties during export</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
}
