/**
 * Workers Routes
 * Manage workers assigned to an owner
 */

const express = require('express');
const bcrypt = require('bcryptjs');
const { body, validationResult } = require('express-validator');
const pool = require('../database/db');
const { authenticate, requireOwner, generateTokens } = require('../middleware/auth');
const { sendWorkerInvite, sendPasswordResetNotification } = require('../utils/emailService');

const router = express.Router();
router.use(authenticate);

/**
 * GET /api/workers
 * Get all workers for the current owner
 */
router.get('/', requireOwner, async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT id, email, name, role, active, hourly_rate, phone, photo_url, 
                   assigned_job_ids, worker_permissions, created_at,
                   bank_name, account_holder_name, account_number, routing_number, account_type
            FROM users
            WHERE owner_id = $1 AND role = 'worker'
            ORDER BY name
        `, [req.user.id]);

        const workers = result.rows.map(w => ({
            id: w.id,
            email: w.email,
            name: w.name,
            role: w.role,
            active: w.active,
            hourlyRate: w.hourly_rate ? parseFloat(w.hourly_rate) : null,
            phone: w.phone,
            photoURL: w.photo_url,
            ownerId: req.user.id,
            assignedJobIDs: w.assigned_job_ids || [],
            workerPermissions: w.worker_permissions || {
                canViewFinancials: false,
                canEditTimesheets: false,
                canUploadReceipts: true,
                canViewDocuments: true,
                canChatWithAI: false
            },
            bankInfo: {
                bankName: w.bank_name,
                accountHolderName: w.account_holder_name,
                accountNumber: w.account_number,
                routingNumber: w.routing_number,
                accountType: w.account_type
            },
            createdAt: w.created_at
        }));

        res.json(workers);
    } catch (error) {
        console.error('Get workers error:', error);
        res.status(500).json({ error: 'Failed to fetch workers' });
    }
});

/**
 * POST /api/workers
 * Create a new worker (owners only)
 */
router.post('/', requireOwner, [
    body('email').isEmail().normalizeEmail(),
    body('name').trim().notEmpty(),
    body('hourlyRate').optional().isFloat({ min: 0 })
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }

        const { email, name, hourlyRate, phone, password } = req.body;

        // Check if email exists
        const existing = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
        if (existing.rows.length > 0) {
            return res.status(400).json({ error: 'Email already registered' });
        }

        // Generate temp password if not provided
        const tempPassword = password || Math.random().toString(36).slice(-8);
        const passwordHash = await bcrypt.hash(tempPassword, 10);

        const result = await pool.query(`
            INSERT INTO users (email, password_hash, name, role, hourly_rate, phone, owner_id)
            VALUES ($1, $2, $3, 'worker', $4, $5, $6)
            RETURNING id, email, name, role, active, hourly_rate, phone, created_at
        `, [email, passwordHash, name, hourlyRate || null, phone || null, req.user.id]);

        const worker = result.rows[0];

        // Send invitation email to the new worker
        try {
            await sendWorkerInvite(
                worker.email,
                worker.name,
                req.user.name || 'Your manager',
                tempPassword
            );
            console.log(`✅ Invitation email sent to ${worker.email}`);
        } catch (emailError) {
            console.error('Failed to send invitation email:', emailError);
            // Don't fail the request if email fails - worker is already created
        }

        res.status(201).json({
            id: worker.id,
            email: worker.email,
            name: worker.name,
            role: worker.role,
            active: worker.active,
            hourlyRate: worker.hourly_rate ? parseFloat(worker.hourly_rate) : null,
            phone: worker.phone,
            photoURL: worker.photo_url,
            createdAt: worker.created_at,
            tempPassword: password ? undefined : tempPassword  // Return temp password only if auto-generated
        });
    } catch (error) {
        console.error('Create worker error:', error);
        res.status(500).json({ error: 'Failed to create worker' });
    }
});

/**
 * PUT /api/workers/:id
 * Update a worker (owners only)
 */
router.put('/:id', requireOwner, async (req, res) => {
    try {
        const { name, hourlyRate, phone, active } = req.body;

        const result = await pool.query(`
            UPDATE users SET
                name = COALESCE($1, name),
                hourly_rate = COALESCE($2, hourly_rate),
                phone = COALESCE($3, phone),
                active = COALESCE($4, active)
            WHERE id = $5 AND owner_id = $6 AND role = 'worker'
            RETURNING id, email, name, role, active, hourly_rate, phone, created_at
        `, [name, hourlyRate, phone, active, req.params.id, req.user.id]);

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Worker not found' });
        }

        const worker = result.rows[0];

        res.json({
            id: worker.id,
            email: worker.email,
            name: worker.name,
            role: worker.role,
            active: worker.active,
            hourlyRate: worker.hourly_rate ? parseFloat(worker.hourly_rate) : null,
            phone: worker.phone,
            photoURL: worker.photo_url,
            createdAt: worker.created_at
        });
    } catch (error) {
        console.error('Update worker error:', error);
        res.status(500).json({ error: 'Failed to update worker' });
    }
});

/**
 * DELETE /api/workers/:id
 * Delete a worker (owners only)
 */
router.delete('/:id', requireOwner, async (req, res) => {
    try {
        const result = await pool.query(
            'DELETE FROM users WHERE id = $1 AND owner_id = $2 AND role = $3 RETURNING id',
            [req.params.id, req.user.id, 'worker']
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Worker not found' });
        }

        res.json({ message: 'Worker deleted' });
    } catch (error) {
        console.error('Delete worker error:', error);
        res.status(500).json({ error: 'Failed to delete worker' });
    }
});

/**
 * GET /api/workers/:id/assigned-jobs
 * Get jobs assigned to a worker
 */
router.get('/:id/assigned-jobs', requireOwner, async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT j.*
            FROM jobs j
            JOIN worker_job_assignments wja ON j.id = wja.job_id
            WHERE wja.worker_id = $1 AND j.owner_id = $2
            ORDER BY j.created_at DESC
        `, [req.params.id, req.user.id]);

        const jobs = result.rows.map(j => ({
            id: j.id,
            jobName: j.job_name,
            clientName: j.client_name,
            status: j.status
        }));

        res.json(jobs);
    } catch (error) {
        console.error('Get assigned jobs error:', error);
        res.status(500).json({ error: 'Failed to fetch assigned jobs' });
    }
});

/**
 * POST /api/workers/:id/reset-password
 * Reset a worker's password (owners only)
 */
router.post('/:id/reset-password', requireOwner, [
    body('newPassword').isLength({ min: 8 }).withMessage('Password must be at least 8 characters')
        .matches(/[A-Z]/).withMessage('Password must contain at least one uppercase letter')
        .matches(/[a-z]/).withMessage('Password must contain at least one lowercase letter')
        .matches(/[0-9]/).withMessage('Password must contain at least one number')
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }

        const { newPassword } = req.body;
        const workerID = req.params.id;

        // Verify worker belongs to this owner and get worker details
        const workerCheck = await pool.query(
            'SELECT id, email, name FROM users WHERE id = $1 AND owner_id = $2 AND role = $3',
            [workerID, req.user.id, 'worker']
        );

        if (workerCheck.rows.length === 0) {
            return res.status(404).json({ error: 'Worker not found' });
        }

        const worker = workerCheck.rows[0];

        // Hash new password
        const passwordHash = await bcrypt.hash(newPassword, 10);

        // Update password
        await pool.query(
            'UPDATE users SET password_hash = $1 WHERE id = $2',
            [passwordHash, workerID]
        );

        // Send notification email
        try {
            await sendPasswordResetNotification(worker.email, worker.name, newPassword);
            console.log(`✅ Password reset notification sent to ${worker.email}`);
        } catch (emailError) {
            console.error('Failed to send notification email:', emailError);
            // Continue even if email fails
        }

        res.json({ message: 'Password reset successfully' });
    } catch (error) {
        console.error('Reset password error:', error);
        res.status(500).json({ error: 'Failed to reset password' });
    }
});

/**
 * POST /api/workers/:id/send-invite
 * Send invitation email to worker (owners only)
 */
router.post('/:id/send-invite', requireOwner, async (req, res) => {
    try {
        const workerID = req.params.id;

        // Get worker details
        const result = await pool.query(
            'SELECT email, name FROM users WHERE id = $1 AND owner_id = $2 AND role = $3',
            [workerID, req.user.id, 'worker']
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Worker not found' });
        }

        const worker = result.rows[0];

        // Generate a temporary password
        const tempPassword = Math.random().toString(36).slice(-10) + 'A1'; // Ensure it meets requirements
        const passwordHash = await bcrypt.hash(tempPassword, 10);

        // Update worker's password
        await pool.query(
            'UPDATE users SET password_hash = $1 WHERE id = $2',
            [passwordHash, workerID]
        );

        // Get owner name
        const ownerResult = await pool.query(
            'SELECT name FROM users WHERE id = $1',
            [req.user.id]
        );
        const ownerName = ownerResult.rows[0]?.name || 'Your project manager';

        // Send invitation email
        try {
            await sendWorkerInvite(worker.email, worker.name, ownerName, tempPassword);
            console.log(`✅ Invitation email sent to ${worker.email}`);
        } catch (emailError) {
            console.error('Failed to send email:', emailError);
            // Continue even if email fails - still return credentials
        }

        res.json({
            message: 'Invitation sent',
            email: worker.email,
            tempPassword: tempPassword
        });
    } catch (error) {
        console.error('Send invite error:', error);
        res.status(500).json({ error: 'Failed to send invitation' });
    }
});

module.exports = router;
