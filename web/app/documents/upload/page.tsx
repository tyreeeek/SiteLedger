'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import DashboardLayout from '@/components/dashboard-layout';
import AuthService from '@/lib/auth';
import APIService from '@/lib/api';
import toast from '@/lib/toast';
import { ArrowLeft, Loader2, Upload, FileText } from 'lucide-react';

export default function UploadDocument() {
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(false);
  const [jobs, setJobs] = useState<any[]>([]);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [formData, setFormData] = useState({
    jobID: '',
    title: '',
    fileType: 'other' as 'pdf' | 'image' | 'other',  // Backend only accepts: pdf, image, other
    notes: ''
  });

  useEffect(() => {
    loadJobs();
  }, []);

  const loadJobs = async () => {
    try {
      const jobsData = await APIService.fetchJobs();
      setJobs(jobsData);
    } catch (error) {
      // Silently fail - user can still upload without job assignment
    }
  };

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      setSelectedFile(file);

      // Auto-detect file type - backend accepts: pdf, image, other
      const fileType = file.type;
      let detectedType: 'pdf' | 'image' | 'other' = 'other';
      if (fileType.includes('pdf')) detectedType = 'pdf';
      else if (fileType.includes('image')) detectedType = 'image';

      setFormData({ ...formData, title: file.name, fileType: detectedType });
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!selectedFile) {
      toast.error('Please select a file to upload');
      return;
    }

    setIsLoading(true);

    try {
      const user = AuthService.getCurrentUser();
      if (!user) {
        toast.error('Please sign in');
        router.push('/auth/signin');
        return;
      }

      // 1. Upload file using APIService
      const fileURL = await APIService.uploadFile(selectedFile, 'document');
      console.log('File uploaded successfully, URL:', fileURL);

      // 2. Create document record
      const documentData = {
        jobID: formData.jobID || null,
        title: formData.title,
        fileURL: fileURL,
        fileType: formData.fileType,
        notes: formData.notes || ''
      };

      console.log('Creating document record with data:', documentData);
      await APIService.createDocument(documentData);
      toast.success('Document uploaded successfully!');
      router.push('/documents');
    } catch (error: any) {
      console.error('Document upload error:', error);
      const errorMessage = error.message || 'Failed to upload document. Please try again.';
      toast.error(errorMessage);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <DashboardLayout>
      <div className="max-w-3xl mx-auto space-y-6">
        <div className="flex items-center gap-4">
          <button
            onClick={() => router.back()}
            className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition"
            aria-label="Go back to documents list"
            title="Go back"
          >
            <ArrowLeft className="w-6 h-6 text-gray-900 dark:text-white" />
          </button>
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Upload Document</h1>
            <p className="text-gray-600 mt-1">Add contracts, invoices, or files</p>
          </div>
        </div>

        <form onSubmit={handleSubmit} className="bg-white rounded-xl border border-gray-200 p-6 shadow-sm space-y-6">
          {/* File Upload */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              File <span className="text-red-500">*</span>
            </label>
            <div className="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center hover:border-blue-500 transition">
              <input
                type="file"
                onChange={handleFileSelect}
                className="hidden"
                id="file-upload"
                accept=".pdf,.doc,.docx,.xls,.xlsx,.jpg,.jpeg,.png"
              />
              <label
                htmlFor="file-upload"
                className="cursor-pointer flex flex-col items-center gap-2"
              >
                {selectedFile ? (
                  <>
                    <FileText className="w-12 h-12 text-blue-600" />
                    <p className="text-sm font-medium text-gray-900">{selectedFile.name}</p>
                    <p className="text-xs text-gray-500">
                      {(selectedFile.size / 1024 / 1024).toFixed(2)} MB
                    </p>
                    <p className="text-xs text-blue-600 hover:underline">Click to change</p>
                  </>
                ) : (
                  <>
                    <Upload className="w-12 h-12 text-gray-400" />
                    <p className="text-sm font-medium text-gray-900">Click to upload</p>
                    <p className="text-xs text-gray-500">
                      PDF, DOC, XLS, JPG, PNG (Max 10MB)
                    </p>
                  </>
                )}
              </label>
            </div>
          </div>

          {/* File Name */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Document Title <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              required
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              placeholder="e.g., Contract - Kitchen Renovation"
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-gray-900 bg-white"
            />
          </div>

          {/* File Type */}
          <div>
            <label htmlFor="doc-type" className="block text-sm font-medium text-gray-700 mb-2">
              Document Type
            </label>
            <select
              id="doc-type"
              value={formData.fileType}
              onChange={(e) => setFormData({ ...formData, fileType: e.target.value as 'pdf' | 'image' | 'other' })}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-gray-900 bg-white"
              aria-label="Select document type"
            >
              <option value="pdf">PDF Document</option>
              <option value="image">Image/Photo</option>
              <option value="other">Other</option>
            </select>
          </div>

          {/* Job Association (Optional) */}
          <div>
            <label htmlFor="doc-job" className="block text-sm font-medium text-gray-700 mb-2">
              Associated Job (Optional)
            </label>
            <select
              id="doc-job"
              value={formData.jobID}
              onChange={(e) => setFormData({ ...formData, jobID: e.target.value })}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-gray-900 bg-white"
              aria-label="Select associated job"
            >
              <option value="">No job association</option>
              {jobs.map((job) => (
                <option key={job.id} value={job.id}>
                  {job.jobName} - {job.clientName}
                </option>
              ))}
            </select>
          </div>

          {/* Notes */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Notes
            </label>
            <textarea
              rows={3}
              value={formData.notes}
              onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
              placeholder="Additional notes about this document..."
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-gray-900 bg-white"
            />
          </div>

          {/* Submit Button */}
          <div className="flex gap-4 pt-4">
            <button
              type="button"
              onClick={() => router.back()}
              className="flex-1 px-6 py-3 border-2 border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition"
              disabled={isLoading}
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isLoading || !selectedFile}
              className="flex-1 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isLoading ? (
                <>
                  <Loader2 className="w-5 h-5 animate-spin" />
                  Uploading...
                </>
              ) : (
                <>
                  <Upload className="w-5 h-5" />
                  Upload Document
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </DashboardLayout>
  );
}
