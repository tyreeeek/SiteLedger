'use client';

import { useState, useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import AuthService from '@/lib/auth';
import APIService from '@/lib/api';
import DashboardLayout from '@/components/dashboard-layout';
import { Loader2, ArrowLeft, X, ZoomIn } from 'lucide-react';

export default function ReceiptDetail() {
  const router = useRouter();
  const params = useParams();
  const [isAuthChecked, setIsAuthChecked] = useState(false);
  const [receipt, setReceipt] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [showFullImage, setShowFullImage] = useState(false);

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
          <div className="space-y-2">
            <p className="text-lg"><strong>Amount:</strong> ${receipt.amount.toFixed(2)}</p>
            <p><strong>Date:</strong> {new Date(receipt.date).toLocaleDateString()}</p>
            <p><strong>Category:</strong> {receipt.category}</p>
            {receipt.jobName && <p><strong>Job:</strong> {receipt.jobName}</p>}
            {receipt.notes && <p className="mt-4"><strong>Notes:</strong> {receipt.notes}</p>}
          </div>
          
          {receipt.imageURL && (
            <div className="mt-6">
              <h2 className="text-lg font-semibold mb-3">Receipt Image</h2>
              <div className="relative group cursor-pointer" onClick={() => setShowFullImage(true)}>
                <img 
                  src={receipt.imageURL} 
                  alt={`Receipt from ${receipt.vendor}`}
                  className="max-w-full h-auto rounded-lg border border-gray-300 dark:border-gray-600 transition-transform hover:scale-[1.02]"
                />
                <div className="absolute inset-0 bg-black/0 group-hover:bg-black/10 transition-colors rounded-lg flex items-center justify-center">
                  <div className="opacity-0 group-hover:opacity-100 transition-opacity bg-white dark:bg-gray-800 rounded-full p-3 shadow-lg">
                    <ZoomIn className="w-6 h-6 text-gray-900 dark:text-white" />
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Full Screen Image Modal */}
        {showFullImage && receipt.imageURL && (
          <div 
            className="fixed inset-0 z-50 bg-black/90 flex items-center justify-center p-4"
            onClick={() => setShowFullImage(false)}
          >
            <button
              onClick={() => setShowFullImage(false)}
              className="absolute top-4 right-4 p-2 bg-white/10 hover:bg-white/20 rounded-full transition"
              aria-label="Close"
            >
              <X className="w-6 h-6 text-white" />
            </button>
            <img
              src={receipt.imageURL}
              alt={`Receipt from ${receipt.vendor}`}
              className="max-w-full max-h-full object-contain"
              onClick={(e) => e.stopPropagation()}
            />
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
