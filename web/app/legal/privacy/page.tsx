'use client';

import { useRouter } from 'next/navigation';
import DashboardLayout from '@/components/dashboard-layout';
import BackButton from '@/components/back-button';

export default function PrivacyPolicy() {
  const router = useRouter();

  return (
    <DashboardLayout>
      <div className="max-w-4xl mx-auto space-y-6">
        <div className="flex items-center gap-4">
          <BackButton />
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Privacy Policy</h1>
        </div>

        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-8 shadow-sm prose prose-blue max-w-none">
          <p className="text-sm text-gray-500 dark:text-gray-400 mb-6">Last Updated: December 25, 2025</p>

          <section className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">1. Introduction</h2>
            <p className="text-gray-700 dark:text-gray-300 leading-relaxed mb-4">
              Welcome to SiteLedger ("we," "our," or "us"). We are committed to protecting your personal information and your right to privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our contractor management platform.
            </p>
            <p className="text-gray-700 dark:text-gray-300 leading-relaxed">
              By using SiteLedger, you agree to the collection and use of information in accordance with this policy. If you do not agree with our policies and practices, please do not use our services.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">2. Information We Collect</h2>
            
            <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-3">2.1 Personal Information</h3>
            <p className="text-gray-700 dark:text-gray-300 leading-relaxed mb-4">
              We collect information that you provide directly to us, including:
            </p>
            <ul className="list-disc pl-6 text-gray-700 dark:text-gray-300 space-y-2 mb-4">
              <li>Name, email address, phone number</li>
              <li>Company information (name, tax ID)</li>
              <li>Payment and billing information</li>
              <li>Profile photos and avatars</li>
              <li>Job and project details</li>
              <li>Receipt and expense information</li>
              <li>Timesheet and work hour data</li>
            </ul>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">2.2 Automatically Collected Information</h3>
            <ul className="list-disc pl-6 text-gray-700 space-y-2 mb-4">
              <li>Device information (IP address, browser type, operating system)</li>
              <li>Usage data (pages visited, time spent, features used)</li>
              <li>Location data (when you use GPS check-in features)</li>
              <li>Cookies and similar tracking technologies</li>
            </ul>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">2.3 Information from Third Parties</h3>
            <p className="text-gray-700 leading-relaxed">
              We may receive information from third-party services you connect to SiteLedger, such as accounting software or payment processors.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">3. How We Use Your Information</h2>
            <p className="text-gray-700 leading-relaxed mb-4">
              We use your information to:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2">
              <li>Provide, operate, and maintain our services</li>
              <li>Process your transactions and manage your account</li>
              <li>Send you notifications, updates, and administrative messages</li>
              <li>Improve and optimize our platform through analytics</li>
              <li>Provide AI-powered features (receipt scanning, insights, automation)</li>
              <li>Detect and prevent fraud, abuse, and security incidents</li>
              <li>Comply with legal obligations and enforce our terms</li>
              <li>Respond to customer support requests</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">4. Information Sharing and Disclosure</h2>
            <p className="text-gray-700 leading-relaxed mb-4">
              We may share your information with:
            </p>
            
            <h3 className="text-xl font-semibold text-gray-900 mb-3">4.1 Service Providers</h3>
            <p className="text-gray-700 leading-relaxed mb-4">
              Third-party vendors who perform services on our behalf (cloud hosting, payment processing, AI/ML services, analytics).
            </p>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">4.2 Business Transfers</h3>
            <p className="text-gray-700 leading-relaxed mb-4">
              In connection with any merger, sale, acquisition, or transfer of all or part of our business.
            </p>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">4.3 Legal Requirements</h3>
            <p className="text-gray-700 leading-relaxed mb-4">
              When required by law, legal process, litigation, or governmental requests.
            </p>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">4.4 With Your Consent</h3>
            <p className="text-gray-700 leading-relaxed">
              We may share your information with your explicit consent or at your direction.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">5. Data Security</h2>
            <p className="text-gray-700 leading-relaxed mb-4">
              We implement appropriate technical and organizational security measures to protect your information, including:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2">
              <li>Encryption of data in transit and at rest (TLS/SSL, AES-256)</li>
              <li>Regular security audits and vulnerability assessments</li>
              <li>Access controls and authentication (password requirements, 2FA)</li>
              <li>Secure data centers and infrastructure</li>
              <li>Employee training on data protection and privacy</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">6. Your Rights and Choices</h2>
            <p className="text-gray-700 leading-relaxed mb-4">
              You have the right to:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2">
              <li><strong>Access:</strong> Request a copy of your personal information</li>
              <li><strong>Correct:</strong> Update or correct inaccurate information</li>
              <li><strong>Delete:</strong> Request deletion of your data (subject to legal obligations)</li>
              <li><strong>Export:</strong> Download your data in a portable format</li>
              <li><strong>Opt-out:</strong> Unsubscribe from marketing communications</li>
              <li><strong>Restrict:</strong> Limit how we use your data</li>
            </ul>
            <p className="text-gray-700 leading-relaxed mt-4">
              To exercise these rights, contact us at privacy@siteledger.ai or use the settings in your account.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">7. Cookies and Tracking</h2>
            <p className="text-gray-700 leading-relaxed mb-4">
              We use cookies and similar technologies to:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2">
              <li>Remember your preferences and settings</li>
              <li>Authenticate your login sessions</li>
              <li>Analyze site traffic and usage patterns</li>
              <li>Improve our services and user experience</li>
            </ul>
            <p className="text-gray-700 leading-relaxed mt-4">
              You can control cookies through your browser settings, but disabling cookies may affect functionality.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">8. Data Retention</h2>
            <p className="text-gray-700 leading-relaxed">
              We retain your information for as long as necessary to provide our services, comply with legal obligations, resolve disputes, and enforce our agreements. You can configure data retention settings in Settings &gt; Data Retention.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">9. Children's Privacy</h2>
            <p className="text-gray-700 leading-relaxed">
              SiteLedger is not intended for individuals under 18 years of age. We do not knowingly collect personal information from children. If you believe we have collected information from a child, please contact us immediately.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">10. International Data Transfers</h2>
            <p className="text-gray-700 leading-relaxed">
              Your information may be transferred to and processed in countries other than your country of residence. We ensure appropriate safeguards are in place for international transfers in compliance with applicable laws.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">11. Changes to This Policy</h2>
            <p className="text-gray-700 leading-relaxed">
              We may update this Privacy Policy from time to time. We will notify you of material changes by email or through our platform. Your continued use of SiteLedger after changes constitutes acceptance of the updated policy.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">12. Contact Us</h2>
            <p className="text-gray-700 leading-relaxed mb-4">
              If you have questions or concerns about this Privacy Policy, please contact us:
            </p>
            <div className="bg-gray-50 p-4 rounded-lg">
              <p className="text-gray-700"><strong>Email:</strong> privacy@siteledger.ai</p>
              <p className="text-gray-700"><strong>Support:</strong> <a href="/support" className="text-blue-600 hover:underline">Contact Support</a></p>
            </div>
          </section>
        </div>
      </div>
    </DashboardLayout>
  );
}
