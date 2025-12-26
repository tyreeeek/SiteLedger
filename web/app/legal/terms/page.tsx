'use client';

import { useRouter } from 'next/navigation';
import DashboardLayout from '@/components/dashboard-layout';
import { ArrowLeft } from 'lucide-react';

export default function TermsOfService() {
  const router = useRouter();

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
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Terms of Service</h1>
        </div>

        <div className="bg-white rounded-xl border border-gray-200 p-8 shadow-sm prose prose-blue max-w-none">
          <p className="text-sm text-gray-500 mb-6">Last Updated: December 21, 2024</p>

          <section className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">1. Acceptance of Terms</h2>
            <p className="text-gray-700 leading-relaxed mb-4">
              By accessing and using SiteLedger ("Service," "Platform," or "App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, you may not use our Service.
            </p>
            <p className="text-gray-700 leading-relaxed">
              These Terms constitute a legally binding agreement between you ("User," "you," or "your") and SiteLedger, Inc. ("Company," "we," "us," or "our").
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">2. Description of Service</h2>
            <p className="text-gray-700 leading-relaxed mb-4">
              SiteLedger is a contractor management platform that provides:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2">
              <li>Job and project tracking</li>
              <li>Receipt and expense management</li>
              <li>Timesheet and labor cost tracking</li>
              <li>Worker and team management</li>
              <li>Document storage and organization</li>
              <li>AI-powered features (OCR, insights, automation)</li>
              <li>Financial reporting and analytics</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">3. User Accounts</h2>
            
            <h3 className="text-xl font-semibold text-gray-900 mb-3">3.1 Account Creation</h3>
            <p className="text-gray-700 leading-relaxed mb-4">
              To use SiteLedger, you must create an account by providing accurate, complete, and current information. You are responsible for maintaining the confidentiality of your account credentials.
            </p>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">3.2 Account Eligibility</h3>
            <p className="text-gray-700 leading-relaxed mb-4">
              You must be at least 18 years old and legally capable of entering into binding contracts to use our Service.
            </p>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">3.3 Account Security</h3>
            <p className="text-gray-700 leading-relaxed mb-4">
              You are responsible for all activities under your account. Notify us immediately of any unauthorized access or security breach.
            </p>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">3.4 Account Termination</h3>
            <p className="text-gray-700 leading-relaxed">
              We reserve the right to suspend or terminate accounts that violate these Terms, engage in fraudulent activity, or pose security risks.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">4. Payment and Billing</h2>
            
            <h3 className="text-xl font-semibold text-gray-900 mb-3">4.1 Subscription Fees</h3>
            <p className="text-gray-700 leading-relaxed mb-4">
              Access to SiteLedger requires a paid subscription. Pricing is available on our website and subject to change with 30 days' notice.
            </p>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">4.2 Billing Cycle</h3>
            <p className="text-gray-700 leading-relaxed mb-4">
              Subscriptions are billed monthly or annually in advance. Your payment method will be automatically charged at the beginning of each billing cycle.
            </p>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">4.3 Free Trial</h3>
            <p className="text-gray-700 leading-relaxed mb-4">
              New users may receive a free trial period. After the trial ends, you will be charged unless you cancel before the trial expiration.
            </p>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">4.4 Refunds</h3>
            <p className="text-gray-700 leading-relaxed mb-4">
              Fees are non-refundable except as required by law or at our sole discretion. Contact support@siteledger.ai for refund requests.
            </p>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">4.5 Cancellation</h3>
            <p className="text-gray-700 leading-relaxed">
              You may cancel your subscription at any time. Cancellations take effect at the end of your current billing period. You retain access until that date.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">5. User Content and Data</h2>
            
            <h3 className="text-xl font-semibold text-gray-900 mb-3">5.1 Your Data</h3>
            <p className="text-gray-700 leading-relaxed mb-4">
              You retain ownership of all data, content, and information you upload to SiteLedger ("User Content"). By using our Service, you grant us a license to use, store, and process your User Content solely to provide our services.
            </p>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">5.2 Data Accuracy</h3>
            <p className="text-gray-700 leading-relaxed mb-4">
              You are responsible for the accuracy and legality of your User Content. We are not liable for errors, omissions, or unauthorized use of your data.
            </p>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">5.3 Data Export and Deletion</h3>
            <p className="text-gray-700 leading-relaxed">
              You may export your data at any time through Settings &gt; Export Data. Upon account termination, your data may be deleted after 30 days unless otherwise required by law.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">6. Prohibited Uses</h2>
            <p className="text-gray-700 leading-relaxed mb-4">
              You agree not to:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2">
              <li>Violate any laws, regulations, or third-party rights</li>
              <li>Use the Service for fraudulent or illegal activities</li>
              <li>Upload malicious code, viruses, or harmful content</li>
              <li>Reverse engineer, decompile, or attempt to extract source code</li>
              <li>Interfere with or disrupt the Service or servers</li>
              <li>Access another user's account without permission</li>
              <li>Scrape, copy, or harvest data using automated means</li>
              <li>Resell or redistribute the Service without authorization</li>
              <li>Impersonate any person or entity</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">7. Intellectual Property</h2>
            <p className="text-gray-700 leading-relaxed mb-4">
              SiteLedger and all related trademarks, logos, service marks, software, and content (excluding User Content) are owned by SiteLedger, Inc. and protected by copyright, trademark, and other intellectual property laws.
            </p>
            <p className="text-gray-700 leading-relaxed">
              You may not copy, modify, distribute, or create derivative works without our express written permission.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">8. Third-Party Services</h2>
            <p className="text-gray-700 leading-relaxed mb-4">
              SiteLedger may integrate with third-party services (payment processors, AI providers, cloud storage). Your use of these services is governed by their respective terms and privacy policies.
            </p>
            <p className="text-gray-700 leading-relaxed">
              We are not responsible for third-party services, their availability, security, or performance.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">9. Disclaimer of Warranties</h2>
            <p className="text-gray-700 leading-relaxed mb-4">
              THE SERVICE IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED. WE DO NOT WARRANT THAT:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2">
              <li>The Service will be uninterrupted, secure, or error-free</li>
              <li>Results from use will be accurate or reliable</li>
              <li>Defects will be corrected</li>
              <li>AI features will always provide accurate results</li>
            </ul>
            <p className="text-gray-700 leading-relaxed mt-4">
              YOU USE THE SERVICE AT YOUR OWN RISK.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">10. Limitation of Liability</h2>
            <p className="text-gray-700 leading-relaxed mb-4">
              TO THE MAXIMUM EXTENT PERMITTED BY LAW, SITELEDGER SHALL NOT BE LIABLE FOR:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2">
              <li>Indirect, incidental, special, consequential, or punitive damages</li>
              <li>Loss of profits, revenue, data, or business opportunities</li>
              <li>Service interruptions or data breaches</li>
              <li>User Content errors or inaccuracies</li>
              <li>Third-party actions or services</li>
            </ul>
            <p className="text-gray-700 leading-relaxed mt-4">
              OUR TOTAL LIABILITY SHALL NOT EXCEED THE AMOUNT YOU PAID IN THE PAST 12 MONTHS.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">11. Indemnification</h2>
            <p className="text-gray-700 leading-relaxed">
              You agree to indemnify and hold harmless SiteLedger, its affiliates, officers, directors, employees, and agents from any claims, losses, liabilities, damages, costs, or expenses arising from your use of the Service, violation of these Terms, or infringement of any rights.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">12. Dispute Resolution</h2>
            
            <h3 className="text-xl font-semibold text-gray-900 mb-3">12.1 Governing Law</h3>
            <p className="text-gray-700 leading-relaxed mb-4">
              These Terms are governed by the laws of [Your State/Country], without regard to conflict of law principles.
            </p>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">12.2 Arbitration</h3>
            <p className="text-gray-700 leading-relaxed mb-4">
              Any disputes shall be resolved through binding arbitration in accordance with the rules of the American Arbitration Association, except for claims of intellectual property infringement or small claims court jurisdiction.
            </p>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">12.3 Class Action Waiver</h3>
            <p className="text-gray-700 leading-relaxed">
              You agree to resolve disputes on an individual basis and waive the right to participate in class actions or class arbitrations.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">13. Changes to Terms</h2>
            <p className="text-gray-700 leading-relaxed">
              We may modify these Terms at any time. Material changes will be notified via email or in-app notice 30 days before taking effect. Continued use after changes constitutes acceptance. If you disagree, you must stop using the Service.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">14. Termination</h2>
            <p className="text-gray-700 leading-relaxed mb-4">
              Either party may terminate this agreement at any time. Upon termination:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2">
              <li>Your access to the Service will cease immediately</li>
              <li>You remain responsible for all fees incurred before termination</li>
              <li>Provisions regarding liability, indemnification, and disputes survive</li>
              <li>You have 30 days to export your data before deletion</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">15. General Provisions</h2>
            
            <h3 className="text-xl font-semibold text-gray-900 mb-3">15.1 Entire Agreement</h3>
            <p className="text-gray-700 leading-relaxed mb-4">
              These Terms, along with our Privacy Policy, constitute the entire agreement between you and SiteLedger.
            </p>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">15.2 Severability</h3>
            <p className="text-gray-700 leading-relaxed mb-4">
              If any provision is found unenforceable, the remaining provisions remain in full effect.
            </p>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">15.3 No Waiver</h3>
            <p className="text-gray-700 leading-relaxed mb-4">
              Our failure to enforce any right or provision does not constitute a waiver of that right.
            </p>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">15.4 Assignment</h3>
            <p className="text-gray-700 leading-relaxed">
              You may not assign or transfer these Terms. We may assign our rights and obligations without restriction.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">16. Contact Information</h2>
            <p className="text-gray-700 leading-relaxed mb-4">
              For questions about these Terms, please contact us:
            </p>
            <div className="bg-gray-50 p-4 rounded-lg">
              <p className="text-gray-700"><strong>Email:</strong> legal@siteledger.ai</p>
              <p className="text-gray-700"><strong>Support:</strong> <a href="/support" className="text-blue-600 hover:underline">Contact Support</a></p>
              <p className="text-gray-700"><strong>Address:</strong> SiteLedger, Inc., [Your Address]</p>
            </div>
          </section>

          <div className="bg-blue-50 border-l-4 border-blue-600 p-4 mt-8">
            <p className="text-sm text-blue-800">
              <strong>By using SiteLedger, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.</strong>
            </p>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
}
