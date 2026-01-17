'use client';

// Version: 2.0 - Updated worker navigation
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import AuthService from '@/lib/auth';
import {
  LayoutDashboard,
  Briefcase,
  Receipt,
  Clock,
  FileText,
  Users,
  Settings,
  LogOut,
  Menu,
  X,
  DollarSign,
  Brain,
  Calendar,
  Link as LinkIcon,
  HelpCircle,
  CheckSquare,
  Building,
  User,
} from 'lucide-react';
import { useState, useEffect } from 'react';
import { BRANDING } from '@/lib/branding';
import NotificationsDropdown from './notifications-dropdown';

const ownerNavigation = [
  { name: 'Dashboard', href: '/dashboard', icon: LayoutDashboard },
  { name: 'Jobs', href: '/jobs', icon: Briefcase },
  { name: 'Receipts', href: '/receipts', icon: Receipt },
  { name: 'Timesheets', href: '/timesheets', icon: Clock },
  { name: 'Documents', href: '/documents', icon: FileText },
  { name: 'Workers', href: '/workers', icon: Users },
  { name: 'Payroll', href: '/payroll', icon: DollarSign },
  { name: 'Calendar', href: '/calendar', icon: Calendar },
  { name: 'Integrations', href: '/integrations', icon: LinkIcon },
  { name: 'Settings', href: '/settings', icon: Settings },
];

const workerNavigation = [
  { name: 'Dashboard', href: '/worker/dashboard', icon: LayoutDashboard },
  { name: 'My Jobs', href: '/worker/jobs', icon: Briefcase },
  { name: 'Time Clock', href: '/timesheets/clock', icon: Clock },
  { name: 'My Timesheets', href: '/worker/timesheets', icon: FileText },
  { name: 'Receipts', href: '/receipts', icon: Receipt },
  { name: 'Profile', href: '/settings', icon: User },
];

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [user, setUser] = useState(AuthService.getCurrentUser());

  // Update user state when component mounts or pathname changes
  useEffect(() => {
    const currentUser = AuthService.getCurrentUser();
    setUser(currentUser);
  }, [pathname]); // Re-fetch when navigating

  // Determine which navigation to show based on user role
  const navigation = user?.role === 'owner' ? ownerNavigation : workerNavigation;

  const handleSignOut = async () => {
    await AuthService.signOut();
    router.push('/auth/signin');
  };

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Mobile menu button */}
      <div className="lg:hidden fixed top-0 left-0 right-0 z-50 bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 px-4 py-3 flex items-center justify-between">
        <button
          onClick={() => setSidebarOpen(!sidebarOpen)}
          className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 text-gray-900 dark:text-white"
        >
          {sidebarOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
        </button>
        <NotificationsDropdown />
      </div>

      {/* Sidebar */}
      <div
        className={`fixed inset-y-0 left-0 z-40 w-64 bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700 transform transition-transform duration-300 ease-in-out lg:translate-x-0 ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'
          }`}
      >
        <div className="flex flex-col h-full">
          {/* Logo */}
          <div className="p-6 border-b border-gray-200 dark:border-gray-700">
            <div className="flex items-center gap-3">
              <img 
                src={user?.companyLogo || BRANDING.LOGO_URL} 
                alt={user?.companyName || BRANDING.APP_NAME} 
                className="w-12 h-12 rounded-xl object-cover" 
              />
              <div className="flex-1">
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                  {user?.companyName || BRANDING.APP_NAME}
                </h1>
                <div className="flex items-center gap-2 mt-1">
                  {user?.photoURL ? (
                    <img
                      src={user.photoURL}
                      alt={user?.name || 'User'}
                      className="w-6 h-6 rounded-full object-cover border-2 border-gray-300 dark:border-gray-600"
                    />
                  ) : (
                    <div className="w-6 h-6 rounded-full bg-blue-500 flex items-center justify-center text-white text-xs font-bold">
                      {user?.name?.charAt(0)?.toUpperCase() || 'U'}
                    </div>
                  )}
                  <p className="text-sm text-gray-600 dark:text-gray-400">{user?.name || 'User'}</p>
                </div>
              </div>
            </div>
          </div>

          {/* Navigation */}
          <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
            {/* Main Navigation */}
            {navigation.map((item) => {
              const isActive = pathname === item.href;
              return (
                <Link
                  key={item.name}
                  href={item.href}
                  onClick={() => setSidebarOpen(false)}
                  className={`flex items-center px-4 py-3 rounded-lg transition-colors ${isActive
                    ? 'bg-[#007AFF] bg-opacity-10 text-[#007AFF] dark:bg-[#3b82f6] dark:bg-opacity-20 dark:text-[#3b82f6] font-medium'
                    : 'text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700'
                    }`}
                >
                  <item.icon className="w-5 h-5 mr-3" />
                  {item.name}
                </Link>
              );
            })}
          </nav>

          {/* Sign Out */}
          <div className="p-4 border-t border-gray-200 dark:border-gray-700">
            <button
              onClick={handleSignOut}
              className="flex items-center w-full px-4 py-3 text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/30 rounded-lg transition-colors"
            >
              <LogOut className="w-5 h-5 mr-3" />
              Sign Out
            </button>
          </div>
        </div>
      </div>

      {/* Main content */}
      <div className="lg:pl-64 pt-16 lg:pt-0">
        <main className="p-6 lg:p-8">{children}</main>
      </div>

      {/* Overlay for mobile */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 bg-black bg-opacity-50 z-30 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}
    </div>
  );
}
