/**
 * Job Model - Matches iOS Job.swift exactly
 * Represents a contractor project/job with financial tracking
 */

export enum JobStatus {
  ACTIVE = 'active',
  COMPLETED = 'completed',
  ON_HOLD = 'on_hold',
}

export interface Job {
  id?: string;
  ownerID: string;
  jobName: string;
  clientName: string;
  address: string;
  latitude?: number;
  longitude?: number;
  startDate: Date;
  endDate?: Date;
  status: JobStatus;
  notes: string;
  createdAt: Date;
  projectValue: number;
  amountPaid: number;
  assignedWorkers?: string[];
}

/**
 * Calculate profit: projectValue - laborCost - receiptExpenses
 * Receipts now affect profit as job expenses
 */
export function calculateProfit(
  job: Job,
  laborCost: number = 0,
  receiptExpenses: number = 0
): number {
  return job.projectValue - laborCost - receiptExpenses;
}

/**
 * Remaining balance owed by client
 */
export function remainingBalance(job: Job): number {
  return job.projectValue - job.amountPaid;
}

/**
 * Receipt Model - Matches iOS Receipt.swift
 */
export interface Receipt {
  id?: string;
  ownerID: string;
  jobID?: string;
  amount: number;
  vendor: string;
  date: Date;
  category?: string;
  imageURL?: string;
  notes: string;
  createdAt: Date;
  // AI Processing Fields
  aiProcessed?: boolean;
  aiConfidence?: number;  // 0.0 to 1.0
  aiFlags?: string[];  // ["duplicate", "unusual_amount", "missing_info", etc.]
  aiSuggestedCategory?: string;
}

/**
 * Timesheet Model - Matches iOS Timesheet.swift
 */
export interface Timesheet {
  id?: string;
  ownerID?: string;  // Owner who manages this timesheet
  userID?: string;  // Worker ID (renamed from workerID to match API)
  workerID?: string;  // Compatibility alias for userID
  jobID?: string;
  jobName?: string;  // Job name from backend
  clockIn: Date;
  clockOut?: Date;
  hours?: number;
  status?: 'working' | 'completed' | 'flagged';
  notes?: string;
  createdAt: Date;
  // Location Tracking
  latitude?: number;  // Legacy single location
  longitude?: number;  // Legacy single location
  clockInLocation?: string;  // GPS coordinates or address
  clockOutLocation?: string;
  clockInLatitude?: number;
  clockInLongitude?: number;
  clockOutLatitude?: number;
  clockOutLongitude?: number;
  distanceFromJobSite?: number;  // Distance in meters
  isLocationValid?: boolean;  // Within acceptable radius
  // AI Flags
  aiFlags?: string[];  // ["auto_checkout", "unusual_hours", "location_mismatch", etc.]
}

/**
 * Document Model - Matches iOS Document.swift
 */
export enum DocumentType {
  PDF = 'pdf',
  IMAGE = 'image',
  OTHER = 'other',
}

export enum DocumentCategory {
  CONTRACT = 'contract',
  INVOICE = 'invoice',
  ESTIMATE = 'estimate',
  PERMIT = 'permit',
  RECEIPT = 'receipt',
  PHOTO = 'photo',
  BLUEPRINT = 'blueprint',
  OTHER = 'other',
}

export interface Document {
  id?: string;
  ownerID: string;
  jobID?: string;
  title: string;  // Renamed from fileName to match iOS
  fileURL: string;
  fileType: DocumentType | string;
  fileSize?: number;
  uploadDate?: Date;  // Kept for backward compatibility
  createdAt?: Date;
  notes?: string;
  // AI Processing Fields
  aiProcessed?: boolean;
  aiSummary?: string;  // AI-generated summary
  aiExtractedData?: Record<string, string>;  // Key-value pairs extracted by AI
  aiConfidence?: number;  // 0.0 to 1.0
  aiFlags?: string[];  // ["low_quality", "missing_signature", etc.]
  documentCategory?: DocumentCategory;  // AI-detected document type
}

/**
 * User Model - Matches iOS User.swift
 */
export enum UserRole {
  OWNER = 'owner',
  WORKER = 'worker',
}

export interface WorkerPermissions {
  canViewFinancials: boolean;
  canUploadReceipts: boolean;
  canApproveTimesheets: boolean;
  canSeeAIInsights: boolean;
  canViewAllJobs: boolean;
}

export interface User {
  id?: string;
  ownerID?: string;  // Owner who manages this worker (for worker role)
  name: string;
  email: string;
  phone?: string;
  photoURL?: string;
  role: UserRole;
  hourlyRate?: number;
  active: boolean;
  assignedJobIDs?: string[];  // Jobs this worker is assigned to
  workerPermissions?: WorkerPermissions;
  hasPassword?: boolean;  // False for Apple Sign-In users
  createdAt: Date;
}

/**
 * WorkerPayment Model - Matches iOS WorkerPayment.swift
 * Represents a payment made to a worker
 */
export enum PaymentMethod {
  CASH = 'cash',
  CHECK = 'check',
  DIRECT_DEPOSIT = 'direct_deposit',
  VENMO = 'venmo',
  ZELLE = 'zelle',
  PAYPAL = 'paypal',
  OTHER = 'other',
}

export interface WorkerPayment {
  id?: string;
  ownerID: string;
  workerID: string;
  workerName: string;
  amount: number;
  paymentDate: Date;
  periodStart: Date;
  periodEnd: Date;
  hoursWorked: number;
  hourlyRate: number;
  calculatedEarnings: number;
  paymentMethod: PaymentMethod;
  notes?: string;
  referenceNumber?: string;
  createdAt: Date;
}

/**
 * WorkerPayrollSummary - Summary of worker earnings and payments
 */
export interface WorkerPayrollSummary {
  workerID: string;
  workerName: string;
  hourlyRate: number;
  totalHoursWorked: number;
  totalEarnings: number;
  totalPaid: number;
  balance: number;
}

/**
 * Alert Model - Matches iOS Alert.swift
 */
export enum AlertType {
  BUDGET = 'budget',
  LABOR = 'labor',
  RECEIPT = 'receipt',
  DOCUMENT = 'document',
  TIMESHEET = 'timesheet',
  PAYMENT = 'payment',
}

export enum AlertSeverity {
  INFO = 'info',
  WARNING = 'warning',
  CRITICAL = 'critical',
}

export interface Alert {
  id?: string;
  ownerID: string;
  type: AlertType;
  severity: AlertSeverity;
  title: string;
  message: string;
  jobID?: string;
  read: boolean;
  createdAt: Date;
}

/**
 * AIInsight Model - Matches iOS AIInsight.swift
 */
export interface AIInsight {
  id?: string;
  ownerID: string;
  insight: string;  // Single insight text (replaces title + message)
  category: string;  // Freeform: "cost", "profit", "labor", "efficiency", etc.
  severity: 'info' | 'warning' | 'critical';
  actionable: boolean;  // Whether this insight requires action
  createdAt: Date;
}
