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
        
        // Verify job belongs to user
        const jobCheck = await pool.query(
            'SELECT id FROM jobs WHERE id = $1 AND owner_id = $2',
            [jobId, req.user.userId]
        );
        
        if (jobCheck.rows.length === 0) {
            return res.status(404).json({ error: 'Job not found' });
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

// Get all payments for user
router.get('/', authenticate, async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT 
                cp.id,
                cp.job_id as "jobId",
                j.job_name as "jobName",
                cp.amount,
                cp.method,
                cp.date,
                cp.reference,
                cp.notes,
                cp.created_at as "createdAt",
                cp.created_by as "createdBy"
            FROM client_payments cp
            JOIN jobs j ON cp.job_id = j.id
            WHERE j.owner_id = $1
            ORDER BY cp.date DESC, cp.created_at DESC
        `, [req.user.userId]);
        
        res.json(result.rows);
    } catch (error) {
        console.error('Error fetching client payments:', error);
        res.status(500).json({ error: 'Failed to fetch client payments' });
    }
});

// Create new payment
router.post('/', authenticate, async (req, res) => {
    try {
        const { jobId, amount, method, date, reference, notes } = req.body;
        
        if (!jobId || !amount || !method || !date) {
            return res.status(400).json({ 
                error: 'Missing required fields: jobId, amount, method, date' 
            });
        }
        
        // Verify job belongs to user
        const jobCheck = await pool.query(
            'SELECT id FROM jobs WHERE id = $1 AND owner_id = $2',
            [jobId, req.user.userId]
        );
        
        if (jobCheck.rows.length === 0) {
            return res.status(404).json({ error: 'Job not found' });
        }
        
        const result = await pool.query(`
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
        `, [jobId, amount, method, date, reference, notes, req.user.userId]);
        
        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error('Error creating client payment:', error);
        res.status(500).json({ error: 'Failed to create client payment' });
    }
});

// Update payment
router.put('/:id', authenticate, async (req, res) => {
    try {
        const { id } = req.params;
        const { amount, method, date, reference, notes } = req.body;
        
        // Verify payment belongs to user's job
        const paymentCheck = await pool.query(`
            SELECT cp.id FROM client_payments cp
            JOIN jobs j ON cp.job_id = j.id
            WHERE cp.id = $1 AND j.owner_id = $2
        `, [id, req.user.userId]);
        
        if (paymentCheck.rows.length === 0) {
            return res.status(404).json({ error: 'Payment not found' });
        }
        
        const result = await pool.query(`
            UPDATE client_payments
            SET 
                amount = COALESCE($1, amount),
                method = COALESCE($2, method),
                date = COALESCE($3, date),
                reference = COALESCE($4, reference),
                notes = COALESCE($5, notes)
            WHERE id = $6
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
        `, [amount, method, date, reference, notes, id]);
        
        res.json(result.rows[0]);
    } catch (error) {
        console.error('Error updating client payment:', error);
        res.status(500).json({ error: 'Failed to update client payment' });
    }
});

// Delete payment
router.delete('/:id', authenticate, async (req, res) => {
    try {
        const { id } = req.params;
        
        // Verify payment belongs to user's job
        const paymentCheck = await pool.query(`
            SELECT cp.id, cp.job_id FROM client_payments cp
            JOIN jobs j ON cp.job_id = j.id
            WHERE cp.id = $1 AND j.owner_id = $2
        `, [id, req.user.userId]);
        
        if (paymentCheck.rows.length === 0) {
            return res.status(404).json({ error: 'Payment not found' });
        }
        
        await pool.query('DELETE FROM client_payments WHERE id = $1', [id]);
        
        res.json({ message: 'Payment deleted successfully' });
    } catch (error) {
        console.error('Error deleting client payment:', error);
        res.status(500).json({ error: 'Failed to delete client payment' });
    }
});

module.exports = router;
