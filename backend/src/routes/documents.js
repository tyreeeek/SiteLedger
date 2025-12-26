/**
 * Documents Routes
 */

const express = require('express');
const { body, validationResult } = require('express-validator');
const pool = require('../database/db');
const { authenticate } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate);

/**
 * GET /api/documents
 */
router.get('/', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT d.*, j.job_name
            FROM documents d
            LEFT JOIN jobs j ON d.job_id = j.id
            WHERE d.owner_id = $1
            ORDER BY d.created_at DESC
        `, [req.user.id]);
        
        const docs = result.rows.map(d => ({
            id: d.id,
            ownerID: d.owner_id,
            jobID: d.job_id,
            jobName: d.job_name,
            fileURL: d.file_url,
            fileType: d.file_type,
            title: d.title,
            notes: d.notes,
            aiProcessed: d.ai_processed,
            aiSummary: d.ai_summary,
            aiExtractedData: d.ai_extracted_data,
            aiConfidence: d.ai_confidence ? parseFloat(d.ai_confidence) : null,
            aiFlags: d.ai_flags,
            documentCategory: d.document_category,
            createdAt: d.created_at
        }));
        
        res.json(docs);
    } catch (error) {
        console.error('Get documents error:', error);
        res.status(500).json({ error: 'Failed to fetch documents' });
    }
});

/**
 * POST /api/documents
 */
router.post('/', [
    body('fileURL').notEmpty(),
    body('title').trim().notEmpty(),
    body('fileType').isIn(['pdf', 'image', 'other'])
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }
        
        const {
            jobID, fileURL, fileType, title, notes,
            aiProcessed, aiSummary, aiExtractedData, aiConfidence, aiFlags, documentCategory
        } = req.body;
        
        const result = await pool.query(`
            INSERT INTO documents (
                owner_id, job_id, file_url, file_type, title, notes,
                ai_processed, ai_summary, ai_extracted_data, ai_confidence, ai_flags, document_category
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
            RETURNING *
        `, [
            req.user.id,
            jobID || null,
            fileURL,
            fileType,
            title,
            notes || '',
            aiProcessed || false,
            aiSummary || null,
            aiExtractedData ? JSON.stringify(aiExtractedData) : null,
            aiConfidence || null,
            aiFlags || null,
            documentCategory || null
        ]);
        
        const d = result.rows[0];
        
        res.status(201).json({
            id: d.id,
            ownerID: d.owner_id,
            jobID: d.job_id,
            fileURL: d.file_url,
            fileType: d.file_type,
            title: d.title,
            notes: d.notes,
            createdAt: d.created_at
        });
    } catch (error) {
        console.error('Create document error:', error);
        res.status(500).json({ error: 'Failed to create document' });
    }
});

/**
 * DELETE /api/documents/:id
 */
router.delete('/:id', async (req, res) => {
    try {
        const result = await pool.query(
            'DELETE FROM documents WHERE id = $1 AND owner_id = $2 RETURNING id',
            [req.params.id, req.user.id]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Document not found' });
        }
        
        res.json({ message: 'Document deleted' });
    } catch (error) {
        console.error('Delete document error:', error);
        res.status(500).json({ error: 'Failed to delete document' });
    }
});

module.exports = router;
