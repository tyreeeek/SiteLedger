'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import DashboardLayout from '@/components/dashboard-layout';
import AuthService from '@/lib/auth';
import { ArrowLeft, ChevronDown, ChevronUp } from 'lucide-react';

interface FAQItem {
  question: string;
  answer: string;
  category: string;
}

const faqs: FAQItem[] = [
  // Getting Started
  {
    category: 'Getting Started',
    question: 'How do I create my first job?',
    answer: 'Navigate to the Jobs page and click "Create Job". Fill in the job name, client information, project value, and other details. You can then assign workers and start tracking expenses and time.'
  },
  {
    category: 'Getting Started',
    question: 'How do I invite workers to my team?',
    answer: 'Go to the Workers page and click "Add Worker". Enter their name, email, and hourly rate. They\'ll receive an invitation to join your team and can start logging hours immediately.'
  },
  {
    category: 'Getting Started',
    question: 'What\'s the difference between Owner and Worker roles?',
    answer: 'Owners have full access to manage jobs, workers, financials, and settings. Workers can log hours, submit receipts, and view their assigned jobs. You can customize worker permissions in Settings > Roles & Permissions.'
  },
  
  // Jobs & Projects
  {
    category: 'Jobs & Projects',
    question: 'How is job profit calculated?',
    answer: 'Profit = Project Value - Labor Cost - Receipt Expenses. Labor cost is calculated from timesheet hours × hourly rates. Receipt expenses are all receipts linked to the job.'
  },
  {
    category: 'Jobs & Projects',
    question: 'Can I track partial payments from clients?',
    answer: 'Yes! When creating or editing a job, enter the "Amount Paid" field. The system automatically calculates the remaining balance (Project Value - Amount Paid) and shows payment progress.'
  },
  {
    category: 'Jobs & Projects',
    question: 'How do I mark a job as complete?',
    answer: 'On the job details page, change the status to "Completed". You can also archive old jobs to keep your active jobs list clean while preserving all data.'
  },
  {
    category: 'Jobs & Projects',
    question: 'Can I duplicate a job for recurring projects?',
    answer: 'While we don\'t have a duplicate feature yet, you can create a new job and manually copy the details. This feature is coming soon!'
  },
  
  // Receipts & Expenses
  {
    category: 'Receipts & Expenses',
    question: 'How does AI receipt scanning work?',
    answer: 'Take a photo of your receipt, and our AI automatically extracts the vendor name, amount, and date. You can review and edit the details before saving. Enable auto-fill in Settings > AI Automation.'
  },
  {
    category: 'Receipts & Expenses',
    question: 'Can I link receipts to specific jobs?',
    answer: 'Yes! When adding a receipt, select the job from the dropdown. The receipt amount will automatically be deducted from that job\'s profit calculation.'
  },
  {
    category: 'Receipts & Expenses',
    question: 'What happens if I delete a receipt?',
    answer: 'Deleting a receipt removes it from expense tracking and updates the job\'s profit calculation. The receipt image is permanently deleted and cannot be recovered.'
  },
  {
    category: 'Receipts & Expenses',
    question: 'Can I export receipts for tax purposes?',
    answer: 'Yes! Go to Settings > Export Data and select "Export Receipts (CSV)". Choose your date range and download all receipt data including vendor, amount, date, and notes.'
  },
  
  // Timesheets
  {
    category: 'Timesheets',
    question: 'How do workers log their hours?',
    answer: 'Workers can clock in/out in real-time or manually enter their hours. Go to Timesheets > Create and select the job, date, and hours worked. GPS location is automatically recorded for clock-in/out.'
  },
  {
    category: 'Timesheets',
    question: 'Do I need to approve timesheets?',
    answer: 'You can enable timesheet approval in Settings > Roles & Permissions. When enabled, all worker timesheets require owner approval before counting toward labor costs and payroll.'
  },
  {
    category: 'Timesheets',
    question: 'How are overtime hours calculated?',
    answer: 'Currently, all hours are calculated at the worker\'s standard hourly rate. Overtime rules and differential rates are coming in a future update.'
  },
  {
    category: 'Timesheets',
    question: 'Can I edit or delete a timesheet entry?',
    answer: 'Yes, owners can edit or delete any timesheet. Workers can only edit their own entries before approval. After approval, only owners can make changes.'
  },
  
  // Workers
  {
    category: 'Workers',
    question: 'How do I set different pay rates for workers?',
    answer: 'When adding or editing a worker, enter their hourly rate. Each worker can have a different rate, which is used to calculate labor costs and payroll automatically.'
  },
  {
    category: 'Workers',
    question: 'Can workers see other workers\' information?',
    answer: 'By default, workers can only see their own hours and earnings. You can customize this in Settings > Roles & Permissions by toggling "View Reports".'
  },
  {
    category: 'Workers',
    question: 'How do I deactivate a worker without deleting them?',
    answer: 'On the Workers page, click the worker\'s name and change their status to "Inactive". This preserves all their historical data while preventing new time entries.'
  },
  
  // AI Features
  {
    category: 'AI Features',
    question: 'What are AI Thresholds?',
    answer: 'AI Thresholds control how confident the AI must be before auto-filling data. Set the confidence level (default 85%), max daily hours alerts, and budget warning thresholds in Settings > AI Thresholds.'
  },
  {
    category: 'AI Features',
    question: 'What\'s the difference between Manual, Assist, and Auto-Pilot modes?',
    answer: 'Manual: AI only suggests, never changes data. Assist: AI auto-fills but requires your approval. Auto-Pilot: AI applies changes automatically. Configure in Settings > AI Automation.'
  },
  {
    category: 'AI Features',
    question: 'How do I get AI insights about my business?',
    answer: 'AI Insights analyze your jobs, expenses, and time data to provide recommendations. Add more data (jobs, receipts, timesheets) to unlock insights in Settings > AI Insights.'
  },
  {
    category: 'AI Features',
    question: 'Can I turn off AI features?',
    answer: 'Yes! Set AI Automation to "Manual" mode and disable all feature toggles. You can still use the app fully with manual data entry.'
  },
  
  // Billing
  {
    category: 'Billing',
    question: 'How much does SiteLedger cost?',
    answer: 'Contact our sales team for pricing details. We offer flexible plans for teams of all sizes, from solo contractors to large construction companies.'
  },
  {
    category: 'Billing',
    question: 'Is there a free trial?',
    answer: 'Yes! New users get a 14-day free trial with full access to all features. No credit card required to start.'
  },
  {
    category: 'Billing',
    question: 'Can I export my data if I cancel?',
    answer: 'Absolutely! Go to Settings > Export Data to download all your jobs, receipts, and timesheets as CSV files before canceling your subscription.'
  }
];

export default function FAQ() {
  const router = useRouter();
  const [openIndex, setOpenIndex] = useState<number | null>(null);
  const [selectedCategory, setSelectedCategory] = useState<string>('All');

  useEffect(() => {
    if (!AuthService.isAuthenticated()) {
      router.push('/auth/signin');
    }
  }, []);

  const categories = ['All', ...Array.from(new Set(faqs.map(faq => faq.category)))];
  const filteredFaqs = selectedCategory === 'All' 
    ? faqs 
    : faqs.filter(faq => faq.category === selectedCategory);

  const toggleFAQ = (index: number) => {
    setOpenIndex(openIndex === index ? null : index);
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
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Frequently Asked Questions</h1>
        </div>

        {/* Category Filter */}
        <div className="bg-white rounded-xl border border-gray-200 p-4 shadow-sm">
          <div className="flex flex-wrap gap-2">
            {categories.map((category) => (
              <button
                key={category}
                onClick={() => setSelectedCategory(category)}
                className={`px-4 py-2 rounded-lg font-medium transition ${
                  selectedCategory === category
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                {category}
              </button>
            ))}
          </div>
        </div>

        {/* FAQ Items */}
        <div className="space-y-3">
          {filteredFaqs.map((faq, index) => (
            <div
              key={index}
              className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden"
            >
              <button
                onClick={() => toggleFAQ(index)}
                className="w-full flex items-center justify-between p-6 text-left hover:bg-gray-50 transition"
              >
                <div className="flex-1">
                  <span className="text-xs font-semibold text-blue-600 uppercase tracking-wide mb-2 block">
                    {faq.category}
                  </span>
                  <h3 className="text-lg font-semibold text-gray-900 dark:text-white">{faq.question}</h3>
                </div>
                {openIndex === index ? (
                  <ChevronUp className="w-6 h-6 text-gray-400 flex-shrink-0 ml-4" />
                ) : (
                  <ChevronDown className="w-6 h-6 text-gray-400 flex-shrink-0 ml-4" />
                )}
              </button>
              {openIndex === index && (
                <div className="px-6 pb-6">
                  <p className="text-gray-700 leading-relaxed">{faq.answer}</p>
                </div>
              )}
            </div>
          ))}
        </div>

        {/* Contact Support */}
        <div className="bg-gradient-to-br from-blue-50 to-purple-50 rounded-xl border border-gray-200 p-6 text-center">
          <h3 className="text-xl font-bold text-gray-900 mb-2">Still have questions?</h3>
          <p className="text-gray-600 mb-4">
            Can't find the answer you're looking for? Our support team is here to help.
          </p>
          <button
            onClick={() => router.push('/support')}
            className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition font-medium"
          >
            Contact Support
          </button>
        </div>
      </div>
    </DashboardLayout>
  );
}
