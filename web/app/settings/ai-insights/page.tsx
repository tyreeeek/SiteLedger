'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import DashboardLayout from '@/components/dashboard-layout';
import AuthService from '@/lib/auth';
import { ArrowLeft, Lightbulb, Sparkles, TrendingUp, AlertCircle } from 'lucide-react';

interface Insight {
  category: string;
  title: string;
  description: string;
  priority: 'high' | 'medium' | 'low';
  recommendation?: string;
}

export default function AIInsights() {
  const router = useRouter();
  const [insights, setInsights] = useState<Insight[]>([]);
  const [isGenerating, setIsGenerating] = useState(false);
  const [message, setMessage] = useState('');

  useEffect(() => {
    if (!AuthService.isAuthenticated()) {
      router.push('/auth/signin');
    }
  }, []);

  const handleGenerateInsights = async () => {
    setIsGenerating(true);
    setMessage('');
    
    try {
      const token = localStorage.getItem('accessToken');
      if (!token) {
        setMessage('Please sign in to generate insights');
        return;
      }
      
      console.log('Generating AI insights...');
      const response = await fetch('https://api.siteledger.ai/api/ai-insights/generate', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      console.log('AI insights response status:', response.status);

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({ error: 'Unknown error' }));
        console.error('AI insights error:', errorData);
        throw new Error(errorData.error || `Failed with status ${response.status}`);
      }

      const data = await response.json();
      console.log('AI insights data:', data);
      
      // Transform the response into Insight objects
      if (data.insights && Array.isArray(data.insights)) {
        // Map backend insights to frontend format
        const mappedInsights = data.insights.map((insight: any) => ({
          category: insight.severity || 'info',
          title: insight.title,
          description: insight.description,
          priority: insight.severity === 'critical' ? 'high' : insight.severity === 'warning' ? 'medium' : 'low',
          recommendation: insight.actionItems ? insight.actionItems.join('; ') : undefined
        }));
        setInsights(mappedInsights);
        setMessage(`Generated ${mappedInsights.length} AI insights successfully!`);
      } else if (data.message) {
        setMessage(data.message);
      } else {
        setMessage('No insights generated. Try adding more data to your jobs.');
      }
      
      setTimeout(() => setMessage(''), 5000);
    } catch (error: any) {
      console.error('Generate insights error:', error);
      setMessage(error.message || 'Failed to generate insights. Please try again.');
    } finally {
      setIsGenerating(false);
    }
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'high':
        return 'bg-red-100 text-red-800 border-red-200';
      case 'medium':
        return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'low':
        return 'bg-blue-100 text-blue-800 border-blue-200';
      default:
        return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  return (
    <DashboardLayout>
      <div className="max-w-4xl mx-auto space-y-6">
        <div className="flex items-center gap-4">
          <button
            onClick={() => router.back()}
            className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition"
            aria-label="Go back"
          >
            <ArrowLeft className="w-6 h-6 text-gray-900 dark:text-white" />
          </button>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">AI Insights</h1>
        </div>

        {/* Generate Button */}
        <button
          onClick={handleGenerateInsights}
          disabled={isGenerating}
          className="w-full py-4 bg-gradient-to-r from-blue-600 to-purple-600 text-white rounded-xl hover:from-blue-700 hover:to-purple-700 transition flex items-center justify-center gap-2 font-medium shadow-lg disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <Sparkles className="w-5 h-5" />
          {isGenerating ? 'Generating Insights...' : 'Generate AI Insights'}
        </button>

        {/* Success/Error Message */}
        {message && (
          <div className={`p-4 rounded-xl ${message.includes('Failed') ? 'bg-red-50 text-red-800 border border-red-200' : 'bg-green-50 text-green-800 border border-green-200'}`}>
            {message}
          </div>
        )}

        {/* Insights Display */}
        {insights.length > 0 && (
          <div className="space-y-4">
            <h2 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
              <TrendingUp className="w-6 h-6 text-blue-600" />
              Your AI Insights
            </h2>
            {insights.map((insight, index) => (
              <div key={index} className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">
                <div className="flex items-start justify-between mb-3">
                  <h3 className="text-lg font-bold text-gray-900">{insight.title}</h3>
                  <span className={`px-3 py-1 rounded-full text-xs font-medium border ${getPriorityColor(insight.priority)}`}>
                    {insight.priority.toUpperCase()}
                  </span>
                </div>
                <p className="text-gray-700 mb-3">{insight.description}</p>
                {insight.recommendation && (
                  <div className="bg-blue-50 border border-blue-200 rounded-lg p-3 flex items-start gap-2">
                    <AlertCircle className="w-5 h-5 text-blue-600 mt-0.5 flex-shrink-0" />
                    <div>
                      <p className="text-sm font-medium text-blue-900">Recommendation</p>
                      <p className="text-sm text-blue-800">{insight.recommendation}</p>
                    </div>
                  </div>
                )}
              </div>
            ))}
          </div>
        )}

        {/* Empty State */}
        {insights.length === 0 && !isGenerating && (
          <div className="bg-gradient-to-br from-blue-50 to-purple-50 rounded-xl border border-gray-200 p-12 shadow-sm">
            <div className="flex flex-col items-center justify-center text-center space-y-4">
              <div className="p-6 bg-yellow-100 rounded-full">
                <Lightbulb className="w-16 h-16 text-yellow-600" />
              </div>
              <h2 className="text-2xl font-bold text-gray-900 dark:text-white">No Insights Yet</h2>
              <p className="text-gray-600 max-w-md">
                Click "Generate AI Insights" above to get AI-powered recommendations about your business.
                The AI will analyze your jobs, receipts, and timesheets to provide personalized insights.
              </p>
            </div>
          </div>
        )}

        {/* Info Card */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">
          <h3 className="text-lg font-bold text-gray-900 mb-3">What are AI Insights?</h3>
          <ul className="space-y-3 text-gray-700">
            <li className="flex items-start gap-3">
              <svg className="w-5 h-5 text-blue-600 mt-0.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
              </svg>
              <span>Profit trends and job performance analysis</span>
            </li>
            <li className="flex items-start gap-3">
              <svg className="w-5 h-5 text-blue-600 mt-0.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
              </svg>
              <span>Worker productivity and labor cost optimization</span>
            </li>
            <li className="flex items-start gap-3">
              <svg className="w-5 h-5 text-blue-600 mt-0.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
              </svg>
              <span>Expense patterns and budget recommendations</span>
            </li>
            <li className="flex items-start gap-3">
              <svg className="w-5 h-5 text-blue-600 mt-0.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
              </svg>
              <span>Cash flow predictions and payment reminders</span>
            </li>
            <li className="flex items-start gap-3">
              <svg className="w-5 h-5 text-blue-600 mt-0.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
              </svg>
              <span>Anomaly detection for unusual expenses or hours</span>
            </li>
          </ul>
        </div>
      </div>
    </DashboardLayout>
  );
}
