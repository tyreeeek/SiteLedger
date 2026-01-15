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
            [req.user.id]
        );
        
        // Fetch all receipts
        const receiptsResult = await pool.query(
            'SELECT * FROM receipts WHERE owner_id = $1',
            [req.user.id]
        );
        
        // Fetch all timesheets
        const timesheetsResult = await pool.query(
            'SELECT * FROM timesheets WHERE owner_id = $1',
            [req.user.id]
        );
        
        // Generate insights using AI
        const insights = await AIInsightsService.generateInsights(
            req.user.id,
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
            [jobId, req.user.id]
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

// Get all insights (no job relationship - global insights only)
router.get('/', authenticate, async (req, res) => {
    try {
        const { type } = req.query;
        
        let query = `
            SELECT 
                ai.id,
                ai.job_name as "jobName",
                ai.type,
                ai.insight,
                ai.summary,
                ai.details,
                ai.confidence,
                ai.recommendations,
                ai.actionable,
                ai.created_at as "createdAt"
            FROM ai_insights ai
            WHERE 1=1
        `;
        
        const params = [];
        
        if (type) {
            params.push(type);
            query += ` AND ai.type = $${params.length}`;
        }
        
        query += ' ORDER BY ai.created_at DESC LIMIT 50';
        
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
                ai.job_name as "jobName",
                ai.type,
                ai.insight,
                ai.summary,
                ai.details,
                ai.confidence,
                ai.recommendations,
                ai.actionable,
                ai.created_at as "createdAt"
            FROM ai_insights ai
            WHERE ai.id = $1
        `, [id]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Insight not found' });
        }
        
        res.json(result.rows[0]);
    } catch (error) {
        console.error('Error fetching AI insight:', error);
        res.status(500).json({ error: 'Failed to fetch AI insight' });
    }
});

// Create new insight (no job relationship - global insights)
router.post('/', authenticate, async (req, res) => {
    try {
        const { jobName, type, insight, summary, details, confidence, recommendations, actionable } = req.body;
        
        if (!type || !insight || !summary) {
            return res.status(400).json({ 
                error: 'Missing required fields: type, insight, summary' 
            });
        }
        
        const result = await pool.query(`
            INSERT INTO ai_insights (job_name, type, insight, summary, details, confidence, recommendations, actionable)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            RETURNING 
                id,
                job_name as "jobName",
                type,
                insight,
                summary,
                details,
                confidence,
                recommendations,
                actionable,
                created_at as "createdAt"
        `, [jobName, type, insight, summary, details, confidence, recommendations, actionable || false]);
        
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
        
        const result = await pool.query('DELETE FROM ai_insights WHERE id = $1 RETURNING id', [id]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Insight not found' });
        }
        
        res.json({ message: 'Insight deleted successfully' });
    } catch (error) {
        console.error('Error deleting AI insight:', error);
        res.status(500).json({ error: 'Failed to delete AI insight' });
    }
});

module.exports = router;
