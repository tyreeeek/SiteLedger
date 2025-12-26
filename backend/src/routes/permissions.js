/**
 * Permissions Routes
 * Manage worker permissions for role-based access control
 */

const express = require('express');
const router = express.Router();
const pool = require('../database/db');
const { authenticate } = require('../middleware/auth');
const { requireOwner } = require('../middleware/permissions');

/**
 * GET /api/permissions/worker/:workerId
 * Get a worker's permissions
 */
router.get('/worker/:workerId', authenticate, requireOwner, async (req, res) => {
  try {
    const { workerId } = req.params;
    const ownerId = req.user.id;

    // Verify the worker belongs to this owner
    const workerQuery = await pool.query(
      'SELECT id, name, email, role, worker_permissions FROM users WHERE id = $1 AND owner_id = $2',
      [workerId, ownerId]
    );

    if (workerQuery.rows.length === 0) {
      return res.status(404).json({ error: 'Worker not found or not under your management' });
    }

    const worker = workerQuery.rows[0];

    res.json({
      workerId: worker.id,
      name: worker.name,
      email: worker.email,
      role: worker.role,
      permissions: worker.worker_permissions || {
        canViewFinancials: false,
        canUploadReceipts: true,
        canApproveTimesheets: false,
        canSeeAIInsights: false,
        canViewAllJobs: false
      }
    });
  } catch (error) {
    console.error('Error fetching worker permissions:', error);
    res.status(500).json({ error: 'Failed to fetch worker permissions' });
  }
});

/**
 * PUT /api/permissions/worker/:workerId
 * Update a worker's permissions
 */
router.put('/worker/:workerId', authenticate, requireOwner, async (req, res) => {
  try {
    const { workerId } = req.params;
    const ownerId = req.user.id;
    const { permissions } = req.body;

    if (!permissions || typeof permissions !== 'object') {
      return res.status(400).json({ error: 'Valid permissions object required' });
    }

    // Validate permission keys
    const validPermissions = [
      'canViewFinancials',
      'canUploadReceipts',
      'canApproveTimesheets',
      'canSeeAIInsights',
      'canViewAllJobs'
    ];

    const providedKeys = Object.keys(permissions);
    const invalidKeys = providedKeys.filter(key => !validPermissions.includes(key));

    if (invalidKeys.length > 0) {
      return res.status(400).json({ 
        error: 'Invalid permission keys',
        invalid: invalidKeys,
        valid: validPermissions
      });
    }

    // Verify the worker belongs to this owner
    const workerQuery = await pool.query(
      'SELECT id, role FROM users WHERE id = $1 AND owner_id = $2',
      [workerId, ownerId]
    );

    if (workerQuery.rows.length === 0) {
      return res.status(404).json({ error: 'Worker not found or not under your management' });
    }

    if (workerQuery.rows[0].role !== 'worker') {
      return res.status(400).json({ error: 'Can only set permissions for workers' });
    }

    // Update permissions
    const updateQuery = await pool.query(
      'UPDATE users SET worker_permissions = $1, updated_at = NOW() WHERE id = $2 RETURNING worker_permissions',
      [JSON.stringify(permissions), workerId]
    );

    res.json({
      message: 'Worker permissions updated successfully',
      workerId,
      permissions: updateQuery.rows[0].worker_permissions
    });
  } catch (error) {
    console.error('Error updating worker permissions:', error);
    res.status(500).json({ error: 'Failed to update worker permissions' });
  }
});

/**
 * GET /api/permissions/workers
 * List all workers and their permissions for the authenticated owner
 */
router.get('/workers', authenticate, requireOwner, async (req, res) => {
  try {
    const ownerId = req.user.id;

    const workersQuery = await pool.query(
      `SELECT id, name, email, role, active, worker_permissions, created_at 
       FROM users 
       WHERE owner_id = $1 AND role = 'worker' 
       ORDER BY name ASC`,
      [ownerId]
    );

    const workers = workersQuery.rows.map(worker => ({
      id: worker.id,
      name: worker.name,
      email: worker.email,
      active: worker.active,
      permissions: worker.worker_permissions || {
        canViewFinancials: false,
        canUploadReceipts: true,
        canApproveTimesheets: false,
        canSeeAIInsights: false,
        canViewAllJobs: false
      },
      createdAt: worker.created_at
    }));

    res.json({
      workers,
      count: workers.length
    });
  } catch (error) {
    console.error('Error fetching workers:', error);
    res.status(500).json({ error: 'Failed to fetch workers' });
  }
});

/**
 * GET /api/permissions/my-permissions
 * Get current user's own permissions (for workers)
 */
router.get('/my-permissions', authenticate, async (req, res) => {
  try {
    const userId = req.user.id;

    const userQuery = await pool.query(
      'SELECT role, worker_permissions FROM users WHERE id = $1',
      [userId]
    );

    if (userQuery.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const user = userQuery.rows[0];

    // Owners have all permissions
    if (user.role === 'owner') {
      return res.json({
        role: 'owner',
        permissions: {
          canViewFinancials: true,
          canUploadReceipts: true,
          canApproveTimesheets: true,
          canSeeAIInsights: true,
          canViewAllJobs: true
        }
      });
    }

    // Return worker permissions
    res.json({
      role: user.role,
      permissions: user.worker_permissions || {
        canViewFinancials: false,
        canUploadReceipts: true,
        canApproveTimesheets: false,
        canSeeAIInsights: false,
        canViewAllJobs: false
      }
    });
  } catch (error) {
    console.error('Error fetching permissions:', error);
    res.status(500).json({ error: 'Failed to fetch permissions' });
  }
});

module.exports = router;
