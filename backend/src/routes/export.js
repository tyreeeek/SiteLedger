/**
 * Data Export Routes
 * Export jobs, receipts, and timesheets as CSV files
 */

const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const ExportService = require('../services/export');

/**
 * GET /api/export/jobs
 * Export jobs to CSV
 */
router.get('/jobs', authenticate, async (req, res) => {
  try {
    const userId = req.user.id;
    const role = req.user.role;

    const result = await ExportService.exportJobsCSV(userId, role);

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename="${result.filename}"`);
    res.send(result.data);
  } catch (error) {
    console.error('Error exporting jobs:', error);
    res.status(500).json({ error: 'Failed to export jobs' });
  }
});

/**
 * GET /api/export/receipts
 * Export receipts to CSV
 */
router.get('/receipts', authenticate, async (req, res) => {
  try {
    const userId = req.user.id;
    const role = req.user.role;
    const permissions = req.user.worker_permissions || {};

    const result = await ExportService.exportReceiptsCSV(userId, role, permissions);

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename="${result.filename}"`);
    res.send(result.data);
  } catch (error) {
    console.error('Error exporting receipts:', error);
    res.status(500).json({ error: 'Failed to export receipts' });
  }
});

/**
 * GET /api/export/timesheets
 * Export timesheets to CSV
 */
router.get('/timesheets', authenticate, async (req, res) => {
  try {
    const userId = req.user.id;
    const role = req.user.role;

    const result = await ExportService.exportTimesheetsCSV(userId, role);

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename="${result.filename}"`);
    res.send(result.data);
  } catch (error) {
    console.error('Error exporting timesheets:', error);
    res.status(500).json({ error: 'Failed to export timesheets' });
  }
});

/**
 * GET /api/export/all
 * Export all data (jobs, receipts, timesheets) as separate CSV files in a JSON response
 */
router.get('/all', authenticate, async (req, res) => {
  try {
    const userId = req.user.id;
    const role = req.user.role;
    const permissions = req.user.worker_permissions || {};

    const result = await ExportService.exportAllDataCSV(userId, role, permissions);

    // Return as JSON with separate CSV data for each type
    res.json({
      message: 'Data exported successfully',
      exports: {
        jobs: {
          filename: result.jobs.filename,
          data: result.jobs.data,
          count: result.jobs.count
        },
        receipts: {
          filename: result.receipts.filename,
          data: result.receipts.data,
          count: result.receipts.count
        },
        timesheets: {
          filename: result.timesheets.filename,
          data: result.timesheets.data,
          count: result.timesheets.count
        }
      },
      totalRecords: result.totalRecords,
      exportedAt: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error exporting all data:', error);
    res.status(500).json({ error: 'Failed to export data' });
  }
});

/**
 * GET /api/export/summary
 * Get export summary (counts only, no data)
 */
router.get('/summary', authenticate, async (req, res) => {
  try {
    const userId = req.user.id;
    const role = req.user.role;
    const permissions = req.user.worker_permissions || {};

    const result = await ExportService.exportAllDataCSV(userId, role, permissions);

    res.json({
      summary: {
        jobs: result.jobs.count,
        receipts: result.receipts.count,
        timesheets: result.timesheets.count,
        total: result.totalRecords
      },
      availableFormats: ['csv'],
      role: role
    });
  } catch (error) {
    console.error('Error getting export summary:', error);
    res.status(500).json({ error: 'Failed to get export summary' });
  }
});

module.exports = router;
