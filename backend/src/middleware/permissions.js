/**
 * Permissions Middleware
 * Checks role-based permissions for worker users
 */

const pool = require('../database/db');

/**
 * Middleware to check if user has required permission
 * @param {string} permission - The permission to check (e.g., 'canViewFinancials')
 * @returns {Function} Express middleware
 */
const requirePermission = (permission) => {
  return async (req, res, next) => {
    try {
      const userId = req.user.id;

      // Get user's role and permissions
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
        return next();
      }

      // Workers need specific permission
      if (user.role === 'worker') {
        const permissions = user.worker_permissions || {};
        
        if (permissions[permission] === true) {
          return next();
        } else {
          return res.status(403).json({ 
            error: 'Insufficient permissions',
            required: permission,
            message: `You need '${permission}' permission to access this resource`
          });
        }
      }

      // Unknown role
      return res.status(403).json({ error: 'Invalid user role' });
    } catch (error) {
      console.error('Permission check error:', error);
      return res.status(500).json({ error: 'Permission check failed' });
    }
  };
};

/**
 * Middleware to check if user is an owner
 * @returns {Function} Express middleware
 */
const requireOwner = async (req, res, next) => {
  try {
    const userId = req.user.id;

    const userQuery = await pool.query(
      'SELECT role FROM users WHERE id = $1',
      [userId]
    );

    if (userQuery.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (userQuery.rows[0].role !== 'owner') {
      return res.status(403).json({ 
        error: 'Owner access required',
        message: 'This action can only be performed by an owner'
      });
    }

    next();
  } catch (error) {
    console.error('Owner check error:', error);
    return res.status(500).json({ error: 'Permission check failed' });
  }
};

/**
 * Middleware to check if user can access a specific job
 * Owners can access their own jobs, workers can access assigned jobs
 * @returns {Function} Express middleware
 */
const requireJobAccess = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const jobId = req.params.id || req.params.jobId || req.body.jobId;

    if (!jobId) {
      return res.status(400).json({ error: 'Job ID required' });
    }

    // Get user's role
    const userQuery = await pool.query(
      'SELECT role, owner_id, worker_permissions FROM users WHERE id = $1',
      [userId]
    );

    if (userQuery.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const user = userQuery.rows[0];

    // Get job details
    const jobQuery = await pool.query(
      'SELECT owner_id FROM jobs WHERE id = $1',
      [jobId]
    );

    if (jobQuery.rows.length === 0) {
      return res.status(404).json({ error: 'Job not found' });
    }

    const job = jobQuery.rows[0];

    // Owners can access their own jobs
    if (user.role === 'owner' && job.owner_id === userId) {
      return next();
    }

    // Workers can access jobs they're assigned to
    if (user.role === 'worker') {
      // Check if worker has canViewAllJobs permission
      const permissions = user.worker_permissions || {};
      if (permissions.canViewAllJobs === true) {
        // Verify they belong to the same owner
        if (user.owner_id === job.owner_id) {
          return next();
        }
      }

      // Check if worker is assigned to this specific job
      const assignmentQuery = await pool.query(
        'SELECT id FROM worker_job_assignments WHERE worker_id = $1 AND job_id = $2',
        [userId, jobId]
      );

      if (assignmentQuery.rows.length > 0) {
        return next();
      }
    }

    return res.status(403).json({ 
      error: 'Access denied',
      message: 'You do not have access to this job'
    });
  } catch (error) {
    console.error('Job access check error:', error);
    return res.status(500).json({ error: 'Access check failed' });
  }
};

module.exports = {
  requirePermission,
  requireOwner,
  requireJobAccess
};
