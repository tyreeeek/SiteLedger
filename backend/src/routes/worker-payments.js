/**
 * Worker Payments Routes
 * Payroll and compensation tracking for workers
 */

const express = require('express');
const { body, validationResult } = require('express-validator');
const pool = require('../database/db');
const { authenticate, requireOwner } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate);

/**
 * GET /api/worker-payments
 * Get all worker payments (owner view)
 */
router.get('/', requireOwner, async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT wp.*, u.name as worker_name, u.email as worker_email
            FROM worker_payments wp
            JOIN users u ON wp.worker_id = u.id
            WHERE wp.owner_id = $1
            ORDER BY wp.payment_date DESC, wp.created_at DESC
        `, [req.user.id]);
        
        const payments = result.rows.map(p => ({
            id: p.id,
            ownerID: p.owner_id,
            workerID: p.worker_id,
            workerName: p.worker_name,
            workerEmail: p.worker_email,
            amount: parseFloat(p.amount),
            paymentDate: p.payment_date,
            periodStart: p.period_start,
            periodEnd: p.period_end,
            hoursWorked: parseFloat(p.hours_worked),
            hourlyRate: parseFloat(p.hourly_rate),
            calculatedEarnings: parseFloat(p.calculated_earnings),
            paymentMethod: p.payment_method,
            notes: p.notes,
            referenceNumber: p.reference_number,
            createdAt: p.created_at
        }));
        
        res.json(payments);
    } catch (error) {
        console.error('Get worker payments error:', error);
        res.status(500).json({ error: 'Failed to fetch worker payments' });
    }
});

/**
 * GET /api/worker-payments/worker/:workerID
 * Get payment history for a specific worker
 */
router.get('/worker/:workerID', async (req, res) => {
    try {
        const { workerID } = req.params;
        
        // Owners can view any worker's payments, workers can only view their own
        if (req.user.role !== 'owner' && workerID !== req.user.id) {
            return res.status(403).json({ error: 'Access denied' });
        }
        
        // If worker is requesting, verify they work for the owner
        let ownerFilter = '';
        let params = [workerID];
        
        if (req.user.role === 'owner') {
            ownerFilter = 'AND wp.owner_id = $2';
            params.push(req.user.id);
        }
        
        const result = await pool.query(`
            SELECT wp.*, u.name as worker_name
            FROM worker_payments wp
            JOIN users u ON wp.worker_id = u.id
            WHERE wp.worker_id = $1 ${ownerFilter}
            ORDER BY wp.payment_date DESC, wp.created_at DESC
        `, params);
        
        const payments = result.rows.map(p => ({
            id: p.id,
            ownerID: p.owner_id,
            workerID: p.worker_id,
            workerName: p.worker_name,
            amount: parseFloat(p.amount),
            paymentDate: p.payment_date,
            periodStart: p.period_start,
            periodEnd: p.period_end,
            hoursWorked: parseFloat(p.hours_worked),
            hourlyRate: parseFloat(p.hourly_rate),
            calculatedEarnings: parseFloat(p.calculated_earnings),
            paymentMethod: p.payment_method,
            notes: p.notes,
            referenceNumber: p.reference_number,
            createdAt: p.created_at
        }));
        
        res.json(payments);
    } catch (error) {
        console.error('Get worker payment history error:', error);
        res.status(500).json({ error: 'Failed to fetch payment history' });
    }
});

/**
 * GET /api/worker-payments/summary/:workerID
 * Get payroll summary for a worker
 */
router.get('/summary/:workerID', async (req, res) => {
    try {
        const { workerID } = req.params;
        
        // Owners can view any worker's summary, workers can only view their own
        if (req.user.role !== 'owner' && workerID !== req.user.id) {
            return res.status(403).json({ error: 'Access denied' });
        }
        
        let ownerFilter = '';
        let params = [workerID];
        
        if (req.user.role === 'owner') {
            ownerFilter = 'AND owner_id = $2';
            params.push(req.user.id);
        }
        
        const result = await pool.query(`
            SELECT 
                COUNT(*) as total_payments,
                SUM(amount) as total_paid,
                SUM(hours_worked) as total_hours,
                AVG(hourly_rate) as avg_hourly_rate,
                MIN(payment_date) as first_payment_date,
                MAX(payment_date) as last_payment_date
            FROM worker_payments
            WHERE worker_id = $1 ${ownerFilter}
        `, params);
        
        const summary = result.rows[0];
        
        // Get worker details
        const workerResult = await pool.query(
            'SELECT name, email, phone FROM users WHERE id = $1',
            [workerID]
        );
        
        if (workerResult.rows.length === 0) {
            return res.status(404).json({ error: 'Worker not found' });
        }
        
        const worker = workerResult.rows[0];
        
        res.json({
            workerID,
            workerName: worker.name,
            workerEmail: worker.email,
            workerPhone: worker.phone,
            totalPayments: parseInt(summary.total_payments) || 0,
            totalPaid: parseFloat(summary.total_paid) || 0,
            totalHours: parseFloat(summary.total_hours) || 0,
            avgHourlyRate: parseFloat(summary.avg_hourly_rate) || 0,
            firstPaymentDate: summary.first_payment_date,
            lastPaymentDate: summary.last_payment_date
        });
    } catch (error) {
        console.error('Get payroll summary error:', error);
        res.status(500).json({ error: 'Failed to fetch payroll summary' });
    }
});

/**
 * GET /api/worker-payments/:id
 * Get a single payment record
 */
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        
        let ownerFilter = '';
        let params = [id];
        
        if (req.user.role === 'owner') {
            ownerFilter = 'AND wp.owner_id = $2';
            params.push(req.user.id);
        } else {
            ownerFilter = 'AND wp.worker_id = $2';
            params.push(req.user.id);
        }
        
        const result = await pool.query(`
            SELECT wp.*, u.name as worker_name, u.email as worker_email
            FROM worker_payments wp
            JOIN users u ON wp.worker_id = u.id
            WHERE wp.id = $1 ${ownerFilter}
        `, params);
        
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Payment record not found' });
        }
        
        const p = result.rows[0];
        
        res.json({
            id: p.id,
            ownerID: p.owner_id,
            workerID: p.worker_id,
            workerName: p.worker_name,
            workerEmail: p.worker_email,
            amount: parseFloat(p.amount),
            paymentDate: p.payment_date,
            periodStart: p.period_start,
            periodEnd: p.period_end,
            hoursWorked: parseFloat(p.hours_worked),
            hourlyRate: parseFloat(p.hourly_rate),
            calculatedEarnings: parseFloat(p.calculated_earnings),
            paymentMethod: p.payment_method,
            notes: p.notes,
            referenceNumber: p.reference_number,
            createdAt: p.created_at
        });
    } catch (error) {
        console.error('Get payment record error:', error);
        res.status(500).json({ error: 'Failed to fetch payment record' });
    }
});

/**
 * POST /api/worker-payments
 * Create a new payment record (owners only)
 */
router.post('/', [
    requireOwner,
    body('workerID').notEmpty(),
    body('amount').isFloat({ min: 0 }),
    body('paymentDate').isISO8601(),
    body('periodStart').isISO8601(),
    body('periodEnd').isISO8601(),
    body('hoursWorked').isFloat({ min: 0 }),
    body('hourlyRate').isFloat({ min: 0 }),
    body('paymentMethod').isIn(['cash', 'check', 'bank_transfer', 'paypal', 'venmo', 'zelle', 'other'])
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }
        
        const {
            workerID,
            amount,
            paymentDate,
            periodStart,
            periodEnd,
            hoursWorked,
            hourlyRate,
            paymentMethod,
            notes,
            referenceNumber
        } = req.body;
        
        // Verify worker exists and belongs to this owner
        const workerResult = await pool.query(
            'SELECT name, owner_id FROM users WHERE id = $1',
            [workerID]
        );
        
        if (workerResult.rows.length === 0) {
            return res.status(404).json({ error: 'Worker not found' });
        }
        
        if (workerResult.rows[0].owner_id !== req.user.id) {
            return res.status(403).json({ error: 'Worker does not belong to your organization' });
        }
        
        const workerName = workerResult.rows[0].name;
        const calculatedEarnings = hoursWorked * hourlyRate;
        
        const result = await pool.query(`
            INSERT INTO worker_payments (
                owner_id, worker_id, worker_name,
                amount, payment_date, period_start, period_end,
                hours_worked, hourly_rate, calculated_earnings,
                payment_method, notes, reference_number
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
            RETURNING *
        `, [
            req.user.id,
            workerID,
            workerName,
            amount,
            paymentDate,
            periodStart,
            periodEnd,
            hoursWorked,
            hourlyRate,
            calculatedEarnings,
            paymentMethod,
            notes || null,
            referenceNumber || null
        ]);
        
        const p = result.rows[0];
        
        res.status(201).json({
            id: p.id,
            ownerID: p.owner_id,
            workerID: p.worker_id,
            workerName: p.worker_name,
            amount: parseFloat(p.amount),
            paymentDate: p.payment_date,
            periodStart: p.period_start,
            periodEnd: p.period_end,
            hoursWorked: parseFloat(p.hours_worked),
            hourlyRate: parseFloat(p.hourly_rate),
            calculatedEarnings: parseFloat(p.calculated_earnings),
            paymentMethod: p.payment_method,
            notes: p.notes,
            referenceNumber: p.reference_number,
            createdAt: p.created_at
        });
    } catch (error) {
        console.error('Create worker payment error:', error);
        res.status(500).json({ error: 'Failed to create payment record' });
    }
});

/**
 * PUT /api/worker-payments/:id
 * Update a payment record (owners only)
 */
router.put('/:id', [
    requireOwner,
    body('amount').optional().isFloat({ min: 0 }),
    body('paymentDate').optional().isISO8601(),
    body('periodStart').optional().isISO8601(),
    body('periodEnd').optional().isISO8601(),
    body('hoursWorked').optional().isFloat({ min: 0 }),
    body('hourlyRate').optional().isFloat({ min: 0 }),
    body('paymentMethod').optional().isIn(['cash', 'check', 'bank_transfer', 'paypal', 'venmo', 'zelle', 'other'])
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }
        
        const { id } = req.params;
        const {
            amount,
            paymentDate,
            periodStart,
            periodEnd,
            hoursWorked,
            hourlyRate,
            paymentMethod,
            notes,
            referenceNumber
        } = req.body;
        
        // Build update query dynamically
        const updates = [];
        const values = [];
        let paramCount = 1;
        
        if (amount !== undefined) {
            updates.push(`amount = $${paramCount++}`);
            values.push(amount);
        }
        if (paymentDate !== undefined) {
            updates.push(`payment_date = $${paramCount++}`);
            values.push(paymentDate);
        }
        if (periodStart !== undefined) {
            updates.push(`period_start = $${paramCount++}`);
            values.push(periodStart);
        }
        if (periodEnd !== undefined) {
            updates.push(`period_end = $${paramCount++}`);
            values.push(periodEnd);
        }
        if (hoursWorked !== undefined) {
            updates.push(`hours_worked = $${paramCount++}`);
            values.push(hoursWorked);
        }
        if (hourlyRate !== undefined) {
            updates.push(`hourly_rate = $${paramCount++}`);
            values.push(hourlyRate);
        }
        if (hoursWorked !== undefined || hourlyRate !== undefined) {
            // Recalculate earnings if either value changes
            updates.push(`calculated_earnings = hours_worked * hourly_rate`);
        }
        if (paymentMethod !== undefined) {
            updates.push(`payment_method = $${paramCount++}`);
            values.push(paymentMethod);
        }
        if (notes !== undefined) {
            updates.push(`notes = $${paramCount++}`);
            values.push(notes);
        }
        if (referenceNumber !== undefined) {
            updates.push(`reference_number = $${paramCount++}`);
            values.push(referenceNumber);
        }
        
        if (updates.length === 0) {
            return res.status(400).json({ error: 'No fields to update' });
        }
        
        values.push(id, req.user.id);
        
        const result = await pool.query(`
            UPDATE worker_payments
            SET ${updates.join(', ')}
            WHERE id = $${paramCount++} AND owner_id = $${paramCount}
            RETURNING *
        `, values);
        
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Payment record not found' });
        }
        
        const p = result.rows[0];
        
        res.json({
            id: p.id,
            ownerID: p.owner_id,
            workerID: p.worker_id,
            workerName: p.worker_name,
            amount: parseFloat(p.amount),
            paymentDate: p.payment_date,
            periodStart: p.period_start,
            periodEnd: p.period_end,
            hoursWorked: parseFloat(p.hours_worked),
            hourlyRate: parseFloat(p.hourly_rate),
            calculatedEarnings: parseFloat(p.calculated_earnings),
            paymentMethod: p.payment_method,
            notes: p.notes,
            referenceNumber: p.reference_number,
            createdAt: p.created_at
        });
    } catch (error) {
        console.error('Update worker payment error:', error);
        res.status(500).json({ error: 'Failed to update payment record' });
    }
});

/**
 * DELETE /api/worker-payments/:id
 * Delete a payment record (owners only)
 */
router.delete('/:id', requireOwner, async (req, res) => {
    try {
        const { id } = req.params;
        
        const result = await pool.query(
            'DELETE FROM worker_payments WHERE id = $1 AND owner_id = $2 RETURNING id',
            [id, req.user.id]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Payment record not found' });
        }
        
        res.json({ message: 'Payment record deleted successfully' });
    } catch (error) {
        console.error('Delete worker payment error:', error);
        res.status(500).json({ error: 'Failed to delete payment record' });
    }
});

module.exports = router;
