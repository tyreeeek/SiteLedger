'use client';

import { useState, useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import DashboardLayout from '@/components/dashboard-layout';
import AuthService from '@/lib/auth';
import APIService from '@/lib/api';
import { ArrowLeft, Users, Edit, Briefcase, CreditCard, DollarSign, TrendingUp, Receipt, Clock, FileText, Loader2, Sparkles } from 'lucide-react';

type Tab = 'ai-insights' | 'receipts' | 'timesheets' | 'documents';

export default function JobDetails() {
  const router = useRouter();
  const params = useParams();
  const jobId = params?.id as string;
  
  const [activeTab, setActiveTab] = useState<Tab>('ai-insights');
  const [job, setJob] = useState<any>(null);
  const [receipts, setReceipts] = useState<any[]>([]);
  const [timesheets, setTimesheets] = useState<any[]>([]);
  const [documents, setDocuments] = useState<any[]>([]);
  const [workers, setWorkers] = useState<any[]>([]);
  const [assignedWorkers, setAssignedWorkers] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [showAssignModal, setShowAssignModal] = useState(false);
  const [selectedWorkerIds, setSelectedWorkerIds] = useState<string[]>([]);
  const [aiInsights, setAiInsights] = useState<any>(null);
  const [loadingInsights, setLoadingInsights] = useState(false);

  useEffect(() => {
    if (!AuthService.isAuthenticated()) {
      router.push('/auth/signin');
      return;
    }
    if (jobId) {
      loadJobData();
    }
  }, [jobId]);

  const loadJobData = async () => {
    setIsLoading(true);
    try {
      const [jobData, receiptsData, timesheetsData, documentsData, workersData] = await Promise.all([
        APIService.fetchJobs().then(jobs => jobs.find((j: any) => j.id === jobId)),
        APIService.fetchReceipts(),
        APIService.fetchTimesheets(),
        APIService.fetchDocuments(),
        APIService.fetchWorkers()
      ]);

      setJob(jobData);
      setReceipts(receiptsData.filter((r: any) => r.jobID === jobId));
      setTimesheets(timesheetsData.filter((t: any) => t.jobID === jobId));
      setDocuments(documentsData.filter((d: any) => d.jobID === jobId));
      setWorkers(workersData);
      
      // Get assigned workers from job data
      if (jobData && jobData.assignedWorkers) {
        const assigned = workersData.filter((w: any) => 
          jobData.assignedWorkers.includes(w.id)
        );
        setAssignedWorkers(assigned);
        setSelectedWorkerIds(assigned.map((w: any) => w.id));
      }
    } catch (error) {
      // Silently fail - page will show loading state
    } finally {
      setIsLoading(false);
    }
  };

  if (isLoading || !job) {
    return (
      <DashboardLayout>
        <div className="min-h-screen flex items-center justify-center">
          <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
        </div>
      </DashboardLayout>
    );
  }

  // USE EXACT BACKEND CALCULATIONS - NO CLIENT-SIDE ESTIMATION
  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(value);
  };

  // Backend provides exact calculations - use them directly
  const laborCost = job.totalCost || 0;  // Backend calculates this
  const profit = job.profit || 0;  // Backend calculates this
  const balanceDue = job.remainingBalance || 0;  // Backend calculates this
  const paymentProgress = job.projectValue > 0 ? ((job.amountPaid || 0) / job.projectValue) * 100 : 0;

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'bg-green-100 text-green-800';
      case 'completed': return 'bg-blue-100 text-blue-800';
      case 'on-hold': return 'bg-yellow-100 text-yellow-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const handleAssignWorkers = async () => {
    try {
      // Update job's assignedWorkers array directly
      const updatedJob = {
        ...job,
        assignedWorkers: selectedWorkerIds
      };
      
      await APIService.updateJob(jobId, updatedJob);
      
      // Reload data
      await loadJobData();
      setShowAssignModal(false);
    } catch (error) {
      // Silently fail - modal stays open for retry
    }
  };

  const toggleWorkerSelection = (workerId: string) => {
    setSelectedWorkerIds(prev => 
      prev.includes(workerId) 
        ? prev.filter(id => id !== workerId)
        : [...prev, workerId]
    );
  };

  return (
    <DashboardLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center gap-4">
          <button
            onClick={() => router.push('/jobs')}
            className="p-2 hover:bg-gray-100 rounded-lg transition"
            aria-label="Go back to jobs list"
            title="Back to jobs"
          >
            <ArrowLeft className="w-6 h-6 text-gray-900" />
          </button>
          <div className="flex-1">
            <h1 className="text-3xl font-bold text-gray-900">Job Details</h1>
          </div>
          <button
            onClick={() => router.push(`/jobs/${jobId}/edit`)}
            className="flex items-center gap-2 px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition"
            aria-label="Assign workers to job"
            title="Assign workers"
          >
            <Users className="w-5 h-5" />
          </button>
        </div>

        {/* Job Header Card */}
        <div className="bg-gradient-to-r from-gray-800 to-gray-900 rounded-xl p-6 text-white shadow-lg">
          <div className="flex items-start justify-between mb-4">
            <div className="flex-1">
              <h2 className="text-3xl font-bold mb-2">{job.jobName}</h2>
              <p className="text-gray-300 text-lg">{job.clientName}</p>
            </div>
            <span className={`px-4 py-2 rounded-full text-sm font-medium capitalize ${getStatusColor(job.status)} !text-gray-900`}>
              {job.status}
            </span>
          </div>
          
          {job.location && (
            <div className="flex items-center gap-2 text-gray-300">
              <span className="text-sm">📍 {job.location}</span>
            </div>
          )}

          {job.startDate && (
            <div className="mt-2 text-sm text-gray-400">
              Start: {new Date(job.startDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
            </div>
          )}
        </div>

        {/* Financial Cards Grid */}
        <div className="grid grid-cols-2 lg:grid-cols-3 gap-4">
          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-4 shadow-sm">
            <div className="flex items-center gap-3 mb-2">
              <div className="p-2 bg-blue-100 dark:bg-blue-900 rounded-lg">
                <Briefcase className="w-5 h-5 text-blue-600 dark:text-blue-400" />
              </div>
              <span className="text-sm text-gray-600 dark:text-gray-400">Project Value</span>
            </div>
            <p className="text-2xl font-bold text-gray-900 dark:text-white">{formatCurrency(job.projectValue || 0)}</p>
          </div>

          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-4 shadow-sm">
            <div className="flex items-center gap-3 mb-2">
              <div className="p-2 bg-green-100 dark:bg-green-900 rounded-lg">
                <CreditCard className="w-5 h-5 text-green-600 dark:text-green-400" />
              </div>
              <span className="text-sm text-gray-600 dark:text-gray-400">Payments Received</span>
            </div>
            <p className="text-2xl font-bold text-gray-900 dark:text-white">{formatCurrency(job.amountPaid || 0)}</p>
          </div>

          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-4 shadow-sm">
            <div className="flex items-center gap-3 mb-2">
              <div className="p-2 bg-orange-100 dark:bg-orange-900 rounded-lg">
                <Users className="w-5 h-5 text-orange-600 dark:text-orange-400" />
              </div>
              <span className="text-sm text-gray-600 dark:text-gray-400">Total Cost</span>
            </div>
            <p className="text-2xl font-bold text-gray-900 dark:text-white">{formatCurrency(laborCost)}</p>
          </div>

          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-4 shadow-sm">
            <div className="flex items-center gap-3 mb-2">
              <div className="p-2 bg-yellow-100 dark:bg-yellow-900 rounded-lg">
                <DollarSign className="w-5 h-5 text-yellow-600 dark:text-yellow-400" />
              </div>
              <span className="text-sm text-gray-600 dark:text-gray-400">Balance Due</span>
            </div>
            <p className="text-2xl font-bold text-gray-900 dark:text-white">{formatCurrency(balanceDue)}</p>
          </div>

          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-4 shadow-sm">
            <div className="flex items-center gap-3 mb-2">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900 rounded-lg">
                <TrendingUp className="w-5 h-5 text-emerald-600 dark:text-emerald-400" />
              </div>
              <span className="text-sm text-gray-600 dark:text-gray-400">Profit</span>
            </div>
            <p className={`text-2xl font-bold ${profit >= 0 ? 'text-emerald-600 dark:text-emerald-400' : 'text-red-600 dark:text-red-400'}`}>
              {formatCurrency(profit)}
            </p>
          </div>
        </div>

        {/* Payment Progress */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Payment Progress</h3>
            <span className="text-2xl font-bold text-blue-600 dark:text-blue-400">{Math.round(paymentProgress)}%</span>
          </div>
          <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-4 overflow-hidden">
            <div
              className="h-full bg-gradient-to-r from-blue-500 to-blue-600 transition-all duration-500"
              style={{ width: `${Math.min(paymentProgress, 100)}%` }}
            />
          </div>
          <p className="text-sm text-gray-600 dark:text-gray-400 mt-2">
            Remaining: {formatCurrency(balanceDue)}
          </p>
        </div>

        {/* Edit Job Button */}
        <button
          onClick={() => router.push(`/jobs/${jobId}/edit`)}
          className="w-full py-4 bg-gray-100 text-gray-700 rounded-xl hover:bg-gray-200 transition flex items-center justify-center gap-2 font-medium"
        >
          <Edit className="w-5 h-5" />
          Edit Job Details
        </button>

        {/* Assigned Workers Section */}
        <div className="bg-white rounded-xl border border-gray-200 p-6 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
              <Users className="w-5 h-5" />
              Assigned Workers
            </h3>
            <button
              onClick={() => setShowAssignModal(true)}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition text-sm font-medium"
            >
              Assign Workers
            </button>
          </div>
          
          {assignedWorkers.length > 0 ? (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              {assignedWorkers.map((worker) => (
                <div
                  key={worker.id}
                  className="flex items-center gap-3 p-3 border border-gray-200 rounded-lg"
                >
                  <div className="p-2 bg-blue-100 rounded-lg">
                    <Users className="w-4 h-4 text-blue-600" />
                  </div>
                  <div className="flex-1">
                    <p className="font-medium text-gray-900">{worker.name}</p>
                    <p className="text-sm text-gray-600">${worker.hourlyRate}/hr</p>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-gray-500 text-center py-4">No workers assigned to this job</p>
          )}
        </div>

        {/* Worker Assignment Modal */}
        {showAssignModal && (
          <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-xl max-w-lg w-full p-6 shadow-2xl max-h-[80vh] overflow-y-auto">
              <h3 className="text-xl font-bold text-gray-900 mb-4">Assign Workers</h3>
              
              <div className="space-y-2 mb-6">
                {workers.map((worker) => (
                  <label
                    key={worker.id}
                    className="flex items-center gap-3 p-3 border border-gray-200 rounded-lg hover:bg-gray-50 cursor-pointer transition"
                  >
                    <input
                      type="checkbox"
                      checked={selectedWorkerIds.includes(worker.id)}
                      onChange={() => toggleWorkerSelection(worker.id)}
                      className="w-5 h-5 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
                    />
                    <div className="flex-1">
                      <p className="font-medium text-gray-900">{worker.name}</p>
                      <p className="text-sm text-gray-600">{worker.email}</p>
                    </div>
                    <span className="text-sm font-medium text-gray-600">
                      ${worker.hourlyRate}/hr
                    </span>
                  </label>
                ))}
              </div>
              
              <div className="flex gap-3">
                <button
                  onClick={() => {
                    setShowAssignModal(false);
                    setSelectedWorkerIds(assignedWorkers.map(w => w.id));
                  }}
                  className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition"
                >
                  Cancel
                </button>
                <button
                  onClick={handleAssignWorkers}
                  className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
                >
                  Save
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Tabs */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm overflow-hidden">
          <div className="flex border-b border-gray-200 dark:border-gray-700">
            <button
              onClick={() => setActiveTab('ai-insights')}
              className={`flex-1 py-4 px-6 font-medium transition ${
                activeTab === 'ai-insights'
                  ? 'bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 border-b-2 border-blue-600'
                  : 'text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-700'
              }`}
            >
              <div className="flex items-center justify-center gap-2">
                <Sparkles className="w-4 h-4" />
                AI Insights
              </div>
            </button>
            <button
              onClick={() => setActiveTab('receipts')}
              className={`flex-1 py-4 px-6 font-medium transition ${
                activeTab === 'receipts'
                  ? 'bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 border-b-2 border-blue-600'
                  : 'text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-700'
              }`}
            >
              Receipts ({receipts.length})
            </button>
            <button
              onClick={() => setActiveTab('timesheets')}
              className={`flex-1 py-4 px-6 font-medium transition ${
                activeTab === 'timesheets'
                  ? 'bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 border-b-2 border-blue-600'
                  : 'text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-700'
              }`}
            >
              Timesheets ({timesheets.length})
            </button>
            <button
              onClick={() => setActiveTab('documents')}
              className={`flex-1 py-4 px-6 font-medium transition ${
                activeTab === 'documents'
                  ? 'bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 border-b-2 border-blue-600'
                  : 'text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-700'
              }`}
            >
              Documents ({documents.length})
            </button>
          </div>

          <div className="p-6">
            {activeTab === 'ai-insights' && (
              <div className="space-y-4">
                <div className="flex items-center justify-between mb-4">
                  <h4 className="font-semibold text-gray-900 dark:text-white">AI-Generated Insights</h4>
                  <button
                    onClick={async () => {
                      setLoadingInsights(true);
                      try {
                        const insights = await APIService.generateAIInsights(jobId);
                        setAiInsights(insights);
                      } catch (error) {
                        console.error('Failed to generate insights:', error);
                      } finally {
                        setLoadingInsights(false);
                      }
                    }}
                    disabled={loadingInsights}
                    className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition disabled:opacity-50 flex items-center gap-2"
                  >
                    {loadingInsights ? (
                      <>
                        <Loader2 className="w-4 h-4 animate-spin" />
                        Generating...
                      </>
                    ) : (
                      <>
                        <Sparkles className="w-4 h-4" />
                        Generate Insights
                      </>
                    )}
                  </button>
                </div>
                
                {aiInsights ? (
                  <div className="space-y-4">
                    {aiInsights.summary && (
                      <div className="p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
                        <h5 className="font-semibold text-blue-900 dark:text-blue-300 mb-2">Summary</h5>
                        <p className="text-blue-800 dark:text-blue-200">{aiInsights.summary}</p>
                      </div>
                    )}
                    {aiInsights.recommendations && aiInsights.recommendations.length > 0 && (
                      <div className="p-4 bg-green-50 dark:bg-green-900/20 rounded-lg border border-green-200 dark:border-green-800">
                        <h5 className="font-semibold text-green-900 dark:text-green-300 mb-2">Recommendations</h5>
                        <ul className="space-y-2">
                          {aiInsights.recommendations.map((rec: string, idx: number) => (
                            <li key={idx} className="text-green-800 dark:text-green-200 flex items-start gap-2">
                              <span className="text-green-600 mt-1">•</span>
                              <span>{rec}</span>
                            </li>
                          ))}
                        </ul>
                      </div>
                    )}
                    {aiInsights.risks && aiInsights.risks.length > 0 && (
                      <div className="p-4 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg border border-yellow-200 dark:border-yellow-800">
                        <h5 className="font-semibold text-yellow-900 dark:text-yellow-300 mb-2">Risks & Warnings</h5>
                        <ul className="space-y-2">
                          {aiInsights.risks.map((risk: string, idx: number) => (
                            <li key={idx} className="text-yellow-800 dark:text-yellow-200 flex items-start gap-2">
                              <span className="text-yellow-600 mt-1">⚠</span>
                              <span>{risk}</span>
                            </li>
                          ))}
                        </ul>
                      </div>
                    )}
                  </div>
                ) : (
                  <div className="text-center py-12">
                    <Sparkles className="w-16 h-16 text-gray-400 dark:text-gray-500 mx-auto mb-4" />
                    <p className="text-gray-600 dark:text-gray-400 mb-2">No AI insights generated yet</p>
                    <p className="text-sm text-gray-500 dark:text-gray-500">Click "Generate Insights" to analyze this job with AI</p>
                  </div>
                )}
                
                {job.notes && (
                  <div className="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                    <h4 className="font-semibold text-gray-900 dark:text-white mb-2">Job Notes</h4>
                    <p className="text-gray-600 dark:text-gray-400">{job.notes}</p>
                  </div>
                )}
              </div>
            )}

            {activeTab === 'receipts' && (
              <div className="space-y-3">
                {receipts.length > 0 ? (
                  receipts.map((receipt) => (
                    <div
                      key={receipt.id}
                      className="flex items-center justify-between p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition cursor-pointer"
                      onClick={() => router.push(`/receipts/${receipt.id}`)}
                    >
                      <div className="flex items-center gap-3">
                        <Receipt className="w-5 h-5 text-gray-400" />
                        <div>
                          <p className="font-medium text-gray-900">{receipt.vendor || 'Receipt'}</p>
                          <p className="text-sm text-gray-500">
                            {receipt.date ? new Date(receipt.date).toLocaleDateString() : 'No date'}
                          </p>
                        </div>
                      </div>
                      <span className="text-lg font-semibold text-gray-900">
                        ${receipt.amount?.toFixed(2) || '0.00'}
                      </span>
                    </div>
                  ))
                ) : (
                  <p className="text-gray-500 text-center py-8">No receipts for this job</p>
                )}
              </div>
            )}

            {activeTab === 'timesheets' && (
              <div className="space-y-3">
                {timesheets.length > 0 ? (
                  timesheets.map((timesheet) => {
                    const worker = workers.find(w => w.id === timesheet.userID);
                    return (
                      <div
                        key={timesheet.id}
                        className="flex items-center justify-between p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition"
                      >
                        <div className="flex items-center gap-3">
                          <Clock className="w-5 h-5 text-gray-400" />
                          <div>
                            <p className="font-medium text-gray-900">{worker?.name || 'Worker'}</p>
                            <p className="text-sm text-gray-500">
                              {timesheet.date ? new Date(timesheet.date).toLocaleDateString() : 'No date'}
                            </p>
                          </div>
                        </div>
                        <div className="text-right">
                          <p className="font-semibold text-gray-900">{timesheet.hours?.toFixed(2) || '0.00'} hrs</p>
                          <p className="text-sm text-gray-500">
                            ${((timesheet.hours || 0) * (worker?.hourlyRate || 0)).toFixed(2)}
                          </p>
                        </div>
                      </div>
                    );
                  })
                ) : (
                  <p className="text-gray-500 text-center py-8">No timesheets for this job</p>
                )}
              </div>
            )}

            {activeTab === 'documents' && (
              <div className="space-y-3">
                {documents.length > 0 ? (
                  documents.map((doc) => (
                    <div
                      key={doc.id}
                      className="flex items-center justify-between p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition cursor-pointer"
                      onClick={() => window.open(doc.fileURL, '_blank')}
                    >
                      <div className="flex items-center gap-3">
                        <FileText className="w-5 h-5 text-gray-400" />
                        <div>
                          <p className="font-medium text-gray-900">{doc.title || 'Document'}</p>
                          <p className="text-sm text-gray-500">
                            {doc.fileType && (
                              <span className="capitalize">{doc.fileType}</span>
                            )}
                          </p>
                        </div>
                      </div>
                      <span className="text-blue-600 hover:text-blue-700">View</span>
                    </div>
                  ))
                ) : (
                  <p className="text-gray-500 text-center py-8">No documents for this job</p>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
}
