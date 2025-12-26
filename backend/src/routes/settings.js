/**
 * Settings Routes
 * Store and retrieve user settings including worker permissions
 */

const express = require('express');
const pool = require('../database/db');
const { authenticate, requireOwner } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate);

/**
 * GET /api/settings/permissions
 * Get worker permissions for the current owner (or worker's owner)
 */
router.get('/permissions', async (req, res) => {
    try {
        let ownerId = req.user.id;
        
        // If worker, get their owner's permissions
        if (req.user.role === 'worker' && req.user.ownerId) {
            ownerId = req.user.ownerId;
        }
        
        const result = await pool.query(
            'SELECT worker_permissions FROM users WHERE id = $1',
            [ownerId]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }
        
        // Default permissions if none set
        const defaultPermissions = {
            canViewFinancials: false,
            canUploadReceipts: true,
            canApproveTimesheets: false,
            canSeeAIInsights: false,
            canViewAllJobs: false
        };
        
        const permissions = result.rows[0].worker_permissions || defaultPermissions;
        res.json(permissions);
    } catch (error) {
        console.error('Get permissions error:', error);
        res.status(500).json({ error: 'Failed to get permissions' });
    }
});

/**
 * PUT /api/settings/permissions
 * Update worker permissions (owners only)
 */
router.put('/permissions', requireOwner, async (req, res) => {
    try {
        const {
            canViewFinancials,
            canUploadReceipts,
            canApproveTimesheets,
            canSeeAIInsights,
            canViewAllJobs
        } = req.body;
        
        const permissions = {
            canViewFinancials: canViewFinancials ?? false,
            canUploadReceipts: canUploadReceipts ?? true,
            canApproveTimesheets: canApproveTimesheets ?? false,
            canSeeAIInsights: canSeeAIInsights ?? false,
            canViewAllJobs: canViewAllJobs ?? false
        };
        
        await pool.query(
            'UPDATE users SET worker_permissions = $1 WHERE id = $2',
            [JSON.stringify(permissions), req.user.id]
        );
        
        res.json({ message: 'Permissions saved', permissions });
    } catch (error) {
        console.error('Save permissions error:', error);
        res.status(500).json({ error: 'Failed to save permissions' });
    }
});

/**
 * GET /api/settings/ai
 * Get AI settings for the current owner
 */
router.get('/ai', requireOwner, async (req, res) => {
    try {
        const result = await pool.query(
            'SELECT ai_settings FROM users WHERE id = $1',
            [req.user.id]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }
        
        // Default AI settings
        const defaultSettings = {
            aiMode: 'assist',
            autoFillReceipts: true,
            autoAssignReceipts: true,
            autoCalculateLabor: true,
            autoGenerateSummaries: false,
            autoGenerateInsights: true,
            minConfidence: 85,
            flagLowConfidence: true,
            flagUnusualHours: true,
            maxDailyHours: 12,
            budgetAlertThreshold: 75
        };
        
        const settings = result.rows[0].ai_settings || defaultSettings;
        res.json(settings);
    } catch (error) {
        console.error('Get AI settings error:', error);
        res.status(500).json({ error: 'Failed to get AI settings' });
    }
});

/**
 * PUT /api/settings/ai
 * Update AI settings (owners only)
 */
router.put('/ai', requireOwner, async (req, res) => {
    try {
        const settings = req.body;
        
        await pool.query(
            'UPDATE users SET ai_settings = $1 WHERE id = $2',
            [JSON.stringify(settings), req.user.id]
        );
        
        res.json({ message: 'AI settings saved', settings });
    } catch (error) {
        console.error('Save AI settings error:', error);
        res.status(500).json({ error: 'Failed to save AI settings' });
    }
});

module.exports = router;
