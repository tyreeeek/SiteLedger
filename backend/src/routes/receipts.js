/**
 * Receipts Routes
 * CRUD operations for receipts (document storage only)
 */

const express = require('express');
const { body, validationResult } = require('express-validator');
const pool = require('../database/db');
const { authenticate } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate);

/**
 * GET /api/receipts
 * Get all receipts for the current user
 */
router.get('/', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT r.*, j.job_name
            FROM receipts r
            LEFT JOIN jobs j ON r.job_id = j.id
            WHERE r.owner_id = $1
            ORDER BY r.created_at DESC
        `, [req.user.id]);
        
        const receipts = result.rows.map(r => ({
            id: r.id,
            ownerID: r.owner_id,
            jobID: r.job_id,
            jobName: r.job_name,
            amount: parseFloat(r.amount),
            vendor: r.vendor,
            category: r.category,
            date: r.receipt_date,
            imageURL: r.image_url,
            notes: r.notes,
            aiProcessed: r.ai_processed,
            aiConfidence: r.ai_confidence ? parseFloat(r.ai_confidence) : null,
            aiFlags: r.ai_flags,
            aiSuggestedCategory: r.ai_suggested_category,
            createdAt: r.created_at
        }));
        
        res.json(receipts);
    } catch (error) {
        console.error('Get receipts error:', error);
        res.status(500).json({ error: 'Failed to fetch receipts' });
    }
});

/**
 * GET /api/receipts/job/:jobId
 * Get receipts for a specific job
 */
router.get('/job/:jobId', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT * FROM receipts
            WHERE job_id = $1 AND owner_id = $2
            ORDER BY created_at DESC
        `, [req.params.jobId, req.user.id]);
        
        const receipts = result.rows.map(r => ({
            id: r.id,
            ownerID: r.owner_id,
            jobID: r.job_id,
            amount: parseFloat(r.amount),
            vendor: r.vendor,
            category: r.category,
            date: r.receipt_date,
            imageURL: r.image_url,
            notes: r.notes,
            aiProcessed: r.ai_processed,
            aiConfidence: r.ai_confidence ? parseFloat(r.ai_confidence) : null,
            aiFlags: r.ai_flags,
            aiSuggestedCategory: r.ai_suggested_category,
            createdAt: r.created_at
        }));
        
        res.json(receipts);
    } catch (error) {
        console.error('Get job receipts error:', error);
        res.status(500).json({ error: 'Failed to fetch receipts' });
    }
});

/**
 * POST /api/receipts
 * Create a new receipt
 */
router.post('/', [
    body('amount').isFloat({ min: 0 }),
    body('vendor').trim().notEmpty(),
    body('date').isISO8601()
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }
        
        const {
            jobID, amount, vendor, category, date, imageURL, notes,
            aiProcessed, aiConfidence, aiFlags, aiSuggestedCategory
        } = req.body;
        
        // Determine the owner_id: 
        // - If user is an owner, use their ID
        // - If user is a worker and jobID is provided, use the job owner's ID
        let ownerID = req.user.id;
        
        if (req.user.role === 'worker' && jobID) {
            // Worker is submitting a receipt for a job - use the job owner's ID
            const jobResult = await pool.query(
                'SELECT owner_id FROM jobs WHERE id = $1',
                [jobID]
            );
            
            if (jobResult.rows.length > 0) {
                ownerID = jobResult.rows[0].owner_id;
                console.log(`✅ Worker ${req.user.id} creating receipt for job ${jobID}, using owner ID: ${ownerID}`);
            } else {
                return res.status(404).json({ error: 'Job not found' });
            }
        }
        
        const result = await pool.query(`
            INSERT INTO receipts (
                owner_id, job_id, amount, vendor, category,
                receipt_date, image_url, notes,
                ai_processed, ai_confidence, ai_flags, ai_suggested_category
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
            RETURNING *
        `, [
            ownerID,
            jobID || null,
            amount,
            vendor,
            category || null,
            date,
            imageURL || null,
            notes || '',
            aiProcessed || false,
            aiConfidence || null,
            aiFlags || null,
            aiSuggestedCategory || null
        ]);
        
        const r = result.rows[0];
        
        res.status(201).json({
            id: r.id,
            ownerID: r.owner_id,
            jobID: r.job_id,
            amount: parseFloat(r.amount),
            vendor: r.vendor,
            category: r.category,
            date: r.receipt_date,
            imageURL: r.image_url,
            notes: r.notes,
            aiProcessed: r.ai_processed,
            aiConfidence: r.ai_confidence ? parseFloat(r.ai_confidence) : null,
            aiFlags: r.ai_flags,
            aiSuggestedCategory: r.ai_suggested_category,
            createdAt: r.created_at
        });
    } catch (error) {
        console.error('Create receipt error:', error);
        res.status(500).json({ error: 'Failed to create receipt' });
    }
});

/**
 * PUT /api/receipts/:id
 * Update a receipt
 */
router.put('/:id', async (req, res) => {
    try {
        const {
            jobID, amount, vendor, category, date, imageURL, notes,
            aiProcessed, aiConfidence, aiFlags, aiSuggestedCategory
        } = req.body;
        
        const result = await pool.query(`
            UPDATE receipts SET
                job_id = COALESCE($1, job_id),
                amount = COALESCE($2, amount),
                vendor = COALESCE($3, vendor),
                category = COALESCE($4, category),
                receipt_date = COALESCE($5, receipt_date),
                image_url = COALESCE($6, image_url),
                notes = COALESCE($7, notes),
                ai_processed = COALESCE($8, ai_processed),
                ai_confidence = COALESCE($9, ai_confidence),
                ai_flags = COALESCE($10, ai_flags),
                ai_suggested_category = COALESCE($11, ai_suggested_category)
            WHERE id = $12 AND owner_id = $13
            RETURNING *
        `, [
            jobID, amount, vendor, category, date, imageURL, notes,
            aiProcessed, aiConfidence, aiFlags, aiSuggestedCategory,
            req.params.id, req.user.id
        ]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Receipt not found' });
        }
        
        const r = result.rows[0];
        
        res.json({
            id: r.id,
            ownerID: r.owner_id,
            jobID: r.job_id,
            amount: parseFloat(r.amount),
            vendor: r.vendor,
            category: r.category,
            date: r.receipt_date,
            imageURL: r.image_url,
            notes: r.notes,
            aiProcessed: r.ai_processed,
            aiConfidence: r.ai_confidence ? parseFloat(r.ai_confidence) : null,
            aiFlags: r.ai_flags,
            aiSuggestedCategory: r.ai_suggested_category,
            createdAt: r.created_at
        });
    } catch (error) {
        console.error('Update receipt error:', error);
        res.status(500).json({ error: 'Failed to update receipt' });
    }
});

/**
 * DELETE /api/receipts/:id
 * Delete a receipt
 */
router.delete('/:id', async (req, res) => {
    try {
        const result = await pool.query(
            'DELETE FROM receipts WHERE id = $1 AND owner_id = $2 RETURNING id',
            [req.params.id, req.user.id]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Receipt not found' });
        }
        
        res.json({ message: 'Receipt deleted' });
    } catch (error) {
        console.error('Delete receipt error:', error);
        res.status(500).json({ error: 'Failed to delete receipt' });
    }
});

module.exports = router;
