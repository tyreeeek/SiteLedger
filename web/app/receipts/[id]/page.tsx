'use client';

import { useState, useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import AuthService from '@/lib/auth';
import APIService from '@/lib/api';
import DashboardLayout from '@/components/dashboard-layout';
import { Loader2, ArrowLeft } from 'lucide-react';

export default function ReceiptDetail() {
  const router = useRouter();
  const params = useParams();
  const [isAuthChecked, setIsAuthChecked] = useState(false);
  const [receipt, setReceipt] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    if (!AuthService.isAuthenticated()) {
      router.push('/auth/signin');
    } else {
      setIsAuthChecked(true);
      loadReceipt();
    }
  }, [router, params.id]);

  const loadReceipt = async () => {
    try {
      setIsLoading(true);
      const data = await APIService.fetchReceipt(params.id as string);
      setReceipt(data);
    } catch (error) {
      console.error('Failed to load receipt:', error);
    } finally {
      setIsLoading(false);
    }
  };

  if (!isAuthChecked || isLoading) {
    return (
      <DashboardLayout>
        <div className="flex items-center justify-center min-h-[60vh]">
          <Loader2 className="w-12 h-12 text-blue-600 animate-spin" />
        </div>
      </DashboardLayout>
    );
  }

  if (!receipt) {
    return (
      <DashboardLayout>
        <div className="text-center py-12">
          <p className="text-gray-600 dark:text-gray-400">Receipt not found</p>
          <button
            onClick={() => router.push('/receipts')}
            className="mt-4 text-blue-600 hover:text-blue-700"
          >
            Back to Receipts
          </button>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <button
          onClick={() => router.push('/receipts')}
          className="flex items-center gap-2 text-gray-600 hover:text-gray-900"
        >
          <ArrowLeft className="w-5 h-5" />
          Back
        </button>
        
        <div className="bg-white dark:bg-gray-800 rounded-xl p-6 border border-gray-200 dark:border-gray-700">
          <h1 className="text-2xl font-bold mb-4">{receipt.vendor}</h1>
          <p className="text-lg">Amount: ${receipt.amount}</p>
          <p>Date: {new Date(receipt.date).toLocaleDateString()}</p>
          {receipt.notes && <p className="mt-4">Notes: {receipt.notes}</p>}
        </div>
      </div>
    </DashboardLayout>
  );
}
