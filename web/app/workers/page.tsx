'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import APIService from '@/lib/api';
import AuthService from '@/lib/auth';
import toast from '@/lib/toast';
import DashboardLayout from '@/components/dashboard-layout';
import { Users, Loader2, Search, Plus, DollarSign, Mail, Phone, AlertCircle, Briefcase, Edit2, X, Trash2 } from 'lucide-react';

export default function Workers() {
  const router = useRouter();
  const user = AuthService.getCurrentUser();
  const [isAuthChecked, setIsAuthChecked] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [editingWorker, setEditingWorker] = useState<any>(null);
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    hourlyRate: '',
    role: 'worker',
    active: true,
  });
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (!AuthService.isAuthenticated()) {
      router.push('/auth/signin');
    } else if (user?.role === 'worker') {
      router.replace('/worker/dashboard');
    } else {
      setIsAuthChecked(true);
    }
  }, [router, user]);

  // Block workers from accessing this page
  if (user?.role === 'worker') {
    return null;
  }

  const { data: workers = [], isLoading } = useQuery({
    queryKey: ['workers'],
    queryFn: () => APIService.fetchWorkers(),
    enabled: isAuthChecked,
  });

  const { data: timesheets = [] } = useQuery({
    queryKey: ['timesheets'],
    queryFn: () => APIService.fetchTimesheets(),
    enabled: isAuthChecked,
  });

  const openEditModal = (worker: any) => {
    setEditingWorker(worker);
    setFormData({
      name: worker.name || '',
      email: worker.email || '',
      phone: worker.phone || '',
      hourlyRate: worker.hourlyRate?.toString() || '',
      role: worker.role || 'worker',
      active: worker.active ?? true,
    });
  };

  const closeEditModal = () => {
    setEditingWorker(null);
    setFormData({
      name: '',
      email: '',
      phone: '',
      hourlyRate: '',
      role: 'worker',
      active: true,
    });
    setIsSaving(false);
  };

  const handleSaveWorker = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSaving(true);
    
    try {
      const updatedWorker = {
        ...editingWorker,
        name: formData.name,
        email: formData.email,
        phone: formData.phone,
        hourlyRate: parseFloat(formData.hourlyRate) || 0,
        role: formData.role,
        active: formData.active,
      };
      
      await APIService.updateWorker(editingWorker.id, updatedWorker);
      
      // Refresh workers list
      window.location.reload();
    } catch (error) {
      toast.error('Failed to update worker. Please try again.');
      setIsSaving(false);
    }
  };

  const handleDeleteWorker = async (workerId: string, workerName: string) => {
    if (!confirm(`Are you sure you want to delete "${workerName}"? This action cannot be undone.`)) {
      return;
    }
    
    try {
      await APIService.deleteWorker(workerId);
      toast.success('Worker deleted successfully');
      // Refresh workers list
      window.location.reload();
    } catch (error: any) {
      toast.error(error.message || 'Failed to delete worker');
    }
  };

  if (!isAuthChecked) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
      </div>
    );
  }

  const filteredWorkers = workers.filter((w: any) =>
    w.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    w.email?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 2,
    }).format(value);
  };

  const getWorkerStats = (workerID: string) => {
    const workerTimesheets = timesheets.filter((ts: any) => ts.workerID === workerID);
    const totalHours = workerTimesheets.reduce((sum: number, ts: any) => sum + (ts.hours || 0), 0);
    return { totalHours, entriesCount: workerTimesheets.length };
  };

  if (isLoading) {
    return (
      <DashboardLayout>
        <div className="flex items-center justify-center min-h-[60vh]">
          <div className="text-center">
            <Loader2 className="w-12 h-12 text-blue-600 animate-spin mx-auto mb-4" />
            <p className="text-gray-600 dark:text-gray-400">Loading workers...</p>
          </div>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
          <div>
            <h1 className="text-3xl lg:text-4xl font-bold text-gray-900 dark:text-white">Workers</h1>
            <p className="text-gray-600 dark:text-gray-400 mt-2">Manage your team members</p>
          </div>
          <button
            onClick={() => router.push('/workers/create')}
            className="flex items-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition shadow-lg"
          >
            <Plus className="w-5 h-5" />
            Add Worker
          </button>
        </div>

        {/* Search */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-4 shadow-sm">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 dark:text-gray-500 w-5 h-5" />
            <input
              type="text"
              placeholder="Search workers..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none bg-white dark:bg-gray-700 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400"
            />
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4 shadow-sm">
            <p className="text-sm text-gray-600 dark:text-gray-400">Total Workers</p>
            <p className="text-2xl font-bold text-gray-900 dark:text-white mt-1">{workers.length}</p>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4 shadow-sm">
            <p className="text-sm text-gray-600 dark:text-gray-400">Active Workers</p>
            <p className="text-2xl font-bold text-green-600 dark:text-green-400 mt-1">
              {workers.filter((w: any) => w.active).length}
            </p>
          </div>
        </div>

        {/* Workers List */}
        {filteredWorkers.length === 0 ? (
          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-12 shadow-sm text-center">
            <AlertCircle className="w-16 h-16 text-gray-400 dark:text-gray-500 mx-auto mb-4" />
            <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">No workers found</h3>
            <p className="text-gray-600 dark:text-gray-400">
              {searchQuery ? 'Try adjusting your search' : 'Add your first worker to get started'}
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {filteredWorkers.map((worker: any) => {
              const stats = getWorkerStats(worker.id);
              return (
                <div
                  key={worker.id}
                  className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm hover:shadow-md transition"
                >
                  <div className="flex items-start justify-between mb-4">
                    <div className="flex-1">
                      <h3 className="text-lg font-bold text-gray-900 dark:text-white">{worker.name}</h3>
                      <span
                        className={`inline-block px-2 py-1 rounded-full text-xs font-medium mt-1 ${
                          worker.active
                            ? 'bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300'
                            : 'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300'
                        }`}
                      >
                        {worker.active ? 'Active' : 'Inactive'}
                      </span>
                    </div>
                    <div className="flex gap-2">
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          openEditModal(worker);
                        }}
                        className="p-2 bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 rounded-lg hover:bg-blue-200 dark:hover:bg-blue-900/50 transition"
                        aria-label="Edit worker"
                      >
                        <Edit2 className="w-4 h-4" />
                      </button>
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          handleDeleteWorker(worker.id, worker.name);
                        }}
                        className="p-2 bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400 rounded-lg hover:bg-red-200 dark:hover:bg-red-900/50 transition"
                        aria-label="Delete worker"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                      <div className="bg-blue-100 dark:bg-blue-900/30 p-3 rounded-lg">
                        <Users className="w-6 h-6 text-blue-600 dark:text-blue-400" />
                      </div>
                    </div>
                  </div>

                  {worker.email && (
                    <div className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400 mb-2">
                      <Mail className="w-4 h-4 flex-shrink-0" />
                      <span className="truncate">{worker.email}</span>
                    </div>
                  )}

                  {worker.phone && (
                    <div className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400 mb-2">
                      <Phone className="w-4 h-4 flex-shrink-0" />
                      {worker.phone}
                    </div>
                  )}

                  {worker.hourlyRate && (
                    <div className="flex items-center gap-2 text-sm font-semibold text-gray-900 dark:text-white mt-3 pt-3 border-t border-gray-200 dark:border-gray-700">
                      <DollarSign className="w-4 h-4" />
                      {formatCurrency(worker.hourlyRate)}/hour
                    </div>
                  )}

                  <div className="mt-3 pt-3 border-t border-gray-200 dark:border-gray-700 grid grid-cols-2 gap-2">
                    <div>
                      <p className="text-xs text-gray-500 dark:text-gray-400">Total Hours</p>
                      <p className="font-semibold text-gray-900 dark:text-white">{stats.totalHours.toFixed(1)}h</p>
                    </div>
                    <div>
                      <p className="text-xs text-gray-500 dark:text-gray-400">Entries</p>
                      <p className="font-semibold text-gray-900 dark:text-white">{stats.entriesCount}</p>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {/* Edit Modal */}
        {editingWorker && (
          <div className="fixed inset-0 bg-black bg-opacity-50 dark:bg-opacity-70 flex items-center justify-center p-4 z-50">
            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-2xl max-w-md w-full max-h-[90vh] overflow-y-auto">
              <div className="sticky top-0 bg-gradient-to-r from-blue-600 to-indigo-600 text-white p-6 rounded-t-xl flex items-center justify-between">
                <h2 className="text-2xl font-bold">Edit Worker</h2>
                <button
                  onClick={closeEditModal}
                  className="p-1 hover:bg-white/20 rounded-lg transition"
                  aria-label="Close modal"
                >
                  <X className="w-6 h-6" />
                </button>
              </div>

              <form onSubmit={handleSaveWorker} className="p-6 space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    Name <span className="text-red-500 dark:text-red-400">*</span>
                  </label>
                  <input
                    type="text"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                    required
                    aria-label="Worker name"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    Email <span className="text-red-500 dark:text-red-400">*</span>
                  </label>
                  <input
                    type="email"
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
                    required
                    aria-label="Worker email"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Phone
                  </label>
                  <input
                    type="tel"
                    value={formData.phone}
                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
                    aria-label="Worker phone number"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Hourly Rate <span className="text-red-500">*</span>
                  </label>
                  <div className="relative">
                    <DollarSign className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
                    <input
                      type="number"
                      step="0.01"
                      min="0"
                      value={formData.hourlyRate}
                      onChange={(e) => setFormData({ ...formData, hourlyRate: e.target.value })}
                      className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
                      required
                      aria-label="Hourly rate"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Role
                  </label>
                  <select
                    value={formData.role}
                    onChange={(e) => setFormData({ ...formData, role: e.target.value })}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
                    aria-label="Worker role"
                  >
                    <option value="worker">Worker</option>
                    <option value="owner">Owner</option>
                  </select>
                </div>

                <div>
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={formData.active}
                      onChange={(e) => setFormData({ ...formData, active: e.target.checked })}
                      className="w-4 h-4 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
                    />
                    <span className="text-sm font-medium text-gray-700">Active Worker</span>
                  </label>
                  <p className="text-xs text-gray-500 mt-1 ml-6">
                    Inactive workers cannot log hours or access the app
                  </p>
                </div>

                <div className="flex gap-3 pt-4">
                  <button
                    type="button"
                    onClick={closeEditModal}
                    className="flex-1 px-4 py-3 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition font-medium"
                    disabled={isSaving}
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    className="flex-1 px-4 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition font-medium disabled:bg-gray-400 disabled:cursor-not-allowed"
                    disabled={isSaving}
                  >
                    {isSaving ? (
                      <span className="flex items-center justify-center gap-2">
                        <Loader2 className="w-4 h-4 animate-spin" />
                        Saving...
                      </span>
                    ) : (
                      'Save Changes'
                    )}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
