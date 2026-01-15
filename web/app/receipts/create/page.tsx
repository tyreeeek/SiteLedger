'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import APIService from '@/lib/api';
import AuthService from '@/lib/auth';
import toast from '@/lib/toast';
import DashboardLayout from '@/components/dashboard-layout';
import { Receipt, Loader2, Upload, X, CheckCircle, AlertCircle, Sparkles, Brain } from 'lucide-react';

export default function CreateReceipt() {
  const router = useRouter();
  const queryClient = useQueryClient();
  const [isAuthChecked, setIsAuthChecked] = useState(false);
  
  const [formData, setFormData] = useState({
    vendor: '',
    amount: '',
    date: new Date().toISOString().split('T')[0],
    jobID: '',
    notes: '',
    category: 'materials',
  });
  
  const [ocrDebugInfo, setOcrDebugInfo] = useState<string>('');
  
  // DEBUG: Log every formData change
  useEffect(() => {
    console.log('📊 FORM DATA CHANGED:', formData);
  }, [formData]);
  
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [errors, setErrors] = useState<any>({});
  const [isProcessingAI, setIsProcessingAI] = useState(false);
  const [aiConfidence, setAiConfidence] = useState<number | null>(null);

  useEffect(() => {
    if (!AuthService.isAuthenticated()) {
      router.push('/auth/signin');
    } else {
      setIsAuthChecked(true);
    }
  }, [router]);

  const { data: jobs = [] } = useQuery({
    queryKey: ['jobs'],
    queryFn: () => APIService.fetchJobs(),
    enabled: isAuthChecked,
  });

  const createMutation = useMutation({
    mutationFn: async (receipt: any) => {
      const user = AuthService.getCurrentUser();
      const receiptData = {
        ...receipt,
        ownerID: user?.id,
        createdAt: new Date().toISOString(),
      };
      return APIService.createReceipt(receiptData);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['receipts'] });
      router.push('/receipts');
    },
  });

  if (!isAuthChecked) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
      </div>
    );
  }

  const handleImageSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setImageFile(file);
      const reader = new FileReader();
      reader.onloadend = () => {
        const result = reader.result as string;
        setImagePreview(result);
        // Auto-process with AI if available - pass the file directly
        processImageWithAI(result, file);
      };
      reader.readAsDataURL(file);
    }
  };

  const processImageWithAI = async (imageData: string, file: File) => {
    setIsProcessingAI(true);
    
    try {
      // Upload the image first
      if (!file) {
        toast.error('No image file selected');
        setIsProcessingAI(false);
        return;
      }
      
      toast.success('📤 Uploading receipt...');
      const imageURL = await APIService.uploadFile(file, 'receipt');
      console.log('📤 Image uploaded successfully:', imageURL);
      
      // Try OCR to extract data
      toast.success('🔍 Scanning receipt with AI...');
      try {
        const ocrResult = await APIService.processReceiptOCR(imageURL);
        console.log('🔍 RAW OCR RESULT:', ocrResult);
        console.log('🔍 OCR SUCCESS:', ocrResult.success);
        console.log('🔍 OCR DATA:', ocrResult.data);
        
        if (ocrResult.success && ocrResult.data) {
          const { vendor, amount, date, category } = ocrResult.data;
          
          console.log('📝 Extracted vendor:', vendor);
          console.log('📝 Extracted amount:', amount);
          console.log('📝 Extracted date:', date);
          console.log('📝 Extracted category:', category);
          
          // Update form data with all extracted values at once
          const updates: any = {};
          if (vendor && vendor !== 'Unknown Vendor' && vendor.trim() !== '') {
            updates.vendor = vendor.trim();
          }
          if (amount && amount > 0) {
            updates.amount = amount.toString();
          }
          if (date) {
            updates.date = date;
          }
          if (category) {
            updates.category = category;
          }
          
          console.log('📊 Applying updates to form:', updates);
          setFormData(prev => ({ ...prev, ...updates }));
          
          const hasData = updates.vendor || updates.amount;
          if (hasData) {
            toast.success('✨ Receipt scanned successfully! Review and submit.');
            setAiConfidence(ocrResult.data.confidence || 0.85);
          } else {
            toast.info('⚠️ Could not read receipt. Please enter details manually.');
            setAiConfidence(null);
          }
        } else {
          console.log('❌ OCR did not return success or data');
          toast.info('⚠️ Could not read receipt. Please enter details manually.');
          setAiConfidence(null);
        }
      } catch (ocrError) {
        console.error('❌ OCR ERROR:', ocrError);
        toast.info('⚠️ OCR failed. Please enter details manually.');
        setAiConfidence(null);
      }
      
    } catch (error: any) {
      console.error('❌ Upload ERROR:', error);
      console.error('Error details:', {
        message: error.message,
        response: error.response?.data,
        status: error.response?.status
      });
      
      const errorMsg = error.message || 'Failed to upload image';
      toast.error(`❌ Upload failed: ${errorMsg}. Please try again.`);
      
      // Clear the failed image so user can try again
      setImageFile(null);
      setImagePreview(null);
    } finally {
      setIsProcessingAI(false);
    }
  };

  const removeImage = () => {
    setImageFile(null);
    setImagePreview(null);
  };

  const validate = () => {
    const newErrors: any = {};
    
    // No validation - all fields are optional
    // Users can submit with whatever information they have
    
    setErrors(newErrors);
    return true; // Always pass validation
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validate()) return;
    
    let imageURL = null;
    
    // Upload image if present
    if (imageFile) {
      try {
        imageURL = await APIService.uploadFile(imageFile, 'receipt');
      } catch (error) {
        toast.error('Failed to upload receipt image. Please try again.');
        return;
      }
    }
    
    const receiptData = {
      vendor: formData.vendor,
      amount: parseFloat(formData.amount),
      date: formData.date,
      jobID: formData.jobID || null,
      notes: formData.notes,
      category: formData.category,
      imageURL: imageURL,
    };
    
    createMutation.mutate(receiptData);
  };

  return (
    <DashboardLayout>
      <div className="max-w-2xl mx-auto space-y-6">
        {/* Header */}
        <div>
          <h1 className="text-3xl lg:text-4xl font-bold text-gray-900 dark:text-white">Add Receipt</h1>
          <p className="text-gray-600 dark:text-gray-400 mt-2">Track expenses and receipts</p>
        </div>

        {/* Form Card */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">
          <form onSubmit={handleSubmit} className="space-y-6">
            {/* Image Upload */}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Receipt Image
              </label>
              
              {!imagePreview ? (
                <label className="flex flex-col items-center justify-center w-full h-48 border-2 border-dashed border-gray-300 dark:border-gray-600 rounded-lg cursor-pointer hover:border-[#007AFF] dark:hover:border-[#3b82f6] hover:bg-blue-50 dark:hover:bg-gray-700 transition">
                  <div className="text-center">
                    <Upload className="w-12 h-12 text-gray-400 dark:text-gray-500 mx-auto mb-3" />
                    <p className="text-sm text-gray-600 dark:text-gray-300 font-medium">Click to upload receipt image</p>
                    <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">PNG, JPG up to 10MB</p>
                  </div>
                  <input
                    type="file"
                    className="hidden"
                    accept="image/*"
                    onChange={handleImageSelect}
                  />
                </label>
              ) : (
                <div className="relative">
                  <img
                    src={imagePreview}
                    alt="Receipt preview"
                    className="w-full h-64 object-contain bg-gray-50 rounded-lg"
                  />
                  <button
                    type="button"
                    onClick={removeImage}
                    className="absolute top-2 right-2 p-2 bg-red-500 text-white rounded-full hover:bg-red-600 transition"
                    aria-label="Remove image"
                  >
                    <X className="w-4 h-4" />
                  </button>
                </div>
              )}
              
              {/* AI Processing Indicator */}
              {isProcessingAI && (
                <div className="mt-3 flex items-center gap-2 p-3 bg-purple-50 border border-purple-200 rounded-lg">
                  <Loader2 className="w-5 h-5 text-purple-600 animate-spin" />
                  <div className="flex-1">
                    <p className="text-sm font-medium text-purple-900">AI is reading your receipt...</p>
                    <p className="text-xs text-purple-600 mt-0.5">Extracting vendor, amount, and date</p>
                  </div>
                  <Brain className="w-5 h-5 text-purple-600" />
                </div>
              )}
              
              {/* AI Confidence Badge */}
              {aiConfidence !== null && !isProcessingAI && (
                <div className={`mt-3 flex items-center gap-2 p-3 rounded-lg ${
                  aiConfidence >= 0.8 ? 'bg-green-50 border border-green-200' :
                  aiConfidence >= 0.5 ? 'bg-yellow-50 border border-yellow-200' :
                  'bg-red-50 border border-red-200'
                }`}>
                  <Sparkles className={`w-5 h-5 ${
                    aiConfidence >= 0.8 ? 'text-green-600' :
                    aiConfidence >= 0.5 ? 'text-yellow-600' :
                    'text-red-600'
                  }`} />
                  <div className="flex-1">
                    <p className={`text-sm font-medium ${
                      aiConfidence >= 0.8 ? 'text-green-900' :
                      aiConfidence >= 0.5 ? 'text-yellow-900' :
                      'text-red-900'
                    }`}>
                      AI extracted data ({(aiConfidence * 100).toFixed(0)}% confidence)
                    </p>
                    <p className={`text-xs mt-0.5 ${
                      aiConfidence >= 0.8 ? 'text-green-600' :
                      aiConfidence >= 0.5 ? 'text-yellow-600' :
                      'text-red-600'
                    }`}>
                      {aiConfidence >= 0.8 ? 'High confidence - review and submit' :
                       aiConfidence >= 0.5 ? 'Medium confidence - please verify details' :
                       'Low confidence - please check all fields'}
                    </p>
                  </div>
                </div>
              )}
              
              {/* DEBUG INFO */}
              {ocrDebugInfo && (
                <div className="mt-3 p-3 bg-gray-100 dark:bg-gray-800 rounded-lg border border-gray-300 dark:border-gray-600">
                  <p className="text-xs font-mono text-gray-700 dark:text-gray-300 whitespace-pre-wrap break-all">
                    {ocrDebugInfo}
                  </p>
                </div>
              )}
            </div>

            {/* Vendor */}
            <div>
              <label htmlFor="vendor" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Vendor Name
              </label>
              <input
                id="vendor"
                type="text"
                value={formData.vendor}
                onChange={(e) => setFormData({ ...formData, vendor: e.target.value })}
                className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-[#007AFF] dark:focus:ring-[#3b82f6] focus:border-transparent outline-none text-gray-900 dark:text-white bg-white dark:bg-gray-700"
                placeholder="e.g., Home Depot, Lowe's"
              />
            </div>

            {/* Amount */}
            <div>
              <label htmlFor="amount" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Amount
              </label>
              <div className="relative">
                <span className="absolute left-4 top-2 text-gray-500 dark:text-gray-400">$</span>
                <input
                  id="amount"
                  type="number"
                  step="0.01"
                  value={formData.amount}
                  onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
                  className="w-full pl-8 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-[#007AFF] dark:focus:ring-[#3b82f6] focus:border-transparent outline-none text-gray-900 dark:text-white bg-white dark:bg-gray-700"
                  placeholder="0.00"
                />
              </div>
            </div>

            {/* Date */}
            <div>
              <label htmlFor="date" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Date
              </label>
              <input
                id="date"
                type="date"
                value={formData.date}
                onChange={(e) => setFormData({ ...formData, date: e.target.value })}
                className={`w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#007AFF] dark:focus:ring-[#3b82f6] focus:border-transparent outline-none text-gray-900 dark:text-white bg-white dark:bg-gray-700 ${
                  errors.date ? 'border-red-500' : 'border-gray-300 dark:border-gray-600'
                }`}
              />
              {errors.date && (
                <p className="text-red-500 dark:text-red-400 text-sm mt-1">{errors.date}</p>
              )}
            </div>

            {/* Category */}
            <div>
              <label htmlFor="category" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Category
              </label>
              <select
                id="category"
                value={formData.category}
                onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-[#007AFF] dark:focus:ring-[#3b82f6] focus:border-transparent outline-none text-gray-900 dark:text-white bg-white dark:bg-gray-700"
              >
                <option value="materials">Materials</option>
                <option value="equipment">Equipment</option>
                <option value="labor">Labor</option>
                <option value="permits">Permits</option>
                <option value="transportation">Transportation</option>
                <option value="other">Other</option>
              </select>
            </div>

            {/* Job Assignment */}
            <div>
              <label htmlFor="jobID" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Assign to Job (Optional)
              </label>
              <select
                id="jobID"
                value={formData.jobID}
                onChange={(e) => setFormData({ ...formData, jobID: e.target.value })}
                className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-[#007AFF] dark:focus:ring-[#3b82f6] focus:border-transparent outline-none text-gray-900 dark:text-white bg-white dark:bg-gray-700"
              >
                <option value="">No job assigned</option>
                {jobs.map((job: any) => (
                  <option key={job.id} value={job.id}>
                    {job.jobName} - {job.clientName}
                  </option>
                ))}
              </select>
            </div>

            {/* Notes */}
            <div>
              <label htmlFor="notes" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Notes
              </label>
              <textarea
                id="notes"
                value={formData.notes}
                onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                rows={3}
                className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-[#007AFF] dark:focus:ring-[#3b82f6] focus:border-transparent outline-none text-gray-900 dark:text-white bg-white dark:bg-gray-700 resize-none"
                placeholder="Additional details about this expense..."
              />
            </div>

            {/* Error Display */}
            {createMutation.isError && (
              <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4 flex items-start gap-3">
                <AlertCircle className="w-5 h-5 text-red-600 dark:text-red-400 flex-shrink-0 mt-0.5" />
                <div>
                  <p className="font-medium text-red-900 dark:text-red-300">Failed to create receipt</p>
                  <p className="text-sm text-red-700 dark:text-red-400 mt-1">
                    {createMutation.error instanceof Error ? createMutation.error.message : 'Please try again'}
                  </p>
                </div>
              </div>
            )}

            {/* Actions */}
            <div className="flex gap-3 pt-4">
              <button
                type="button"
                onClick={() => router.push('/receipts')}
                className="flex-1 px-6 py-3 border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 font-medium transition"
                disabled={createMutation.isPending}
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={createMutation.isPending}
                className="flex-1 px-6 py-3 bg-[#007AFF] dark:bg-[#3b82f6] text-white rounded-lg hover:bg-[#0062CC] dark:hover:bg-[#2563eb] font-medium transition disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
              >
                {createMutation.isPending ? (
                  <>
                    <Loader2 className="w-5 h-5 animate-spin" />
                    Creating...
                  </>
                ) : (
                  <>
                    <CheckCircle className="w-5 h-5" />
                    Create Receipt
                  </>
                )}
              </button>
            </div>
          </form>
        </div>
      </div>
    </DashboardLayout>
  );
}
