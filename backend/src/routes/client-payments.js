/**
 * Client Payments Routes
 * Handles payment tracking from clients
 */

const express = require('express');
const router = express.Router();
const pool = require('../database/db');
const { authenticate } = require('../middleware/auth');

// Get all payments for a job
router.get('/job/:jobId', authenticate, async (req, res) => {
    try {
        const { jobId } = req.params;

        // Verify job ownership or worker permission
        // Simplified: Checks if user owns the job. Workers might need access later.
        const jobCheck = await pool.query(
            'SELECT id FROM jobs WHERE id = $1 AND owner_id = $2',
            [jobId, req.user.id]
        );

        if (jobCheck.rows.length === 0) {
            // Optional: Allow workers with 'view_financials' permission
            // For now, strict owner check as per requirements
            return res.status(403).json({ error: 'Access denied or Job not found' });
        }

        const result = await pool.query(`
            SELECT 
                id,
                job_id as "jobId",
                amount,
                method,
                date,
                reference,
                notes,
                created_at as "createdAt",
                created_by as "createdBy"
            FROM client_payments
            WHERE job_id = $1
            ORDER BY date DESC, created_at DESC
        `, [jobId]);

        res.json(result.rows);
    } catch (error) {
        console.error('Error fetching client payments:', error);
        res.status(500).json({ error: 'Failed to fetch client payments' });
    }
});

// Create new payment
router.post('/', authenticate, async (req, res) => {
    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        const { jobId, amount, method, date, reference, notes } = req.body;

        if (!jobId || !amount || !method || !date) {
            return res.status(400).json({
                error: 'Missing required fields: jobId, amount, method, date'
            });
        }

        // Verify job belongs to user
        const jobCheck = await client.query(
            'SELECT id, amount_paid FROM jobs WHERE id = $1 AND owner_id = $2',
            [jobId, req.user.id]
        );

        if (jobCheck.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ error: 'Job not found' });
        }

        // Insert Payment
        const result = await client.query(`
            INSERT INTO client_payments (job_id, amount, method, date, reference, notes, created_by)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING 
                id,
                job_id as "jobId",
                amount,
                method,
                date,
                reference,
                notes,
                created_at as "createdAt",
                created_by as "createdBy"
        `, [jobId, amount, method, date, reference, notes, req.user.id]);

        // Update Job Amount Paid
        await client.query(`
            UPDATE jobs 
            SET amount_paid = COALESCE(amount_paid, 0) + $1
            WHERE id = $2
        `, [amount, jobId]);

        await client.query('COMMIT');

        res.status(201).json(result.rows[0]);
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error creating client payment:', error);
        res.status(500).json({ error: 'Failed to create client payment' });
    } finally {
        client.release();
    }
});

// Delete payment
router.delete('/:id', authenticate, async (req, res) => {
    const client = await pool.connect();
    try {
        await client.query('BEGIN');
        const { id } = req.params;

        // Get payment to delete and verify ownership via job
        const paymentCheck = await client.query(`
            SELECT cp.id, cp.job_id, cp.amount 
            FROM client_payments cp
            JOIN jobs j ON cp.job_id = j.id
            WHERE cp.id = $1 AND j.owner_id = $2
        `, [id, req.user.id]);

        if (paymentCheck.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ error: 'Payment not found' });
        }

        const { job_id, amount } = paymentCheck.rows[0];

        // Delete Payment
        await client.query('DELETE FROM client_payments WHERE id = $1', [id]);

        // Update Job Amount Paid (Subtract)
        await client.query(`
            UPDATE jobs 
            SET amount_paid = GREATEST(0, COALESCE(amount_paid, 0) - $1)
            WHERE id = $2
        `, [amount, job_id]);

        await client.query('COMMIT');

        res.json({ message: 'Payment deleted successfully' });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error deleting client payment:', error);
        res.status(500).json({ error: 'Failed to delete client payment' });
    } finally {
        client.release();
    }
});

module.exports = router;
