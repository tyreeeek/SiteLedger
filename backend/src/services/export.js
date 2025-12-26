/**
 * Data Export Service
 * Generate CSV and PDF exports for jobs, receipts, and timesheets
 */

const pool = require('../database/db');

class ExportService {
  /**
   * Convert array of objects to CSV format
   * @param {Array} data - Array of objects to convert
   * @param {Array} columns - Column definitions [{key, label}]
   * @returns {string} CSV string
   */
  static arrayToCSV(data, columns) {
    if (!data || data.length === 0) {
      return '';
    }

    // Create header row
    const headers = columns.map(col => `"${col.label}"`).join(',');
    
    // Create data rows
    const rows = data.map(row => {
      return columns.map(col => {
        let value = row[col.key];
        
        // Handle null/undefined
        if (value === null || value === undefined) {
          return '""';
        }
        
        // Handle dates
        if (value instanceof Date) {
          value = value.toISOString().split('T')[0];
        }
        
        // Handle objects (stringify)
        if (typeof value === 'object') {
          value = JSON.stringify(value);
        }
        
        // Escape quotes and wrap in quotes
        value = String(value).replace(/"/g, '""');
        return `"${value}"`;
      }).join(',');
    }).join('\n');
    
    return `${headers}\n${rows}`;
  }

  /**
   * Export jobs to CSV
   * @param {string} userId - User ID
   * @param {string} role - User role (owner/worker)
   * @returns {Promise<{filename: string, data: string}>}
   */
  static async exportJobsCSV(userId, role) {
    let query;
    let params;

    if (role === 'owner') {
      query = `
        SELECT 
          j.id, j.job_name, j.client_name, j.address, j.status,
          j.start_date, j.end_date, j.project_value, j.amount_paid,
          (j.project_value - j.amount_paid) as remaining_balance,
          j.notes, j.created_at
        FROM jobs j
        WHERE j.owner_id = $1
        ORDER BY j.created_at DESC
      `;
      params = [userId];
    } else {
      // Workers can only export jobs they're assigned to
      query = `
        SELECT 
          j.id, j.job_name, j.client_name, j.address, j.status,
          j.start_date, j.end_date, j.created_at
        FROM jobs j
        INNER JOIN worker_job_assignments wja ON j.id = wja.job_id
        WHERE wja.worker_id = $1
        ORDER BY j.created_at DESC
      `;
      params = [userId];
    }

    const result = await pool.query(query, params);

    const columns = role === 'owner' ? [
      { key: 'id', label: 'Job ID' },
      { key: 'job_name', label: 'Job Name' },
      { key: 'client_name', label: 'Client Name' },
      { key: 'address', label: 'Address' },
      { key: 'status', label: 'Status' },
      { key: 'start_date', label: 'Start Date' },
      { key: 'end_date', label: 'End Date' },
      { key: 'project_value', label: 'Project Value' },
      { key: 'amount_paid', label: 'Amount Paid' },
      { key: 'remaining_balance', label: 'Remaining Balance' },
      { key: 'notes', label: 'Notes' },
      { key: 'created_at', label: 'Created At' }
    ] : [
      { key: 'id', label: 'Job ID' },
      { key: 'job_name', label: 'Job Name' },
      { key: 'client_name', label: 'Client Name' },
      { key: 'address', label: 'Address' },
      { key: 'status', label: 'Status' },
      { key: 'start_date', label: 'Start Date' },
      { key: 'end_date', label: 'End Date' },
      { key: 'created_at', label: 'Created At' }
    ];

    const csv = this.arrayToCSV(result.rows, columns);
    const timestamp = new Date().toISOString().split('T')[0];
    const filename = `jobs-export-${timestamp}.csv`;

    return { filename, data: csv, count: result.rows.length };
  }

  /**
   * Export receipts to CSV
   * @param {string} userId - User ID
   * @param {string} role - User role (owner/worker)
   * @param {object} permissions - User permissions (for workers)
   * @returns {Promise<{filename: string, data: string}>}
   */
  static async exportReceiptsCSV(userId, role, permissions = {}) {
    let query;
    let params;

    if (role === 'owner') {
      query = `
        SELECT 
          r.id, r.amount, r.vendor, r.receipt_date as date, r.notes,
          r.image_url, r.ai_confidence, r.created_at,
          j.job_name
        FROM receipts r
        LEFT JOIN jobs j ON r.job_id = j.id
        WHERE r.owner_id = $1
        ORDER BY r.created_at DESC
      `;
      params = [userId];
    } else {
      // Workers can export receipts if they have permission
      query = `
        SELECT 
          r.id, r.amount, r.vendor, r.receipt_date as date, r.notes,
          r.image_url, r.created_at, j.job_name
        FROM receipts r
        LEFT JOIN jobs j ON r.job_id = j.id
        INNER JOIN users u ON u.id = $1
        WHERE r.owner_id = u.owner_id
        ORDER BY r.created_at DESC
      `;
      params = [userId];
    }

    const result = await pool.query(query, params);

    const columns = [
      { key: 'id', label: 'Receipt ID' },
      { key: 'job_name', label: 'Job Name' },
      { key: 'vendor', label: 'Vendor' },
      { key: 'amount', label: 'Amount' },
      { key: 'date', label: 'Date' },
      { key: 'notes', label: 'Notes' },
      { key: 'image_url', label: 'Image URL' },
      { key: 'ai_confidence', label: 'AI Confidence' },
      { key: 'created_at', label: 'Created At' }
    ];

    const csv = this.arrayToCSV(result.rows, columns);
    const timestamp = new Date().toISOString().split('T')[0];
    const filename = `receipts-export-${timestamp}.csv`;

    return { filename, data: csv, count: result.rows.length };
  }

  /**
   * Export timesheets to CSV
   * @param {string} userId - User ID
   * @param {string} role - User role (owner/worker)
   * @returns {Promise<{filename: string, data: string}>}
   */
  static async exportTimesheetsCSV(userId, role) {
    let query;
    let params;

    if (role === 'owner') {
      query = `
        SELECT 
          t.id, t.clock_in, t.clock_out, t.hours,
          t.notes, t.status, t.created_at,
          j.job_name, u.name as worker_name
        FROM timesheets t
        LEFT JOIN jobs j ON t.job_id = j.id
        LEFT JOIN users u ON t.worker_id = u.id
        WHERE t.owner_id = $1
        ORDER BY t.created_at DESC
      `;
      params = [userId];
    } else {
      // Workers can only export their own timesheets
      query = `
        SELECT 
          t.id, t.clock_in, t.clock_out, t.hours,
          t.notes, t.status, t.created_at, j.job_name
        FROM timesheets t
        LEFT JOIN jobs j ON t.job_id = j.id
        WHERE t.worker_id = $1
        ORDER BY t.created_at DESC
      `;
      params = [userId];
    }

    const result = await pool.query(query, params);

    const columns = role === 'owner' ? [
      { key: 'id', label: 'Timesheet ID' },
      { key: 'worker_name', label: 'Worker Name' },
      { key: 'job_name', label: 'Job Name' },
      { key: 'clock_in', label: 'Clock In' },
      { key: 'clock_out', label: 'Clock Out' },
      { key: 'hours', label: 'Hours' },
      { key: 'status', label: 'Status' },
      { key: 'notes', label: 'Notes' },
      { key: 'created_at', label: 'Created At' }
    ] : [
      { key: 'id', label: 'Timesheet ID' },
      { key: 'job_name', label: 'Job Name' },
      { key: 'clock_in', label: 'Clock In' },
      { key: 'clock_out', label: 'Clock Out' },
      { key: 'hours', label: 'Hours' },
      { key: 'status', label: 'Status' },
      { key: 'notes', label: 'Notes' },
      { key: 'created_at', label: 'Created At' }
    ];

    const csv = this.arrayToCSV(result.rows, columns);
    const timestamp = new Date().toISOString().split('T')[0];
    const filename = `timesheets-export-${timestamp}.csv`;

    return { filename, data: csv, count: result.rows.length };
  }

  /**
   * Export all data (jobs + receipts + timesheets) to CSV
   * @param {string} userId - User ID
   * @param {string} role - User role (owner/worker)
   * @param {object} permissions - User permissions (for workers)
   * @returns {Promise<object>} Object with jobs, receipts, and timesheets exports
   */
  static async exportAllDataCSV(userId, role, permissions = {}) {
    const [jobs, receipts, timesheets] = await Promise.all([
      this.exportJobsCSV(userId, role),
      this.exportReceiptsCSV(userId, role, permissions),
      this.exportTimesheetsCSV(userId, role)
    ]);

    return {
      jobs,
      receipts,
      timesheets,
      totalRecords: jobs.count + receipts.count + timesheets.count
    };
  }
}

module.exports = ExportService;
