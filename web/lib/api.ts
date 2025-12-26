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
    if (typeof window !== 'undefined') {
      localStorage.setItem('api_access_token', token);
    }
  }

  loadStoredToken(): void {
    if (typeof window !== 'undefined') {
      this.accessToken = localStorage.getItem('api_access_token');
    }
  }

  clearToken(): void {
    this.accessToken = null;
    if (typeof window !== 'undefined') {
      localStorage.removeItem('api_access_token');
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
        if (typeof window !== 'undefined') {
          window.location.href = '/auth/signin';
        }
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

  // MARK: - AI Insights API

  async fetchAIInsights(): Promise<any[]> {
    return this.request('GET', '/ai-insights');
  }

  async generateAIInsights(jobId: string): Promise<any> {
    return this.request('POST', '/ai-insights', { jobId });
  }

  // MARK: - File Upload

  async uploadFile(file: File, type: 'receipt' | 'document'): Promise<string> {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('type', type);

    const response = await this.axiosInstance.post<{ url: string }>(
      '/upload',
      formData,
      {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      }
    );

    return response.data.url;
  }
}

export default APIService.shared;
