'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import DashboardLayout from '@/components/dashboard-layout';
import AuthService from '@/lib/auth';
import APIService from '@/lib/api';
import { DollarSign, Users, TrendingUp, Download, Check } from 'lucide-react';

interface WorkerPayroll {
  workerId: string;
  workerName: string;
  hoursWorked: number;
  hourlyRate: number;
  totalOwed: number;
  status: 'paid' | 'pending';
}

export default function Payroll() {
  const router = useRouter();
  const [workers, setWorkers] = useState<any[]>([]);
  const [timesheets, setTimesheets] = useState<any[]>([]);
  const [payrollData, setPayrollData] = useState<WorkerPayroll[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    if (!AuthService.isAuthenticated()) {
      router.push('/auth/signin');
    } else {
      loadPayrollData();
    }
  }, []);

  const loadPayrollData = async () => {
    try {
      setIsLoading(true);
      const [workersData, timesheetsData] = await Promise.all([
        APIService.fetchWorkers(),
        APIService.fetchTimesheets()
      ]);

      setWorkers(workersData);
      setTimesheets(timesheetsData);

      // Calculate payroll for each worker
      const payroll: WorkerPayroll[] = workersData.map(worker => {
        const workerTimesheets = timesheetsData.filter((t: any) => t.workerID === worker.id);
        const hoursWorked = workerTimesheets.reduce((sum: number, t: any) => sum + (t.hours || 0), 0);
        const hourlyRate = worker.hourlyRate || 0;
        const totalOwed = hoursWorked * hourlyRate;

        return {
          workerId: worker.id,
          workerName: worker.name,
          hoursWorked,
          hourlyRate,
          totalOwed,
          status: 'pending' as const
        };
      });

      setPayrollData(payroll);
    } catch (error) {
      // Silently fail - UI will show empty state
    } finally {
      setIsLoading(false);
    }
  };

  const totalPayroll = payrollData.reduce((sum, p) => sum + p.totalOwed, 0);
  const workersPaid = payrollData.filter(p => p.status === 'paid').length;
  const avgHourlyRate = workers.length > 0
    ? workers.reduce((sum: number, w: any) => sum + (w.hourlyRate || 0), 0) / workers.length
    : 0;

  const handleMarkAsPaid = (workerId: string) => {
    setPayrollData(prev => prev.map(p =>
      p.workerId === workerId ? { ...p, status: 'paid' as const } : p
    ));
  };

  const handleExportPayroll = () => {
    const csv = [
      ['Worker Name', 'Hours Worked', 'Hourly Rate', 'Total Owed', 'Status'],
      ...payrollData.map(p => [
        p.workerName,
        p.hoursWorked.toFixed(2),
        formatCurrency(p.hourlyRate),
        formatCurrency(p.totalOwed),
        p.status
      ])
    ].map(row => row.join(',')).join('\n');

    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `payroll_${new Date().toISOString().split('T')[0]}.csv`;
    a.click();
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(amount);
  };

  if (isLoading) {
    return (
      <DashboardLayout>
        <div className="flex items-center justify-center h-64">
          <div className="text-gray-500 dark:text-gray-400">Loading payroll data...</div>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <div className="max-w-7xl mx-auto space-y-6">
        <div className="flex items-center justify-between">
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Payroll</h1>
          <button
            onClick={handleExportPayroll}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
          >
            <Download className="w-5 h-5" />
            Export CSV
          </button>
        </div>

        {/* Metrics */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl p-6 text-white shadow-lg">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-blue-100 text-sm mb-1">Total Payroll</p>
                <p className="text-3xl font-bold">{formatCurrency(totalPayroll)}</p>
              </div>
              <div className="p-3 bg-blue-400 rounded-lg">
                <DollarSign className="w-8 h-8" />
              </div>
            </div>
          </div>

          <div className="bg-gradient-to-br from-green-500 to-green-600 rounded-xl p-6 text-white shadow-lg">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-green-100 text-sm mb-1">Workers Paid</p>
                <p className="text-3xl font-bold">{workersPaid} / {workers.length}</p>
              </div>
              <div className="p-3 bg-green-400 rounded-lg">
                <Users className="w-8 h-8" />
              </div>
            </div>
          </div>

          <div className="bg-gradient-to-br from-purple-500 to-purple-600 rounded-xl p-6 text-white shadow-lg">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-purple-100 text-sm mb-1">Avg Hourly Rate</p>
                <p className="text-3xl font-bold">{formatCurrency(avgHourlyRate)}</p>
              </div>
              <div className="p-3 bg-purple-400 rounded-lg">
                <TrendingUp className="w-8 h-8" />
              </div>
            </div>
          </div>
        </div>

        {/* Payroll Table */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 dark:bg-gray-700 border-b border-gray-200 dark:border-gray-600">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                    Worker Name
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                    Hours Worked
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                    Hourly Rate
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                    Total Owed
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                {payrollData.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="px-6 py-12 text-center text-gray-500 dark:text-gray-400">
                      No payroll data available. Add workers and timesheets to see payroll information.
                    </td>
                  </tr>
                ) : (
                  payrollData.map((payroll) => (
                    <tr key={payroll.workerId} className="hover:bg-gray-50 dark:hover:bg-gray-700">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="flex items-center">
                          <div className="w-10 h-10 bg-blue-100 dark:bg-blue-900/30 rounded-full flex items-center justify-center text-blue-600 dark:text-blue-400 font-semibold">
                            {payroll.workerName.charAt(0).toUpperCase()}
                          </div>
                          <div className="ml-3">
                            <p className="text-sm font-medium text-gray-900 dark:text-white">{payroll.workerName}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                        {payroll.hoursWorked.toFixed(2)} hrs
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                        {formatCurrency(payroll.hourlyRate)}/hr
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-semibold text-gray-900 dark:text-white">
                        {formatCurrency(payroll.totalOwed)}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        {payroll.status === 'paid' ? (
                          <span className="px-3 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-300">
                            Paid
                          </span>
                        ) : (
                          <span className="px-3 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-yellow-100 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-300">
                            Pending
                          </span>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm">
                        {payroll.status === 'pending' && (
                          <button
                            onClick={() => handleMarkAsPaid(payroll.workerId)}
                            className="flex items-center gap-1 px-3 py-1 bg-green-600 dark:bg-green-700 text-white rounded-lg hover:bg-green-700 dark:hover:bg-green-600 transition text-xs font-medium"
                          >
                            <Check className="w-4 h-4" />
                            Mark as Paid
                          </button>
                        )}
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
