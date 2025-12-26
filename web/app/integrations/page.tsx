'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import DashboardLayout from '@/components/dashboard-layout';
import AuthService from '@/lib/auth';
import { ArrowLeft, ExternalLink } from 'lucide-react';

const integrations = [
  {
    name: 'QuickBooks',
    description: 'Sync jobs, expenses, and invoices with QuickBooks Online',
    logo: '💼',
    color: 'from-green-500 to-green-600'
  },
  {
    name: 'Stripe',
    description: 'Accept client payments and track transactions',
    logo: '💳',
    color: 'from-purple-500 to-purple-600'
  },
  {
    name: 'Square',
    description: 'Process payments and manage point-of-sale transactions',
    logo: '⬜',
    color: 'from-blue-500 to-blue-600'
  },
  {
    name: 'Xero',
    description: 'Connect accounting data and automate bookkeeping',
    logo: '📊',
    color: 'from-cyan-500 to-cyan-600'
  },
  {
    name: 'Mailchimp',
    description: 'Send client updates and marketing campaigns',
    logo: '✉️',
    color: 'from-yellow-500 to-yellow-600'
  },
  {
    name: 'Zapier',
    description: 'Connect with 5000+ apps and automate workflows',
    logo: '⚡',
    color: 'from-orange-500 to-orange-600'
  },
  {
    name: 'Google Drive',
    description: 'Backup documents and photos to Google Drive',
    logo: '📁',
    color: 'from-blue-400 to-blue-500'
  },
  {
    name: 'Dropbox',
    description: 'Automatically sync files to Dropbox',
    logo: '📦',
    color: 'from-indigo-500 to-indigo-600'
  },
  {
    name: 'Slack',
    description: 'Get notifications and updates in Slack channels',
    logo: '💬',
    color: 'from-purple-400 to-purple-500'
  }
];

export default function Integrations() {
  const router = useRouter();

  useEffect(() => {
    if (!AuthService.isAuthenticated()) {
      router.push('/auth/signin');
    }
  }, []);

  return (
    <DashboardLayout>
      <div className="max-w-7xl mx-auto space-y-6">
        <div className="flex items-center gap-4">
          <button
            onClick={() => router.back()}
            className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition"
            aria-label="Go back"
          >
            <ArrowLeft className="w-6 h-6 text-gray-900 dark:text-white" />
          </button>
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Integrations</h1>
            <p className="text-gray-600 mt-1">Connect SiteLedger with your favorite tools</p>
          </div>
        </div>

        {/* Coming Soon Banner */}
        <div className="bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl p-8 text-white text-center shadow-lg">
          <div className="text-6xl mb-4">🚀</div>
          <h2 className="text-3xl font-bold mb-3">Integrations Coming Soon!</h2>
          <p className="text-lg text-blue-50 max-w-2xl mx-auto">
            We're working hard to bring you seamless integrations with the tools you already use. 
            Get notified when integrations launch by contacting our support team.
          </p>
        </div>

        {/* Integration Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {integrations.map((integration, index) => (
            <div
              key={index}
              className="bg-white rounded-xl border border-gray-200 p-6 shadow-sm hover:shadow-md transition"
            >
              <div className="flex items-start justify-between mb-4">
                <div className={`text-4xl w-16 h-16 bg-gradient-to-br ${integration.color} rounded-xl flex items-center justify-center text-white shadow-lg`}>
                  {integration.logo}
                </div>
                <span className="px-3 py-1 bg-yellow-100 text-yellow-800 text-xs font-semibold rounded-full">
                  Coming Soon
                </span>
              </div>
              <h3 className="text-xl font-bold text-gray-900 mb-2">{integration.name}</h3>
              <p className="text-gray-600 text-sm">{integration.description}</p>
            </div>
          ))}
        </div>

        {/* Request Integration */}
        <div className="bg-white rounded-xl border border-gray-200 p-8 text-center shadow-sm">
          <h3 className="text-2xl font-bold text-gray-900 mb-3">Need a specific integration?</h3>
          <p className="text-gray-600 mb-6 max-w-2xl mx-auto">
            Let us know which integrations are most important to your workflow. We prioritize based on user feedback.
          </p>
          <button
            onClick={() => router.push('/support')}
            className="inline-flex items-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition font-medium"
          >
            <ExternalLink className="w-5 h-5" />
            Request an Integration
          </button>
        </div>

        {/* Benefits */}
        <div className="bg-gradient-to-br from-purple-50 to-blue-50 rounded-xl border border-gray-200 p-8">
          <h3 className="text-2xl font-bold text-gray-900 mb-6 text-center">Why Integrations Matter</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="text-center">
              <div className="text-4xl mb-3">⚡</div>
              <h4 className="font-semibold text-gray-900 mb-2">Save Time</h4>
              <p className="text-sm text-gray-600">Automate data entry and eliminate duplicate work</p>
            </div>
            <div className="text-center">
              <div className="text-4xl mb-3">🔄</div>
              <h4 className="font-semibold text-gray-900 mb-2">Stay in Sync</h4>
              <p className="text-sm text-gray-600">Keep data consistent across all your tools</p>
            </div>
            <div className="text-center">
              <div className="text-4xl mb-3">📈</div>
              <h4 className="font-semibold text-gray-900 mb-2">Scale Faster</h4>
              <p className="text-sm text-gray-600">Focus on growth, not manual data management</p>
            </div>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
}
