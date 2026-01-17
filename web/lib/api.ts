import axios, { AxiosInstance, AxiosRequestConfig } from 'axios';

/**
 * API Service - Matches iOS APIService.swift exactly
 * Connects to DigitalOcean PostgreSQL backend
 */
class APIService {
  private static instance: APIService;
  private baseURL: string = 'https://api.siteledger.ai/api';
  private accessToken: string | null = null;
  private axiosInstance: AxiosInstance;
  private static readonly TOKEN_KEY = 'accessToken';

  private constructor() {
    this.axiosInstance = axios.create({
      baseURL: this.baseURL,
      timeout: 30000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Request interceptor to add auth token
    this.axiosInstance.interceptors.request.use(
      (config) => {
        if (this.accessToken) {
          config.headers.Authorization = `Bearer ${this.accessToken}`;
        }
        return config;
      },
      (error) => Promise.reject(error)
    );

    // Load stored token
    this.loadStoredToken();
  }

  static get shared(): APIService {
    if (!APIService.instance) {
      APIService.instance = new APIService();
    }
    return APIService.instance;
  }

  // MARK: - Token Management

  setAccessToken(token: string): void {
    this.accessToken = token;
    this.axiosInstance.defaults.headers.common['Authorization'] = `Bearer ${token}`;
    if (typeof window !== 'undefined') {
      localStorage.setItem(APIService.TOKEN_KEY, token);
    }
  }

  loadStoredToken(): void {
    if (typeof window !== 'undefined') {
      const token = localStorage.getItem(APIService.TOKEN_KEY);
      if (token) {
        this.accessToken = token;
        this.axiosInstance.defaults.headers.common['Authorization'] = `Bearer ${token}`;
      }
    }
  }

  clearToken(): void {
    this.accessToken = null;
    delete this.axiosInstance.defaults.headers.common['Authorization'];
    if (typeof window !== 'undefined') {
      localStorage.removeItem(APIService.TOKEN_KEY);
    }
  }

  // MARK: - Health Check

  async checkHealth(): Promise<boolean> {
    try {
      const response = await axios.get('https://api.siteledger.ai/health', {
        timeout: 5000,
      });
      return response.status === 200;
    } catch (error) {
      return false;
    }
  }

  // MARK: - Generic Request Method

  async request<T>(
    method: string,
    endpoint: string,
    data?: any,
    config?: AxiosRequestConfig
  ): Promise<T> {
    try {
      const response = await this.axiosInstance.request<T>({
        method,
        url: endpoint,
        data,
        ...config,
      });
      return response.data;
    } catch (error: any) {
      if (error.response?.status === 401) {
        // Token expired or invalid
        this.clearToken();
        // Disable auto-redirect to prevent loops; let the UI handle the error state
        // if (typeof window !== 'undefined') {
        //   window.location.href = '/auth/signin';
        // }
      }
      throw error;
    }
  }

  // MARK: - Jobs API

  async fetchJobs(): Promise<any[]> {
    return this.request('GET', '/jobs');
  }

  async fetchJob(id: string): Promise<any> {
    return this.request('GET', `/jobs/${id}`);
  }

  async createJob(job: any): Promise<any> {
    return this.request('POST', '/jobs', job);
  }

  async updateJob(id: string, job: any): Promise<any> {
    return this.request('PUT', `/jobs/${id}`, job);
  }

  async deleteJob(id: string): Promise<void> {
    return this.request('DELETE', `/jobs/${id}`);
  }

  // MARK: - Receipts API

  async fetchReceipts(): Promise<any[]> {
    return this.request('GET', '/receipts');
  }

  async fetchReceipt(id: string): Promise<any> {
    return this.request('GET', `/receipts/${id}`);
  }

  async createReceipt(receipt: any): Promise<any> {
    return this.request('POST', '/receipts', receipt);
  }

  async updateReceipt(id: string, receipt: any): Promise<any> {
    return this.request('PUT', `/receipts/${id}`, receipt);
  }

  async deleteReceipt(id: string): Promise<void> {
    return this.request('DELETE', `/receipts/${id}`);
  }

  async processReceiptOCR(imageUrl: string): Promise<any> {
    return this.request('POST', '/receipts/ocr', { imageUrl });
  }

  // MARK: - Timesheets API

  async fetchTimesheets(): Promise<any[]> {
    return this.request('GET', '/timesheets');
  }

  async fetchTimesheet(id: string): Promise<any> {
    return this.request('GET', `/timesheets/${id}`);
  }

  async createTimesheet(timesheet: any): Promise<any> {
    return this.request('POST', '/timesheets', timesheet);
  }

  async updateTimesheet(id: string, timesheet: any): Promise<any> {
    return this.request('PUT', `/timesheets/${id}`, timesheet);
  }

  async deleteTimesheet(id: string): Promise<void> {
    return this.request('DELETE', `/timesheets/${id}`);
  }

  async clockIn(data: { jobID: string; latitude?: number | null; longitude?: number | null }): Promise<any> {
    return this.request('POST', '/timesheets/clock-in', data);
  }

  async clockOut(timesheetId: string): Promise<any> {
    return this.request('POST', '/timesheets/clock-out', { timesheetId });
  }

  // MARK: - Documents API

  async fetchDocuments(): Promise<any[]> {
    return this.request('GET', '/documents');
  }

  async fetchDocument(id: string): Promise<any> {
    return this.request('GET', `/documents/${id}`);
  }

  async createDocument(document: any): Promise<any> {
    return this.request('POST', '/documents', document);
  }

  async deleteDocument(id: string): Promise<void> {
    return this.request('DELETE', `/documents/${id}`);
  }

  // MARK: - Workers API

  async fetchWorkers(): Promise<any[]> {
    return this.request('GET', '/workers');
  }

  async fetchWorker(id: string): Promise<any> {
    return this.request('GET', `/workers/${id}`);
  }

  async createWorker(worker: any): Promise<any> {
    return this.request('POST', '/workers', worker);
  }

  async updateWorker(id: string, worker: any): Promise<any> {
    return this.request('PUT', `/workers/${id}`, worker);
  }

  async deleteWorker(id: string): Promise<void> {
    return this.request('DELETE', `/workers/${id}`);
  }

  // MARK: - Worker Payments API

  async fetchPayments(): Promise<any[]> {
    return this.request('GET', '/worker-payments');
  }

  async fetchWorkerPayments(workerId: string): Promise<any[]> {
    return this.request('GET', `/worker-payments/worker/${workerId}`);
  }

  async recordPayment(payment: any): Promise<any> {
    return this.request('POST', '/worker-payments', payment);
  }

  // MARK: - Client Payments API

  async fetchClientPayments(jobId: string): Promise<any[]> {
    return this.request('GET', `/client-payments/job/${jobId}`);
  }

  async createClientPayment(payment: any): Promise<any> {
    return this.request('POST', '/client-payments', payment);
  }

  async deleteClientPayment(id: string): Promise<void> {
    return this.request('DELETE', `/client-payments/${id}`);
  }

  // MARK: - Worker Job Assignments API

  async fetchWorkerJobAssignments(): Promise<any[]> {
    return this.request('GET', '/worker-job-assignments');
  }

  async assignWorkerToJob(workerID: string, jobID: string): Promise<any> {
    return this.request('POST', '/worker-job-assignments', { workerID, jobID });
  }

  async removeWorkerFromJob(workerID: string, jobID: string): Promise<void> {
    return this.request('DELETE', `/worker-job-assignments/${workerID}/${jobID}`);
  }

  // MARK: - Alerts API

  async fetchAlerts(): Promise<any[]> {
    return this.request('GET', '/alerts');
  }

  async markAlertRead(id: string): Promise<void> {
    return this.request('PUT', `/alerts/${id}/read`);
  }

  // MARK: - User/Account API

  async changePassword(currentPassword: string, newPassword: string): Promise<void> {
    return this.request('POST', '/auth/change-password', {
      currentPassword,
      newPassword
    });
  }

  async updateUserProfile(data: { name?: string; phone?: string; photoURL?: string; bankInfo?: any }): Promise<any> {
    return this.request('PUT', '/auth/profile', data);
  }

  async deleteAccount(): Promise<void> {
    return this.request('DELETE', '/auth/account');
  }

  // MARK: - AI Insights API

  async fetchAIInsights(): Promise<any[]> {
    return this.request('GET', '/ai-insights');
  }

  async generateAIInsights(jobId?: string): Promise<any> {
    // If jobId provided, generate for specific job, otherwise generate for all jobs
    const endpoint = jobId ? `/ai-insights/generate/${jobId}` : '/ai-insights/generate';
    return this.request('POST', endpoint);
  }

  // MARK: - File Upload

  async uploadFile(file: File, type: 'receipt' | 'document' | 'profile'): Promise<string> {
    const maxRetries = 3;
    let lastError: any;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        const formData = new FormData();
        formData.append('file', file);

        // Backend expects /api/upload/receipt or /api/upload/document or /api/upload/profile
        const endpoint = `/upload/${type}`;

        const response = await this.axiosInstance.post<{ url: string }>(
          endpoint,
          formData,
          {
            headers: {
              'Content-Type': 'multipart/form-data',
            },
            timeout: 60000, // 60 seconds for file upload
          }
        );

        return response.data.url;
      } catch (error: any) {
        console.error(`Upload attempt ${attempt} failed:`, error);
        lastError = error;

        if (attempt < maxRetries) {
          // Wait before retry (exponential backoff)
          await new Promise(resolve => setTimeout(resolve, 1000 * attempt));
        }
      }
    }

    throw new Error(lastError?.response?.data?.error || lastError?.message || 'Failed to upload file after 3 attempts');
  }
}

export default APIService.shared;
