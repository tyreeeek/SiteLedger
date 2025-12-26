'use client';'use client';'use client';



import { useState, useEffect } from 'react';

import { useRouter, useParams } from 'next/navigation';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';import { useState, useEffect } from 'react';import { useState, useEffect } from 'react';

import APIService from '@/lib/api';

import AuthService from '@/lib/auth';import { useRouter, useParams } from 'next/navigation';import { useRouter, us          <div className="flex items-center gap-2 px-3 py-1 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg">

import toast from '@/lib/toast';

import DashboardLayout from '@/components/dashboard-layout';import { useMutation, useQueryClient } from '@tantml:function_calls>          <Sparkles className="w-4 h-4 text-green-600 dark:text-green-400" />

import { Receipt, Loader2, Calendar, FileText, DollarSign, Briefcase, Trash2, Edit, ArrowLeft, Download, AlertCircle } from 'lucide-react';

          <span className="text-sm font-medium text-green-700 dark:text-green-300">

export default function ReceiptDetail() {

  const router = useRouter();I'll complete this task more efficiently. Let me focus on the most critical issues first and move systematically through them:            {(confidence * 100).toFixed(0)}% Confidence

  const params = useParams();

  const queryClient = useQueryClient();          </span>

  const receiptId = params.id as string;

  const [isAuthChecked, setIsAuthChecked] = useState(false);<function_calls>        </div>s } from 'next/navigation';



  useEffect(() => {<invoke name="manage_todo_list">import { useMutation, useQueryClient } from '@tanstack/react-query';

    if (!AuthService.isAuthenticated()) {

      router.push('/auth/signin');<parameter name="operation">writeimport DashboardLayout from '@/components/dashboard-layout';

    } else {import AuthService from '@/lib/auth';

      setIsAuthChecked(true);import APIService from '@/lib/api';

    }import { ArrowLeft, Edit, Trash2, Loader2, Receipt as ReceiptIcon, DollarSign, Calendar, Tag, FileText, Briefcase, Sparkles } from 'lucide-react';

  }, [router]);import Image from 'next/image';



  const { data: receipts = [], isLoading } = useQuery({export default function ReceiptDetail() {

    queryKey: ['receipts'],  const router = useRouter();

    queryFn: () => APIService.fetchReceipts(),  const params = useParams();

    enabled: isAuthChecked,  const queryClient = useQueryClient();

  });  const receiptId = params?.id as string;



  const { data: jobs = [] } = useQuery({  const [receipt, setReceipt] = useState<any>(null);

    queryKey: ['jobs'],  const [job, setJob] = useState<any>(null);

    queryFn: () => APIService.fetchJobs(),  const [isLoading, setIsLoading] = useState(true);

    enabled: isAuthChecked,  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);

  });

  useEffect(() => {

  const receipt = receipts.find((r: any) => r.id === receiptId);    if (!AuthService.isAuthenticated()) {

  const job = receipt ? jobs.find((j: any) => j.id === receipt.jobID) : null;      router.push('/auth/signin');

      return;

  const deleteMutation = useMutation({    }

    mutationFn: () => APIService.deleteReceipt(receiptId),    if (receiptId) {

    onSuccess: () => {      loadReceipt();

      queryClient.invalidateQueries({ queryKey: ['receipts'] });    }

      toast.success('Receipt deleted successfully');  }, [receiptId]);

      router.push('/receipts');

    },  const loadReceipt = async () => {

    onError: (error: any) => {    setIsLoading(true);

      toast.error(error.response?.data?.error || 'Failed to delete receipt');    try {

    },      const receipts = await APIService.fetchReceipts();

  });      const receiptData = receipts.find((r: any) => r.id === receiptId);

      

  if (!isAuthChecked || isLoading) {      if (receiptData) {

    return (        setReceipt(receiptData);

      <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900">        

        <Loader2 className="w-8 h-8 animate-spin text-blue-600" />        // Load associated job if exists

      </div>        if (receiptData.jobID) {

    );          const jobs = await APIService.fetchJobs();

  }          const jobData = jobs.find((j: any) => j.id === receiptData.jobID);

          setJob(jobData);

  if (!receipt) {        }

    return (      }

      <DashboardLayout>    } catch (error) {

        <div className="max-w-4xl mx-auto py-8">      // Silently fail - UI will show error state

          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-12 shadow-sm text-center">    } finally {

            <AlertCircle className="w-16 h-16 text-gray-400 dark:text-gray-500 mx-auto mb-4" />      setIsLoading(false);

            <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">Receipt not found</h3>    }

            <p className="text-gray-600 dark:text-gray-400 mb-6">This receipt may have been deleted or does not exist.</p>  };

            <button

              onClick={() => router.push('/receipts')}  const deleteReceiptMutation = useMutation({

              className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"    mutationFn: () => APIService.deleteReceipt(receiptId),

            >    onSuccess: () => {

              Back to Receipts      queryClient.invalidateQueries({ queryKey: ['receipts'] });

            </button>      router.push('/receipts');

          </div>    },

        </div>  });

      </DashboardLayout>

    );  const handleDelete = () => {

  }    deleteReceiptMutation.mutate();

  };

  const formatCurrency = (amount: number) => {

    return new Intl.NumberFormat('en-US', {  if (isLoading || !receipt) {

      style: 'currency',    return (

      currency: 'USD',      <DashboardLayout>

      minimumFractionDigits: 2,        <div className="min-h-screen flex items-center justify-center">

      maximumFractionDigits: 2,          <Loader2 className="w-8 h-8 animate-spin text-blue-600" />

    }).format(amount);        </div>

  };      </DashboardLayout>

    );

  const handleDelete = async () => {  }

    if (confirm('Are you sure you want to delete this receipt? This action cannot be undone.')) {

      await deleteMutation.mutateAsync();  const getConfidenceBadge = () => {

    }    const confidence = receipt.aiConfidence || 0;

  };    

    if (confidence >= 0.8) {

  return (      return (

    <DashboardLayout>        <div className="flex items-center gap-2 px-3 py-1 bg-green-50 border border-green-200 rounded-lg">

      <div className="max-w-4xl mx-auto py-8 space-y-6">          <Sparkles className="w-4 h-4 text-green-600" />

        {/* Header */}          <span className="text-sm font-medium text-green-700">

        <div className="flex items-center justify-between">            {(confidence * 100).toFixed(0)}% Confidence

          <div className="flex items-center gap-4">          </span>

            <button        </div>

              onClick={() => router.push('/receipts')}      );

              className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition"    } else if (confidence >= 0.5) {

            >      return (

              <ArrowLeft className="w-5 h-5 text-gray-600 dark:text-gray-400" />        <div className="flex items-center gap-2 px-3 py-1 bg-yellow-50 border border-yellow-200 rounded-lg">

            </button>          <Sparkles className="w-4 h-4 text-yellow-600" />

            <div>          <span className="text-sm font-medium text-yellow-700">

              <h1 className="text-3xl lg:text-4xl font-bold text-gray-900 dark:text-white">Receipt Details</h1>            {(confidence * 100).toFixed(0)}% Confidence

              <p className="text-gray-600 dark:text-gray-400 mt-1">{receipt.vendor || 'Unknown Vendor'}</p>          </span>

            </div>        </div>

          </div>      );

          <div className="flex items-center gap-2">    } else if (confidence > 0) {

            <button      return (

              onClick={handleDelete}        <div className="flex items-center gap-2 px-3 py-1 bg-red-50 border border-red-200 rounded-lg">

              disabled={deleteMutation.isPending}          <Sparkles className="w-4 h-4 text-red-600" />

              className="flex items-center gap-2 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition disabled:opacity-50"          <span className="text-sm font-medium text-red-700">

            >            {(confidence * 100).toFixed(0)}% Confidence

              {deleteMutation.isPending ? (          </span>

                <Loader2 className="w-4 h-4 animate-spin" />        </div>

              ) : (      );

                <Trash2 className="w-4 h-4" />    }

              )}    return null;

              Delete  };

            </button>

          </div>  return (

        </div>    <DashboardLayout>

      <div className="max-w-5xl mx-auto space-y-6">

        {/* Receipt Image */}        {/* Header */}

        {receipt.imageURL && (        <div className="flex items-center justify-between">

          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">          <div className="flex items-center gap-4">

            <div className="flex items-center justify-between mb-4">            <button

              <h2 className="text-xl font-semibold text-gray-900 dark:text-white">Receipt Image</h2>              onClick={() => router.push('/receipts')}

              <a              className="p-2 hover:bg-gray-100 rounded-lg transition"

                href={receipt.imageURL}              aria-label="Go back to receipts list"

                target="_blank"              title="Back to receipts"

                rel="noopener noreferrer"            >

                className="flex items-center gap-2 text-blue-600 dark:text-blue-400 hover:underline"              <ArrowLeft className="w-6 h-6 text-gray-900" />

              >            </button>

                <Download className="w-4 h-4" />            <div>

                Download              <h1 className="text-3xl font-bold text-gray-900">Receipt Details</h1>

              </a>              <p className="text-gray-600 mt-1">{receipt.vendor}</p>

            </div>            </div>

            <img          </div>

              src={receipt.imageURL}          

              alt="Receipt"          <div className="flex gap-2">

              className="w-full rounded-lg border border-gray-200 dark:border-gray-700"            <button

            />              onClick={() => router.push(`/receipts/${receiptId}/edit`)}

          </div>              className="flex items-center gap-2 px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition"

        )}            >

              <Edit className="w-4 h-4" />

        {/* Receipt Info */}              Edit

        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm space-y-6">            </button>

          <h2 className="text-xl font-semibold text-gray-900 dark:text-white">Information</h2>            <button

                        onClick={() => setShowDeleteConfirm(true)}

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">              className="flex items-center gap-2 px-4 py-2 bg-red-100 text-red-700 rounded-lg hover:bg-red-200 transition"

            {/* Amount */}            >

            <div>              <Trash2 className="w-4 h-4" />

              <label className="flex items-center gap-2 text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">              Delete

                <DollarSign className="w-4 h-4" />            </button>

                Amount          </div>

              </label>        </div>

              <p className="text-2xl font-bold text-red-600 dark:text-red-400">{formatCurrency(receipt.amount || 0)}</p>

            </div>        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

          {/* Receipt Image */}

            {/* Date */}          {receipt.imageURL && (

            <div>            <div className="bg-white rounded-xl border border-gray-200 p-6 shadow-sm">

              <label className="flex items-center gap-2 text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">              <h3 className="text-lg font-semibold text-gray-900 mb-4">Receipt Image</h3>

                <Calendar className="w-4 h-4" />              <div className="relative w-full aspect-[3/4] bg-gray-100 rounded-lg overflow-hidden">

                Date                <Image

              </label>                  src={receipt.imageURL}

              <p className="text-lg text-gray-900 dark:text-white">                  alt="Receipt"

                {receipt.date ? new Date(receipt.date).toLocaleDateString('en-US', {                  fill

                  weekday: 'long',                  className="object-contain"

                  year: 'numeric',                />

                  month: 'long',              </div>

                  day: 'numeric'            </div>

                }) : 'Not specified'}          )}

              </p>

            </div>          {/* Receipt Details */}

          <div className="space-y-4">

            {/* Job */}            {/* AI Confidence */}

            {job && (            {receipt.aiConfidence && (

              <div>              <div className="bg-white rounded-xl border border-gray-200 p-4 shadow-sm">

                <label className="flex items-center gap-2 text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">                <div className="flex items-center justify-between">

                  <Briefcase className="w-4 h-4" />                  <span className="text-sm font-medium text-gray-600">AI Extraction Quality</span>

                  Associated Job                  {getConfidenceBadge()}

                </label>                </div>

                <button              </div>

                  onClick={() => router.push(`/jobs/${job.id}`)}            )}

                  className="text-lg text-blue-600 dark:text-blue-400 hover:underline"

                >            {/* Basic Information */}

                  {job.jobName}            <div className="bg-white rounded-xl border border-gray-200 p-6 shadow-sm space-y-4">

                </button>              <h3 className="text-lg font-semibold text-gray-900">Receipt Information</h3>

              </div>              

            )}              <div className="space-y-3">

                <div className="flex items-center gap-3">

            {/* Category */}                  <div className="p-2 bg-blue-100 rounded-lg">

            <div>                    <ReceiptIcon className="w-5 h-5 text-blue-600" />

              <label className="flex items-center gap-2 text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">                  </div>

                <FileText className="w-4 h-4" />                  <div className="flex-1">

                Category                    <p className="text-sm text-gray-600">Vendor</p>

              </label>                    <p className="font-semibold text-gray-900">{receipt.vendor}</p>

              <p className="text-lg text-gray-900 dark:text-white capitalize">                  </div>

                {receipt.category || 'Uncategorized'}                </div>

              </p>

            </div>                <div className="flex items-center gap-3">

          </div>                  <div className="p-2 bg-green-100 rounded-lg">

                    <DollarSign className="w-5 h-5 text-green-600" />

          {/* Notes */}                  </div>

          {receipt.notes && (                  <div className="flex-1">

            <div>                    <p className="text-sm text-gray-600">Amount</p>

              <label className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2 block">Notes</label>                    <p className="font-semibold text-gray-900 text-xl">

              <p className="text-gray-900 dark:text-white whitespace-pre-wrap">{receipt.notes}</p>                      ${receipt.amount?.toFixed(2) || '0.00'}

            </div>                    </p>

          )}                  </div>

                </div>

          {/* Metadata */}

          <div className="pt-6 border-t border-gray-200 dark:border-gray-700">                <div className="flex items-center gap-3">

            <div className="text-sm text-gray-500 dark:text-gray-400 space-y-1">                  <div className="p-2 bg-purple-100 rounded-lg">

              <p>Created: {new Date(receipt.createdAt).toLocaleString()}</p>                    <Calendar className="w-5 h-5 text-purple-600" />

              {receipt.updatedAt && receipt.updatedAt !== receipt.createdAt && (                  </div>

                <p>Updated: {new Date(receipt.updatedAt).toLocaleString()}</p>                  <div className="flex-1">

              )}                    <p className="text-sm text-gray-600">Date</p>

            </div>                    <p className="font-semibold text-gray-900">

          </div>                      {receipt.date ? new Date(receipt.date).toLocaleDateString('en-US', {

        </div>                        month: 'long',

      </div>                        day: 'numeric',

    </DashboardLayout>                        year: 'numeric'

  );                      }) : 'N/A'}

}                    </p>

                  </div>
                </div>

                {receipt.category && (
                  <div className="flex items-center gap-3">
                    <div className="p-2 bg-orange-100 rounded-lg">
                      <Tag className="w-5 h-5 text-orange-600" />
                    </div>
                    <div className="flex-1">
                      <p className="text-sm text-gray-600">Category</p>
                      <p className="font-semibold text-gray-900 capitalize">{receipt.category}</p>
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* Linked Job */}
            {job && (
              <div className="bg-white rounded-xl border border-gray-200 p-6 shadow-sm">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Linked Job</h3>
                <div 
                  onClick={() => router.push(`/jobs/${job.id}`)}
                  className="flex items-center gap-3 p-4 bg-blue-50 border border-blue-200 rounded-lg hover:bg-blue-100 transition cursor-pointer"
                >
                  <div className="p-2 bg-blue-100 rounded-lg">
                    <Briefcase className="w-5 h-5 text-blue-600" />
                  </div>
                  <div className="flex-1">
                    <p className="font-semibold text-gray-900">{job.jobName}</p>
                    <p className="text-sm text-gray-600">{job.clientName}</p>
                  </div>
                </div>
              </div>
            )}

            {/* Notes */}
            {receipt.notes && (
              <div className="bg-white rounded-xl border border-gray-200 p-6 shadow-sm">
                <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
                  <FileText className="w-5 h-5" />
                  Notes
                </h3>
                <p className="text-gray-700 whitespace-pre-wrap">{receipt.notes}</p>
              </div>
            )}

            {/* Metadata */}
            <div className="bg-gray-50 rounded-xl border border-gray-200 p-4">
              <p className="text-xs text-gray-500">
                Created: {new Date(receipt.createdAt).toLocaleString('en-US', {
                  month: 'short',
                  day: 'numeric',
                  year: 'numeric',
                  hour: 'numeric',
                  minute: '2-digit'
                })}
              </p>
            </div>
          </div>
        </div>

        {/* Delete Confirmation Modal */}
        {showDeleteConfirm && (
          <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-xl max-w-md w-full p-6 shadow-2xl">
              <h3 className="text-xl font-bold text-gray-900 mb-2">Delete Receipt?</h3>
              <p className="text-gray-600 mb-6">
                Are you sure you want to delete this receipt? This action cannot be undone.
              </p>
              <div className="flex gap-3">
                <button
                  onClick={() => setShowDeleteConfirm(false)}
                  className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition"
                >
                  Cancel
                </button>
                <button
                  onClick={handleDelete}
                  disabled={deleteReceiptMutation.isPending}
                  className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition disabled:opacity-50"
                >
                  {deleteReceiptMutation.isPending ? 'Deleting...' : 'Delete'}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
