'use client';

import { useState, useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import APIService from '@/lib/api';
import AuthService from '@/lib/auth';
import toast from '@/lib/toast';
import DashboardLayout from '@/components/dashboard-layout';
import { FileText, Loader2, ArrowLeft, Download, Trash2, File, Image as ImageIcon, Calendar, Briefcase, AlertCircle, ZoomIn, X } from 'lucide-react';

export default function DocumentDetail() {
  const router = useRouter();
  const params = useParams();
  const queryClient = useQueryClient();
  const documentId = params.id as string;
  const [isAuthChecked, setIsAuthChecked] = useState(false);
  const [showFullImage, setShowFullImage] = useState(false);

  useEffect(() => {
    if (!AuthService.isAuthenticated()) {
      router.push('/auth/signin');
    } else {
      setIsAuthChecked(true);
    }
  }, [router]);

  const { data: documents = [], isLoading } = useQuery({
    queryKey: ['documents'],
    queryFn: () => APIService.fetchDocuments(),
    enabled: isAuthChecked,
  });

  const { data: jobs = [] } = useQuery({
    queryKey: ['jobs'],
    queryFn: () => APIService.fetchJobs(),
    enabled: isAuthChecked,
  });

  const document = documents.find((d: any) => d.id === documentId);
  const job = document ? jobs.find((j: any) => j.id === document.jobID) : null;

  const deleteMutation = useMutation({
    mutationFn: () => APIService.deleteDocument(documentId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['documents'] });
      toast.success('Document deleted successfully');
      router.push('/documents');
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.error || 'Failed to delete document');
    },
  });

  if (!isAuthChecked || isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900">
        <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
      </div>
    );
  }

  if (!document) {
    return (
      <DashboardLayout>
        <div className="max-w-4xl mx-auto py-8">
          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-12 shadow-sm text-center">
            <AlertCircle className="w-16 h-16 text-gray-400 dark:text-gray-500 mx-auto mb-4" />
            <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">Document not found</h3>
            <p className="text-gray-600 dark:text-gray-400 mb-6">This document may have been deleted or does not exist.</p>
            <button
              onClick={() => router.push('/documents')}
              className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
            >
              Back to Documents
            </button>
          </div>
        </div>
      </DashboardLayout>
    );
  }

  const getFileIcon = () => {
    if (document.fileType?.startsWith('image/') || document.fileType === 'image') {
      return <ImageIcon className="w-8 h-8 text-green-600 dark:text-green-400" />;
    }
    if (document.fileType === 'application/pdf' || document.fileType === 'pdf') {
      return <FileText className="w-8 h-8 text-red-600 dark:text-red-400" />;
    }
    return <File className="w-8 h-8 text-gray-600 dark:text-gray-400" />;
  };

  const getFileTypeLabel = () => {
    if (document.fileType?.startsWith('image/') || document.fileType === 'image') return 'Image';
    if (document.fileType === 'application/pdf' || document.fileType === 'pdf') return 'PDF';
    return 'Document';
  };

  const handleDelete = async () => {
    if (confirm('Are you sure you want to delete this document? This action cannot be undone.')) {
      await deleteMutation.mutateAsync();
    }
  };

  const isImage = document.fileType?.startsWith('image/') || document.fileType === 'image';

  return (
    <DashboardLayout>
      <div className="max-w-5xl mx-auto py-8 space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <button
              onClick={() => router.push('/documents')}
              className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition"
              aria-label="Back to documents"
            >
              <ArrowLeft className="w-5 h-5 text-gray-600 dark:text-gray-400" />
            </button>
            <div>
              <h1 className="text-3xl lg:text-4xl font-bold text-gray-900 dark:text-white">Document Details</h1>
              <p className="text-gray-600 dark:text-gray-400 mt-1">{document.title || 'Untitled'}</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <a
              href={document.fileURL}
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
            >
              <Download className="w-4 h-4" />
              Download
            </a>
            <button
              onClick={handleDelete}
              disabled={deleteMutation.isPending}
              className="flex items-center gap-2 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition disabled:opacity-50"
            >
              {deleteMutation.isPending ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : (
                <Trash2 className="w-4 h-4" />
              )}
              Delete
            </button>
          </div>
        </div>

        {/* Document Preview */}
        {isImage && document.fileURL && (
          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">Preview</h2>
            <div className="relative group cursor-pointer" onClick={() => setShowFullImage(true)}>
              <img
                src={document.fileURL}
                alt={document.title || 'Document'}
                className="w-full rounded-lg border border-gray-200 dark:border-gray-700 transition-transform hover:scale-[1.01]"
              />
              <div className="absolute inset-0 bg-black/0 group-hover:bg-black/10 transition-colors rounded-lg flex items-center justify-center">
                <div className="opacity-0 group-hover:opacity-100 transition-opacity bg-white dark:bg-gray-800 rounded-full p-4 shadow-lg">
                  <ZoomIn className="w-8 h-8 text-gray-900 dark:text-white" />
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Document Info */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm space-y-6">
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white">Information</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* File Type */}
            <div>
              <label className="flex items-center gap-2 text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                {getFileIcon()}
                File Type
              </label>
              <p className="text-lg text-gray-900 dark:text-white">{getFileTypeLabel()}</p>
            </div>

            {/* Created Date */}
            <div>
              <label className="flex items-center gap-2 text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                <Calendar className="w-4 h-4" />
                Uploaded
              </label>
              <p className="text-lg text-gray-900 dark:text-white">
                {new Date(document.createdAt).toLocaleDateString('en-US', {
                  weekday: 'long',
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric'
                })}
              </p>
            </div>

            {/* Associated Job */}
            {job && (
              <div className="md:col-span-2">
                <label className="flex items-center gap-2 text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  <Briefcase className="w-4 h-4" />
                  Associated Job
                </label>
                <button
                  onClick={() => router.push(`/jobs/${job.id}`)}
                  className="text-lg text-blue-600 dark:text-blue-400 hover:underline"
                >
                  {job.jobName} - {job.clientName}
                </button>
              </div>
            )}
          </div>

          {/* Notes */}
          {document.notes && (
            <div>
              <label className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2 block">Notes</label>
              <p className="text-gray-900 dark:text-white whitespace-pre-wrap">{document.notes}</p>
            </div>
          )}

          {/* Metadata */}
          <div className="pt-6 border-t border-gray-200 dark:border-gray-700">
            <div className="text-sm text-gray-500 dark:text-gray-400 space-y-1">
              <p>Document ID: {document.id}</p>
              <p>Created: {new Date(document.createdAt).toLocaleString()}</p>
            </div>
          </div>
        </div>

        {/* Full Screen Image Modal */}
        {showFullImage && isImage && document.fileURL && (
          <div 
            className="fixed inset-0 z-50 bg-black/95 flex items-center justify-center p-4"
            onClick={() => setShowFullImage(false)}
          >
            <button
              onClick={() => setShowFullImage(false)}
              className="absolute top-4 right-4 p-3 bg-white/10 hover:bg-white/20 rounded-full transition z-10"
              aria-label="Close fullscreen"
            >
              <X className="w-6 h-6 text-white" />
            </button>
            <img
              src={document.fileURL}
              alt={document.title || 'Document'}
              className="max-w-full max-h-full object-contain"
              onClick={(e) => e.stopPropagation()}
            />
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
