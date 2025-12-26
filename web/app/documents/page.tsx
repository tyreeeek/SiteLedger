'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import APIService from '@/lib/api';
import AuthService from '@/lib/auth';
import toast from '@/lib/toast';
import DashboardLayout from '@/components/dashboard-layout';
import { FileText, Loader2, Search, Plus, Download, Calendar, AlertCircle, File, Image } from 'lucide-react';

export default function Documents() {
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

  if (!isAuthChecked) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
      </div>
    );
  }

  const filteredDocuments = documents.filter((d: any) =>
    d.title?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const getFileIcon = (fileType: string) => {
    if (fileType?.startsWith('image/')) {
      return <Image className="w-8 h-8 text-green-600" />;
    }
    if (fileType === 'application/pdf') {
      return <FileText className="w-8 h-8 text-red-600" />;
    }
    return <File className="w-8 h-8 text-gray-600" />;
  };

  const getFileTypeLabel = (fileType: string) => {
    if (fileType?.startsWith('image/')) return 'Image';
    if (fileType === 'application/pdf') return 'PDF';
    return 'Document';
  };

  if (isLoading) {
    return (
      <DashboardLayout>
        <div className="flex items-center justify-center min-h-[60vh]">
          <div className="text-center">
            <Loader2 className="w-12 h-12 text-blue-600 animate-spin mx-auto mb-4" />
            <p className="text-gray-600 dark:text-gray-400">Loading documents...</p>
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
            <h1 className="text-3xl lg:text-4xl font-bold text-gray-900 dark:text-white">Documents</h1>
            <p className="text-gray-600 dark:text-gray-400 mt-2">Manage contracts, invoices, and files</p>
          </div>
          <button
            onClick={() => router.push('/documents/upload')}
            className="flex items-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition shadow-lg"
          >
            <Plus className="w-5 h-5" />
            Upload
          </button>
        </div>

        {/* Search */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-4 shadow-sm">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 dark:text-gray-500 w-5 h-5" />
            <input
              type="text"
              placeholder="Search documents..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none bg-white dark:bg-gray-700 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400"
            />
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4 shadow-sm">
            <p className="text-sm text-gray-600 dark:text-gray-400">Total Documents</p>
            <p className="text-2xl font-bold text-gray-900 dark:text-white mt-1">{documents.length}</p>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4 shadow-sm">
            <p className="text-sm text-gray-600 dark:text-gray-400">PDF Files</p>
            <p className="text-2xl font-bold text-red-600 dark:text-red-400 mt-1">
              {documents.filter((d: any) => d.fileType === 'application/pdf').length}
            </p>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4 shadow-sm">
            <p className="text-sm text-gray-600 dark:text-gray-400">Images</p>
            <p className="text-2xl font-bold text-green-600 dark:text-green-400 mt-1">
              {documents.filter((d: any) => d.fileType?.startsWith('image/')).length}
            </p>
          </div>
        </div>

        {/* Documents List */}
        {filteredDocuments.length === 0 ? (
          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-12 shadow-sm text-center">
            <AlertCircle className="w-16 h-16 text-gray-400 dark:text-gray-500 mx-auto mb-4" />
            <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">No documents found</h3>
            <p className="text-gray-600 dark:text-gray-400">
              {searchQuery ? 'Try adjusting your search' : 'Upload your first document to get started'}
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {filteredDocuments.map((doc: any) => {
              const job = jobs.find((j: any) => j.id === doc.jobID);
              return (
                <div
                  key={doc.id}
                  className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm hover:shadow-md transition cursor-pointer"
                  onClick={() => router.push(`/documents/${doc.id}`)}
                >
                  <div className="flex items-start gap-4 mb-4">
                    <div className="flex-shrink-0">{getFileIcon(doc.fileType)}</div>
                    <div className="flex-1 min-w-0">
                      <h3 className="font-bold text-gray-900 dark:text-white truncate">{doc.title || 'Untitled'}</h3>
                      <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">{getFileTypeLabel(doc.fileType)}</p>
                    </div>
                  </div>

                  {job && (
                    <div className="mb-3 pb-3 border-b border-gray-200 dark:border-gray-700">
                      <p className="text-sm text-gray-600 dark:text-gray-400">
                        <span className="font-medium">Job:</span> {job.jobName}
                      </p>
                    </div>
                  )}

                  {doc.createdAt && (
                    <div className="flex items-center gap-2 text-sm text-gray-500 dark:text-gray-400 mb-3">
                      <Calendar className="w-4 h-4" />
                      {new Date(doc.createdAt).toLocaleDateString()}
                    </div>
                  )}

                  {doc.fileURL && (
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        window.open(doc.fileURL, '_blank');
                      }}
                      className="w-full flex items-center justify-center gap-2 px-4 py-2 bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 rounded-lg hover:bg-blue-100 dark:hover:bg-blue-900/50 transition"
                    >
                      <Download className="w-4 h-4" />
                      Download
                    </button>
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
