'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import DashboardLayout from '@/components/dashboard-layout';
import AuthService from '@/lib/auth';
import APIService from '@/lib/api';
import toast from '@/lib/toast';
import { DollarSign, Users, TrendingUp, Download, Check, X } from 'lucide-react';

interface WorkerPayroll {
  workerId: string;
  workerName: string;
  hoursWorked: number;
  hourlyRate: number;
  totalOwed: number;
  totalPaid: number;
  remainingBalance: number;
  status: 'paid' | 'pending';
  paymentHistory: any[];
}

export default function Payroll() {
  const router = useRouter();
  const [workers, setWorkers] = useState<any[]>([]);
  const [timesheets, setTimesheets] = useState<any[]>([]);
  const [payments, setPayments] = useState<any[]>([]);
  const [payrollData, setPayrollData] = useState<WorkerPayroll[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [showPaymentModal, setShowPaymentModal] = useState(false);
  const [showHistoryModal, setShowHistoryModal] = useState(false);
  const [selectedWorker, setSelectedWorker] = useState<WorkerPayroll | null>(null);
  const [workerHistory, setWorkerHistory] = useState<any[]>([]);
  const [paymentForm, setPaymentForm] = useState({
    amount: '',
    paymentMethod: 'cash' as 'cash' | 'check' | 'direct_deposit' | 'venmo' | 'zelle' | 'paypal' | 'other',
    paymentDate: new Date().toISOString().split('T')[0],
    notes: '',
    referenceNumber: ''
  });

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
      const [workersData, timesheetsData, paymentsData] = await Promise.all([
        APIService.fetchWorkers(),
        APIService.fetchTimesheets(),
        APIService.fetchPayments()
      ]);

      setWorkers(workersData);
      setTimesheets(timesheetsData);
      setPayments(paymentsData);

      // Calculate payroll for each worker
      const payroll: WorkerPayroll[] = workersData.map(worker => {
        const workerTimesheets = timesheetsData.filter((t: any) => t.workerID === worker.id);
        const workerPayments = paymentsData.filter((p: any) => p.workerID === worker.id);

        // Use effectiveHours or hours field
        const hoursWorked = workerTimesheets.reduce((sum: number, t: any) =>
          sum + (t.effectiveHours || t.hours || 0), 0);
        const hourlyRate = worker.hourlyRate || 0;
        const totalOwed = hoursWorked * hourlyRate;

        // Calculate total paid
        const totalPaid = workerPayments.reduce((sum: number, p: any) =>
          sum + (p.amount || 0), 0);

        // Calculate remaining balance
        const remainingBalance = totalOwed - totalPaid;

        // Determine status: paid if remaining balance <= 0
        const status: 'paid' | 'pending' = remainingBalance <= 0 ? 'paid' : 'pending';

        return {
          workerId: worker.id,
          workerName: worker.name,
          hoursWorked,
          hourlyRate,
          totalOwed,
          totalPaid,
          remainingBalance: Math.max(0, remainingBalance), // Never show negative
          status,
          paymentHistory: workerPayments
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

  const handleOpenPaymentModal = (worker: WorkerPayroll) => {
    setSelectedWorker(worker);
    setPaymentForm({
      ...paymentForm,
      amount: worker.remainingBalance.toFixed(2) // Use remaining balance, not total owed
    });
    setShowPaymentModal(true);
  };

  const handleClosePaymentModal = () => {
    setShowPaymentModal(false);
    setSelectedWorker(null);
    setPaymentForm({
      amount: '',
      paymentMethod: 'cash',
      paymentDate: new Date().toISOString().split('T')[0],
      notes: '',
      referenceNumber: ''
    });
  };

  const handleRecordPayment = async () => {
    if (!selectedWorker) return;

    try {
      // Calculate period dates (last 30 days)
      const periodEnd = new Date();
      const periodStart = new Date();
      periodStart.setDate(periodStart.getDate() - 30);

      const paymentData = {
        workerID: selectedWorker.workerId,
        amount: parseFloat(paymentForm.amount),
        paymentDate: paymentForm.paymentDate,
        periodStart: periodStart.toISOString(),
        periodEnd: periodEnd.toISOString(),
        hoursWorked: selectedWorker.hoursWorked,
        hourlyRate: selectedWorker.hourlyRate,
        calculatedEarnings: selectedWorker.totalOwed,
        paymentMethod: paymentForm.paymentMethod,
        notes: paymentForm.notes,
        referenceNumber: paymentForm.referenceNumber
      };

      await APIService.recordPayment(paymentData);
      toast.success(`Payment of ${formatCurrency(parseFloat(paymentForm.amount))} recorded for ${selectedWorker.workerName}`);
      handleClosePaymentModal();
      loadPayrollData(); // Reload to reflect payment
    } catch (error: any) {
      toast.error(error.message || 'Failed to record payment');
    }
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
            <table className="w-full min-w-[800px]">
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
                    Total Earned
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                    Total Paid
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                    Remaining
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
                    <td colSpan={8} className="px-6 py-12 text-center text-gray-500 dark:text-gray-400">
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
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-green-600 dark:text-green-400 font-medium">
                        {formatCurrency(payroll.totalPaid)}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-bold text-orange-600 dark:text-orange-400">
                        {formatCurrency(payroll.remainingBalance)}
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
                      <td className="px-6 py-4 whitespace-nowrap text-sm space-x-2">
                        <button
                          onClick={() => {
                            setSelectedWorker(payroll);
                            setWorkerHistory(payroll.paymentHistory);
                            setShowHistoryModal(true);
                          }}
                          className="px-3 py-1 bg-blue-600 dark:bg-blue-700 text-white rounded-lg hover:bg-blue-700 dark:hover:bg-blue-600 transition text-xs font-medium"
                        >
                          History ({payroll.paymentHistory.length})
                        </button>
                        {payroll.status === 'pending' && (
                          <button
                            onClick={() => handleOpenPaymentModal(payroll)}
                            className="inline-flex items-center gap-1 px-3 py-1 bg-green-600 dark:bg-green-700 text-white rounded-lg hover:bg-green-700 dark:hover:bg-green-600 transition text-xs font-medium"
                          >
                            <DollarSign className="w-4 h-4" />
                            Pay
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

        {/* Payment Modal */}
        {showPaymentModal && selectedWorker && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
            <div className="bg-white dark:bg-gray-800 rounded-xl max-w-md w-full p-6 space-y-4">
              <div className="flex items-center justify-between">
                <h2 className="text-xl font-bold text-gray-900 dark:text-white">Record Payment</h2>
                <button onClick={handleClosePaymentModal} className="p-1 hover:bg-gray-100 dark:hover:bg-gray-700 rounded">
                  <X className="w-5 h-5 text-gray-500" />
                </button>
              </div>

              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Worker
                  </label>
                  <div className="px-3 py-2 bg-gray-50 dark:bg-gray-700 rounded-lg text-gray-900 dark:text-white">
                    {selectedWorker.workerName}
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Calculated Earnings
                  </label>
                  <div className="px-3 py-2 bg-gray-50 dark:bg-gray-700 rounded-lg text-gray-900 dark:text-white">
                    {formatCurrency(selectedWorker.totalOwed)} ({selectedWorker.hoursWorked.toFixed(2)} hrs × {formatCurrency(selectedWorker.hourlyRate)}/hr)
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Payment Amount *
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    value={paymentForm.amount}
                    onChange={(e) => setPaymentForm({ ...paymentForm, amount: e.target.value })}
                    className="w-full px-3 py-2 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg text-gray-900 dark:text-white"
                    placeholder="0.00"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Payment Method *
                  </label>
                  <select
                    value={paymentForm.paymentMethod}
                    onChange={(e) => setPaymentForm({ ...paymentForm, paymentMethod: e.target.value as any })}
                    className="w-full px-3 py-2 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg text-gray-900 dark:text-white"
                  >
                    <option value="cash">Cash</option>
                    <option value="check">Check</option>
                    <option value="direct_deposit">Direct Deposit</option>
                    <option value="venmo">Venmo</option>
                    <option value="zelle">Zelle</option>
                    <option value="paypal">PayPal</option>
                    <option value="other">Other</option>
                  </select>

                  {/* Show Bank Details if Direct Deposit is selected */}
                  {paymentForm.paymentMethod === 'direct_deposit' && (
                    <div className="mt-3 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-100 dark:border-blue-800">
                      <h4 className="text-sm font-semibold text-blue-800 dark:text-blue-300 mb-2 flex items-center gap-2">
                        <DollarSign className="w-4 h-4" />
                        Worker's Banking Information
                      </h4>
                      {(selectedWorker as any).bankInfo && (selectedWorker as any).bankInfo.bankName ? (
                        <div className="text-sm text-gray-700 dark:text-gray-300 space-y-1">
                          <p><span className="font-medium">Bank:</span> {(selectedWorker as any).bankInfo.bankName}</p>
                          <p><span className="font-medium">Account Holder:</span> {(selectedWorker as any).bankInfo.accountHolderName}</p>
                          <p><span className="font-medium">Routing #:</span> {(selectedWorker as any).bankInfo.routingNumber}</p>
                          <p><span className="font-medium">Account #:</span> {(selectedWorker as any).bankInfo.accountNumber}</p>
                          <p><span className="font-medium">Type:</span> {(selectedWorker as any).bankInfo.accountType}</p>
                        </div>
                      ) : (
                        <div className="text-sm text-orange-600 dark:text-orange-400">
                          No banking information available for this worker.
                        </div>
                      )}
                    </div>
                  )}
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Payment Date *
                  </label>
                  <input
                    type="date"
                    value={paymentForm.paymentDate}
                    onChange={(e) => setPaymentForm({ ...paymentForm, paymentDate: e.target.value })}
                    className="w-full px-3 py-2 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg text-gray-900 dark:text-white"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Reference Number
                  </label>
                  <input
                    type="text"
                    value={paymentForm.referenceNumber}
                    onChange={(e) => setPaymentForm({ ...paymentForm, referenceNumber: e.target.value })}
                    className="w-full px-3 py-2 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg text-gray-900 dark:text-white"
                    placeholder="Check #, Transaction ID, etc."
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Notes
                  </label>
                  <textarea
                    value={paymentForm.notes}
                    onChange={(e) => setPaymentForm({ ...paymentForm, notes: e.target.value })}
                    rows={3}
                    className="w-full px-3 py-2 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg text-gray-900 dark:text-white"
                    placeholder="Optional payment notes..."
                  />
                </div>
              </div>

              <div className="flex gap-3 pt-4">
                <button
                  onClick={handleClosePaymentModal}
                  className="flex-1 px-4 py-2 bg-gray-200 dark:bg-gray-700 text-gray-900 dark:text-white rounded-lg hover:bg-gray-300 dark:hover:bg-gray-600"
                >
                  Cancel
                </button>
                <button
                  onClick={handleRecordPayment}
                  className="flex-1 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
                  disabled={!paymentForm.amount || parseFloat(paymentForm.amount) <= 0}
                >
                  Record Payment
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Transaction History Modal */}
        {showHistoryModal && selectedWorker && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
            <div className="bg-white dark:bg-gray-800 rounded-xl max-w-3xl w-full p-6 space-y-4 max-h-[80vh] overflow-y-auto">
              <div className="flex items-center justify-between sticky top-0 bg-white dark:bg-gray-800 pb-4 border-b border-gray-200 dark:border-gray-700">
                <div>
                  <h2 className="text-xl font-bold text-gray-900 dark:text-white">Payment History</h2>
                  <p className="text-sm text-gray-600 dark:text-gray-400">{selectedWorker.workerName}</p>
                </div>
                <button
                  onClick={() => setShowHistoryModal(false)}
                  className="p-1 hover:bg-gray-100 dark:hover:bg-gray-700 rounded"
                  title="Close"
                >
                  <X className="w-5 h-5 text-gray-500" />
                </button>
              </div>

              <div className="grid grid-cols-3 gap-4 p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
                <div>
                  <p className="text-xs text-gray-600 dark:text-gray-400">Total Earned</p>
                  <p className="text-lg font-bold text-gray-900 dark:text-white">{formatCurrency(selectedWorker.totalOwed)}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-600 dark:text-gray-400">Total Paid</p>
                  <p className="text-lg font-bold text-green-600 dark:text-green-400">{formatCurrency(selectedWorker.totalPaid)}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-600 dark:text-gray-400">Remaining</p>
                  <p className="text-lg font-bold text-orange-600 dark:text-orange-400">{formatCurrency(selectedWorker.remainingBalance)}</p>
                </div>
              </div>

              {workerHistory.length === 0 ? (
                <div className="text-center py-12">
                  <DollarSign className="w-16 h-16 text-gray-400 dark:text-gray-500 mx-auto mb-4" />
                  <p className="text-gray-600 dark:text-gray-400">No payment history yet</p>
                  <p className="text-sm text-gray-500 dark:text-gray-500 mt-1">Payments will appear here once recorded</p>
                </div>
              ) : (
                <div className="space-y-3">
                  <h3 className="font-semibold text-gray-900 dark:text-white">Transactions ({workerHistory.length})</h3>
                  {workerHistory.map((payment: any, idx: number) => (
                    <div
                      key={idx}
                      className="p-4 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700/50 transition"
                    >
                      <div className="flex items-start justify-between">
                        <div className="flex-1">
                          <div className="flex items-center gap-2 mb-1">
                            <Check className="w-5 h-5 text-green-600 dark:text-green-400" />
                            <span className="font-semibold text-gray-900 dark:text-white">
                              {formatCurrency(payment.amount)}
                            </span>
                            <span className="px-2 py-0.5 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 text-xs rounded">
                              {payment.paymentMethod?.replace('_', ' ')}
                            </span>
                          </div>
                          <div className="text-sm text-gray-600 dark:text-gray-400 space-y-1">
                            <p>
                              <span className="font-medium">Date:</span> {new Date(payment.paymentDate).toLocaleDateString()}
                            </p>
                            <p>
                              <span className="font-medium">Period:</span> {new Date(payment.periodStart).toLocaleDateString()} - {new Date(payment.periodEnd).toLocaleDateString()}
                            </p>
                            <p>
                              <span className="font-medium">For:</span> {payment.hoursWorked?.toFixed(2) || 0} hours @ {formatCurrency(payment.hourlyRate || 0)}/hr
                            </p>
                            {payment.referenceNumber && (
                              <p>
                                <span className="font-medium">Reference:</span> {payment.referenceNumber}
                              </p>
                            )}
                            {payment.notes && (
                              <p>
                                <span className="font-medium">Notes:</span> {payment.notes}
                              </p>
                            )}
                          </div>
                        </div>
                        <div className="text-right text-xs text-gray-500 dark:text-gray-400">
                          {new Date(payment.createdAt).toLocaleString()}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
