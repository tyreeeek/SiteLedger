/**
 * Worker Payments Routes
 */

const express = require('express');
const { body, validationResult } = require('express-validator');
const pool = require('../database/db');
const { authenticate, requireOwner } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate);

/**
 * GET /api/payments
 * Get all worker payments for the current owner
 */
router.get('/', requireOwner, async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT * FROM worker_payments
            WHERE owner_id = $1
            ORDER BY payment_date DESC
        `, [req.user.id]);
        
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
        console.error('Get payments error:', error);
        res.status(500).json({ error: 'Failed to fetch payments' });
    }
});

/**
 * GET /api/payments/worker/:workerId
 * Get payments for a specific worker
 */
router.get('/worker/:workerId', requireOwner, async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT * FROM worker_payments
            WHERE worker_id = $1 AND owner_id = $2
            ORDER BY payment_date DESC
        `, [req.params.workerId, req.user.id]);
        
        const payments = result.rows.map(p => ({
            id: p.id,
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
        console.error('Get worker payments error:', error);
        res.status(500).json({ error: 'Failed to fetch payments' });
    }
});

/**
 * POST /api/payments
 * Create a new payment record
 */
router.post('/', requireOwner, [
    body('workerID').notEmpty(),
    body('amount').isFloat({ min: 0.01 }),
    body('paymentDate').isISO8601(),
    body('periodStart').isISO8601(),
    body('periodEnd').isISO8601(),
    body('paymentMethod').isIn(['cash', 'check', 'direct_deposit', 'venmo', 'zelle', 'paypal', 'other'])
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }
        
        const {
            workerID, amount, paymentDate, periodStart, periodEnd,
            hoursWorked, hourlyRate, calculatedEarnings,
            paymentMethod, notes, referenceNumber
        } = req.body;
        
        // Get worker name
        const workerResult = await pool.query(
            'SELECT name FROM users WHERE id = $1 AND owner_id = $2',
            [workerID, req.user.id]
        );
        
        if (workerResult.rows.length === 0) {
            return res.status(404).json({ error: 'Worker not found' });
        }
        
        const workerName = workerResult.rows[0].name;
        
        const result = await pool.query(`
            INSERT INTO worker_payments (
                owner_id, worker_id, worker_name, amount,
                payment_date, period_start, period_end,
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
            hoursWorked || 0,
            hourlyRate || 0,
            calculatedEarnings || amount,
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
        console.error('Create payment error:', error);
        res.status(500).json({ error: 'Failed to create payment' });
    }
});

/**
 * DELETE /api/payments/:id
 */
router.delete('/:id', requireOwner, async (req, res) => {
    try {
        const result = await pool.query(
            'DELETE FROM worker_payments WHERE id = $1 AND owner_id = $2 RETURNING id',
            [req.params.id, req.user.id]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Payment not found' });
        }
        
        res.json({ message: 'Payment deleted' });
    } catch (error) {
        console.error('Delete payment error:', error);
        res.status(500).json({ error: 'Failed to delete payment' });
    }
});

module.exports = router;
