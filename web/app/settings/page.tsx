'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import AuthService from '@/lib/auth';
import DashboardLayout from '@/components/dashboard-layout';
import toast from 'react-hot-toast';
import {
  User,
  Settings as SettingsIcon,
  ChevronRight,
  Brain,
  Bell,
  DollarSign,
  Users,
  Building,
  Shield,
  Palette,
  Database,
  Download,
  FileText,
  HelpCircle,
  Briefcase,
  Loader2,
  Trash2
} from 'lucide-react';

interface SettingsSection {
  title: string;
  description: string;
  icon: any;
  iconBg: string;
  iconColor: string;
  items: SettingsItem[];
}

interface SettingsItem {
  name: string;
  description: string;
  link: string;
  icon: any;
}

export default function Settings() {
  const router = useRouter();
  const [isAuthChecked, setIsAuthChecked] = useState(false);
  const [user, setUser] = useState<any>(null);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [deleteConfirmText, setDeleteConfirmText] = useState('');
  const [isDeleting, setIsDeleting] = useState(false);

  useEffect(() => {
    const init = async () => {
      if (!AuthService.isAuthenticated()) {
        router.push('/auth/signin');
        return;
      }

      try {
        await AuthService.checkSession();
      } catch (error) {
        console.error('Failed to refresh session:', error);
      }

      setIsAuthChecked(true);
      const currentUser = AuthService.getCurrentUser();
      setUser(currentUser);
    };

    init();
  }, [router]);

  const handleDeleteAccount = async () => {
    if (deleteConfirmText.toLowerCase() !== 'delete my account') {
      toast.error('Please type "delete my account" to confirm');
      return;
    }

    setIsDeleting(true);
    try {
      const token = localStorage.getItem('accessToken');
      const response = await fetch('https://api.siteledger.ai/api/auth/delete-account', {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      if (!response.ok) {
        throw new Error('Failed to delete account');
      }

      toast.success('Account deleted successfully');
      AuthService.signOut();
    } catch (error) {
      console.error('Delete account error:', error);
      toast.error('Failed to delete account. Please try again.');
    } finally {
      setIsDeleting(false);
      setShowDeleteModal(false);
    }
  };

  if (!isAuthChecked) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
      </div>
    );
  }

  // Owner settings - full access to all features
  const ownerSections: SettingsSection[] = [
    {
      title: 'AI Settings',
      description: 'Configure AI-powered features and automation',
      icon: Brain,
      iconBg: 'bg-purple-100',
      iconColor: 'text-purple-600',
      items: [
        {
          name: 'AI Thresholds',
          description: 'Configure confidence thresholds for AI decisions',
          link: '/settings/ai-thresholds',
          icon: Brain
        },
        {
          name: 'AI Automation',
          description: 'Set automation levels: Manual, Assist, or Auto-Pilot',
          link: '/settings/ai-automation',
          icon: SettingsIcon
        },
        {
          name: 'AI Insights',
          description: 'Enable advanced insights and recommendations',
          link: '/settings/ai-insights',
          icon: Briefcase
        },
        {
          name: 'Smart Notifications',
          description: 'Manage AI-powered alerts and notifications',
          link: '/settings/notifications',
          icon: Bell
        }
      ]
    },
    {
      title: 'Team Management',
      description: 'Manage workers, roles, and permissions',
      icon: Users,
      iconBg: 'bg-blue-100',
      iconColor: 'text-blue-600',
      items: [
        {
          name: 'Roles & Permissions',
          description: 'Manage worker roles and access permissions',
          link: '/settings/roles',
          icon: Shield
        }
      ]
    },
    {
      title: 'Company',
      description: 'Company profile and account settings',
      icon: Building,
      iconBg: 'bg-green-100',
      iconColor: 'text-green-600',
      items: [
        {
          name: 'Company Profile',
          description: 'Edit company name, address, and branding',
          link: '/settings/company',
          icon: Building
        },
        {
          name: 'Account Settings',
          description: 'Update your personal account details',
          link: '/settings/account',
          icon: User
        }
      ]
    },
    {
      title: 'Preferences',
      description: 'Customize your SiteLedger experience',
      icon: Palette,
      iconBg: 'bg-orange-100',
      iconColor: 'text-orange-600',
      items: [
        {
          name: 'Appearance',
          description: 'Choose theme and display preferences',
          link: '/settings/appearance',
          icon: Palette
        },
        {
          name: 'Data Retention',
          description: 'Configure how long data is stored',
          link: '/settings/data-retention',
          icon: Database
        },
        {
          name: 'Export Data',
          description: 'Export your data for backup or analysis',
          link: '/settings/export',
          icon: Download
        }
      ]
    },
    {
      title: 'Legal & Support',
      description: 'Privacy, terms, and help resources',
      icon: FileText,
      iconBg: 'bg-gray-100',
      iconColor: 'text-gray-600',
      items: [
        {
          name: 'Privacy Policy',
          description: 'How we collect, use, and protect your data',
          link: '/legal/privacy',
          icon: Shield
        },
        {
          name: 'Terms of Service',
          description: 'Terms and conditions for using SiteLedger',
          link: '/legal/terms',
          icon: FileText
        },
        {
          name: 'FAQ',
          description: 'Frequently asked questions and answers',
          link: '/support/faq',
          icon: HelpCircle
        },
        {
          name: 'Contact Support',
          description: 'Get help from our support team',
          link: '/support',
          icon: HelpCircle
        }
      ]
    }
  ];

  // Worker settings - simplified, personal settings only
  const workerSections: SettingsSection[] = [
    {
      title: 'My Account',
      description: 'Manage your personal profile and settings',
      icon: User,
      iconBg: 'bg-green-100',
      iconColor: 'text-green-600',
      items: [
        {
          name: 'Account Settings',
          description: 'Update your personal account details',
          link: '/settings/account',
          icon: User
        }
      ]
    },
    {
      title: 'Preferences',
      description: 'Customize your experience',
      icon: Palette,
      iconBg: 'bg-orange-100',
      iconColor: 'text-orange-600',
      items: [
        {
          name: 'Appearance',
          description: 'Choose theme and display preferences',
          link: '/settings/appearance',
          icon: Palette
        },
        {
          name: 'Notifications',
          description: 'Manage alerts and notifications',
          link: '/settings/notifications',
          icon: Bell
        }
      ]
    },
    {
      title: 'Legal & Support',
      description: 'Privacy, terms, and help resources',
      icon: FileText,
      iconBg: 'bg-gray-100',
      iconColor: 'text-gray-600',
      items: [
        {
          name: 'Privacy Policy',
          description: 'How we collect, use, and protect your data',
          link: '/legal/privacy',
          icon: Shield
        },
        {
          name: 'Terms of Service',
          description: 'Terms and conditions for using SiteLedger',
          link: '/legal/terms',
          icon: FileText
        },
        {
          name: 'FAQ',
          description: 'Frequently asked questions and answers',
          link: '/support/faq',
          icon: HelpCircle
        },
        {
          name: 'Contact Support',
          description: 'Get help from our support team',
          link: '/support',
          icon: HelpCircle
        }
      ]
    }
  ];

  // Choose sections based on user role
  const sections = user?.role === 'owner' ? ownerSections : workerSections;

  return (
    <DashboardLayout>
      <div className="space-y-6">
        {/* Header */}
        <div>
          <h1 className="text-3xl lg:text-4xl font-bold text-gray-900">Settings</h1>
          <p className="text-gray-600 mt-2">Manage your account and preferences</p>
        </div>

        {/* User Profile Card */}
        <div className="bg-gradient-to-r from-blue-600 to-indigo-600 rounded-xl p-8 text-white shadow-lg">
          <div className="flex items-center gap-6">
            <div className="bg-white/20 p-6 rounded-full">
              <User className="w-12 h-12" />
            </div>
            <div className="flex-1">
              <h2 className="text-3xl font-bold">{user?.name || 'User'}</h2>
              <p className="text-blue-100 text-lg mt-1">{user?.email}</p>
              <div className="flex gap-2 mt-3">
                <span className="text-sm text-blue-200 px-3 py-1 bg-white/10 rounded-full capitalize">
                  {user?.role || 'N/A'} Account
                </span>
                <span className="text-sm text-blue-200 px-3 py-1 bg-white/10 rounded-full">
                  {user?.active ? 'Active' : 'Inactive'}
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* Settings Sections */}
        {sections.map((section, sectionIndex) => (
          <div key={sectionIndex} className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
            {/* Section Header */}
            <div className="p-6 border-b border-gray-200">
              <div className="flex items-center gap-4">
                <div className={`${section.iconBg} p-3 rounded-lg`}>
                  <section.icon className={`w-6 h-6 ${section.iconColor}`} />
                </div>
                <div>
                  <h2 className="text-xl font-bold text-gray-900 dark:text-white">{section.title}</h2>
                  <p className="text-sm text-gray-600 mt-0.5">{section.description}</p>
                </div>
              </div>
            </div>

            {/* Section Items */}
            <div className="divide-y divide-gray-200">
              {section.items.map((item, itemIndex) => (
                <button
                  key={itemIndex}
                  onClick={() => router.push(item.link)}
                  className="w-full flex items-center gap-4 p-6 hover:bg-gray-50 transition text-left group"
                >
                  <div className="bg-gray-100 p-2 rounded-lg group-hover:bg-gray-200 transition">
                    <item.icon className="w-5 h-5 text-gray-600" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <h3 className="font-semibold text-gray-900 group-hover:text-blue-600 transition">
                      {item.name}
                    </h3>
                    <p className="text-sm text-gray-600 mt-0.5">{item.description}</p>
                  </div>
                  <ChevronRight className="w-5 h-5 text-gray-400 group-hover:text-blue-600 transition flex-shrink-0" />
                </button>
              ))}
            </div>
          </div>
        ))}

        {/* Delete Account Section - Only for owners */}
        {user?.role === 'owner' && (
          <div className="bg-white dark:bg-gray-800 rounded-xl border border-red-200 dark:border-red-800 shadow-sm overflow-hidden">
            <button
              onClick={() => setShowDeleteModal(true)}
              className="w-full flex items-center gap-4 p-6 hover:bg-red-50 dark:hover:bg-red-900/20 transition text-left group"
            >
              <div className="bg-red-100 dark:bg-red-900/30 p-3 rounded-lg group-hover:bg-red-200 dark:group-hover:bg-red-900/50 transition">
                <Trash2 className="w-6 h-6 text-red-600 dark:text-red-400" />
              </div>
              <div className="flex-1">
                <h3 className="font-bold text-red-600 dark:text-red-400 text-lg">Delete Account</h3>
                <p className="text-sm text-red-600 dark:text-red-400 mt-0.5">Permanently delete your account and all data</p>
              </div>
              <ChevronRight className="w-5 h-5 text-red-400 group-hover:text-red-600 dark:group-hover:text-red-400 transition" />
            </button>
          </div>
        )}

        {/* Sign Out Button */}
        <div className="bg-white rounded-xl border border-red-200 shadow-sm overflow-hidden">
          <button
            onClick={() => {
              if (confirm('Are you sure you want to sign out?')) {
                AuthService.signOut();
              }
            }}
            className="w-full flex items-center gap-4 p-6 hover:bg-red-50 transition text-left group"
          >
            <div className="bg-red-100 p-3 rounded-lg group-hover:bg-red-200 transition">
              <Shield className="w-6 h-6 text-red-600" />
            </div>
            <div className="flex-1">
              <h3 className="font-bold text-red-600 text-lg">Sign Out</h3>
              <p className="text-sm text-red-600 mt-0.5">Sign out of your SiteLedger account</p>
            </div>
            <ChevronRight className="w-5 h-5 text-red-400 group-hover:text-red-600 transition" />
          </button>
        </div>

        {/* Account Info Footer */}
        <div className="bg-gray-50 dark:bg-gray-800 rounded-lg p-4 text-center">
          <p className="text-sm text-gray-600 dark:text-gray-400">
            Account created: {user?.createdAt ? new Date(user.createdAt).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' }) : 'N/A'}
          </p>
          <p className="text-xs text-gray-500 mt-1">
            SiteLedger v1.0 • © {new Date().getFullYear()} All rights reserved
          </p>
        </div>

        {/* Delete Account Confirmation Modal */}
        {showDeleteModal && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
            <div className="bg-white dark:bg-gray-800 rounded-xl p-6 max-w-md w-full">
              <div className="flex items-center gap-3 mb-4">
                <div className="w-12 h-12 bg-red-100 dark:bg-red-900/30 rounded-full flex items-center justify-center">
                  <Trash2 className="w-6 h-6 text-red-600 dark:text-red-400" />
                </div>
                <h2 className="text-2xl font-bold text-gray-900 dark:text-white">Delete Account?</h2>
              </div>

              <div className="space-y-4">
                <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4">
                  <p className="text-sm text-red-800 dark:text-red-300 font-semibold mb-2">
                    ⚠️ Warning: This action cannot be undone
                  </p>
                  <ul className="text-sm text-red-700 dark:text-red-400 space-y-1 list-disc list-inside">
                    <li>All your jobs and projects will be deleted</li>
                    <li>All receipts and documents will be removed</li>
                    <li>All timesheets and payroll data will be lost</li>
                    <li>Worker accounts you created will also be deleted</li>
                  </ul>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    Type "delete my account" to confirm:
                  </label>
                  <input
                    type="text"
                    value={deleteConfirmText}
                    onChange={(e) => setDeleteConfirmText(e.target.value)}
                    placeholder="delete my account"
                    className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500"
                  />
                </div>

                <div className="flex gap-3">
                  <button
                    onClick={() => {
                      setShowDeleteModal(false);
                      setDeleteConfirmText('');
                    }}
                    disabled={isDeleting}
                    className="flex-1 py-3 border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition font-medium disabled:opacity-50"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={handleDeleteAccount}
                    disabled={isDeleting || deleteConfirmText.toLowerCase() !== 'delete my account'}
                    className="flex-1 py-3 bg-red-600 dark:bg-red-700 text-white rounded-lg hover:bg-red-700 dark:hover:bg-red-600 transition font-medium disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                  >
                    {isDeleting ? (
                      <>
                        <Loader2 className="w-5 h-5 animate-spin" />
                        Deleting...
                      </>
                    ) : (
                      <>
                        <Trash2 className="w-5 h-5" />
                        Delete Account
                      </>
                    )}
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
