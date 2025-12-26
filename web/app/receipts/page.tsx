'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import APIService from '@/lib/api';
import AuthService from '@/lib/auth';
import DashboardLayout from '@/components/dashboard-layout';
import { Receipt, Loader2, Search, Plus, DollarSign, Calendar, FileText, AlertCircle } from 'lucide-react';

export default function Receipts() {
  const router = useRouter();
  const [isAuthChecked, setIsAuthChecked] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    if (!AuthService.isAuthenticated()) {
      router.push('/auth/signin');
    } else {
      setIsAuthChecked(true);
    }
  }, [router]);

  const { data: receipts = [], isLoading } = useQuery({
    queryKey: ['receipts'],
    queryFn: () => APIService.fetchReceipts(),
    enabled: isAuthChecked,
  });

  const { data: jobs = [] } = useQuery({
    queryKey: ['jobs'],
    queryFn: () => APIService.fetchJobs(),
    enabled: isAuthChecked,
  });

  if (!isAuthChecked) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
      </div>
    );
  }

  const filteredReceipts = receipts.filter((r: any) => 
    r.vendor?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    r.notes?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('en-US', { 
      style: 'currency', 
      currency: 'USD',
      minimumFractionDigits: 2,
    }).format(value);
  };

  const totalExpenses = receipts.reduce((sum: number, r: any) => sum + (r.amount || 0), 0);

  if (isLoading) {
    return (
      <DashboardLayout>
        <div className="flex items-center justify-center min-h-[60vh]">
          <div className="text-center">
            <Loader2 className="w-12 h-12 text-blue-600 animate-spin mx-auto mb-4" />
            <p className="text-gray-600 dark:text-gray-400">Loading receipts...</p>
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
            <h1 className="text-3xl lg:text-4xl font-bold text-gray-900 dark:text-white">Receipts</h1>
            <p className="text-gray-600 dark:text-gray-400 mt-2">Track expenses and receipts</p>
          </div>
          <button 
            onClick={() => router.push('/receipts/create')}
            className="flex items-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition shadow-lg"
          >
            <Plus className="w-5 h-5" />
            Add Receipt
          </button>
        </div>

        {/* Search */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-4 shadow-sm">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 dark:text-gray-500 w-5 h-5" />
            <input
              type="text"
              placeholder="Search by vendor or notes..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none bg-white dark:bg-gray-700 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400"
            />
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4 shadow-sm">
            <p className="text-sm text-gray-600 dark:text-gray-400">Total Receipts</p>
            <p className="text-2xl font-bold text-gray-900 dark:text-white mt-1">{receipts.length}</p>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4 shadow-sm">
            <p className="text-sm text-gray-600 dark:text-gray-400">Total Expenses</p>
            <p className="text-2xl font-bold text-red-600 dark:text-red-400 mt-1">{formatCurrency(totalExpenses)}</p>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4 shadow-sm">
            <p className="text-sm text-gray-600 dark:text-gray-400">This Month</p>
            <p className="text-2xl font-bold text-gray-900 dark:text-white mt-1">
              {receipts.filter((r: any) => {
                const date = new Date(r.date || r.createdAt);
                const now = new Date();
                return date.getMonth() === now.getMonth() && date.getFullYear() === now.getFullYear();
              }).length}
            </p>
          </div>
        </div>

        {/* Receipts List */}
        {filteredReceipts.length === 0 ? (
          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-12 shadow-sm text-center">
            <AlertCircle className="w-16 h-16 text-gray-400 dark:text-gray-500 mx-auto mb-4" />
            <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">No receipts found</h3>
            <p className="text-gray-600 dark:text-gray-400">
              {searchQuery ? 'Try adjusting your search' : 'Add your first receipt to get started'}
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {filteredReceipts.map((receipt: any) => {
              const job = jobs.find((j: any) => j.id === receipt.jobID);
              return (
                <div
                  key={receipt.id}
                  className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-4 shadow-sm hover:shadow-md transition cursor-pointer"
                  onClick={() => router.push(`/receipts/${receipt.id}`)}
                >
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex-1">
                      <h3 className="font-bold text-gray-900 dark:text-white">{receipt.vendor || 'Unknown Vendor'}</h3>
                      {job && <p className="text-sm text-gray-600 dark:text-gray-400">{job.jobName}</p>}
                    </div>
                    <div className="text-right">
                      <p className="font-bold text-red-600 dark:text-red-400">{formatCurrency(receipt.amount || 0)}</p>
                    </div>
                  </div>
                  
                  {receipt.date && (
                    <div className="flex items-center gap-2 text-sm text-gray-500 dark:text-gray-400 mb-2">
                      <Calendar className="w-4 h-4" />
                      {new Date(receipt.date).toLocaleDateString()}
                    </div>
                  )}
                  
                  {receipt.notes && (
                    <p className="text-sm text-gray-600 dark:text-gray-400 line-clamp-2">{receipt.notes}</p>
                  )}
                  
                  {receipt.imageURL && (
                    <div className="mt-3 flex items-center gap-2 text-sm text-blue-600 dark:text-blue-400">
                      <FileText className="w-4 h-4" />
                      Image attached
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
