/**
 * AI Insights Routes
 * Handles AI-generated insights and recommendations
 */

const express = require('express');
const router = express.Router();
const pool = require('../database/db');
const { authenticate } = require('../middleware/auth');
const { requirePermission } = require('../middleware/permissions');
const AIInsightsService = require('../services/ai-insights');

// Generate new AI insights for all jobs
router.post('/generate', authenticate, requirePermission('canSeeAIInsights'), async (req, res) => {
    try {
        // Fetch user's jobs
        const jobsResult = await pool.query(
            'SELECT * FROM jobs WHERE owner_id = $1 ORDER BY created_at DESC',
            [req.user.userId]
        );
        
        // Fetch all receipts
        const receiptsResult = await pool.query(
            'SELECT * FROM receipts WHERE owner_id = $1',
            [req.user.userId]
        );
        
        // Fetch all timesheets
        const timesheetsResult = await pool.query(
            'SELECT * FROM timesheets WHERE owner_id = $1',
            [req.user.userId]
        );
        
        // Generate insights using AI
        const insights = await AIInsightsService.generateInsights(
            req.user.userId,
            jobsResult.rows,
            receiptsResult.rows,
            timesheetsResult.rows
        );
        
        res.json(insights);
    } catch (error) {
        console.error('Error generating AI insights:', error);
        res.status(500).json({ error: error.message || 'Failed to generate AI insights' });
    }
});

// Generate AI insights for a specific job
router.post('/generate/:jobId', authenticate, requirePermission('canSeeAIInsights'), async (req, res) => {
    try {
        const { jobId } = req.params;
        
        // Fetch job
        const jobResult = await pool.query(
            'SELECT * FROM jobs WHERE id = $1 AND owner_id = $2',
            [jobId, req.user.userId]
        );
        
        if (jobResult.rows.length === 0) {
            return res.status(404).json({ error: 'Job not found' });
        }
        
        // Fetch job receipts
        const receiptsResult = await pool.query(
            'SELECT * FROM receipts WHERE job_id = $1',
            [jobId]
        );
        
        // Fetch job timesheets
        const timesheetsResult = await pool.query(
            'SELECT * FROM timesheets WHERE job_id = $1',
            [jobId]
        );
        
        // Generate job-specific insights
        const insights = await AIInsightsService.generateJobInsights(
            jobResult.rows[0],
            receiptsResult.rows,
            timesheetsResult.rows
        );
        
        res.json(insights);
    } catch (error) {
        console.error('Error generating job insights:', error);
        res.status(500).json({ error: error.message || 'Failed to generate job insights' });
    }
});

// Get all insights
router.get('/', authenticate, async (req, res) => {
    try {
        const { jobId, type } = req.query;
        
        let query = `
            SELECT 
                ai.id,
                ai.job_id as "jobId",
                ai.job_name as "jobName",
                ai.type,
                ai.title,
                ai.summary,
                ai.details,
                ai.confidence,
                ai.recommendations,
                ai.created_at as "createdAt"
            FROM ai_insights ai
            JOIN jobs j ON ai.job_id = j.id
            WHERE j.owner_id = $1
        `;
        
        const params = [req.user.userId];
        
        if (jobId) {
            params.push(jobId);
            query += ` AND ai.job_id = $${params.length}`;
        }
        
        if (type) {
            params.push(type);
            query += ` AND ai.type = $${params.length}`;
        }
        
        query += ' ORDER BY ai.created_at DESC';
        
        const result = await pool.query(query, params);
        res.json(result.rows);
    } catch (error) {
        console.error('Error fetching AI insights:', error);
        res.status(500).json({ error: 'Failed to fetch AI insights' });
    }
});

// Get insight by ID
router.get('/:id', authenticate, async (req, res) => {
    try {
        const { id } = req.params;
        
        const result = await pool.query(`
            SELECT 
                ai.id,
                ai.job_id as "jobId",
                ai.job_name as "jobName",
                ai.type,
                ai.title,
                ai.summary,
                ai.details,
                ai.confidence,
                ai.recommendations,
                ai.created_at as "createdAt"
            FROM ai_insights ai
            JOIN jobs j ON ai.job_id = j.id
            WHERE ai.id = $1 AND j.owner_id = $2
        `, [id, req.user.userId]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Insight not found' });
        }
        
        res.json(result.rows[0]);
    } catch (error) {
        console.error('Error fetching AI insight:', error);
        res.status(500).json({ error: 'Failed to fetch AI insight' });
    }
});

// Create new insight
router.post('/', authenticate, async (req, res) => {
    try {
        const { jobId, jobName, type, title, summary, details, confidence, recommendations } = req.body;
        
        if (!jobId || !type || !title || !summary) {
            return res.status(400).json({ 
                error: 'Missing required fields: jobId, type, title, summary' 
            });
        }
        
        // Verify job belongs to user
        const jobCheck = await pool.query(
            'SELECT id, job_name FROM jobs WHERE id = $1 AND owner_id = $2',
            [jobId, req.user.userId]
        );
        
        if (jobCheck.rows.length === 0) {
            return res.status(404).json({ error: 'Job not found' });
        }
        
        const actualJobName = jobName || jobCheck.rows[0].job_name;
        
        const result = await pool.query(`
            INSERT INTO ai_insights (job_id, job_name, type, title, summary, details, confidence, recommendations)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            RETURNING 
                id,
                job_id as "jobId",
                job_name as "jobName",
                type,
                title,
                summary,
                details,
                confidence,
                recommendations,
                created_at as "createdAt"
        `, [jobId, actualJobName, type, title, summary, details, confidence, recommendations]);
        
        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error('Error creating AI insight:', error);
        res.status(500).json({ error: 'Failed to create AI insight' });
    }
});

// Delete insight
router.delete('/:id', authenticate, async (req, res) => {
    try {
        const { id } = req.params;
        
        // Verify insight belongs to user's job
        const insightCheck = await pool.query(`
            SELECT ai.id FROM ai_insights ai
            JOIN jobs j ON ai.job_id = j.id
            WHERE ai.id = $1 AND j.owner_id = $2
        `, [id, req.user.userId]);
        
        if (insightCheck.rows.length === 0) {
            return res.status(404).json({ error: 'Insight not found' });
        }
        
        await pool.query('DELETE FROM ai_insights WHERE id = $1', [id]);
        
        res.json({ message: 'Insight deleted successfully' });
    } catch (error) {
        console.error('Error deleting AI insight:', error);
        res.status(500).json({ error: 'Failed to delete AI insight' });
    }
});

module.exports = router;
