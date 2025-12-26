/**
 * Alerts Routes
 */

const express = require('express');
const pool = require('../database/db');
const { authenticate } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate);

/**
 * GET /api/alerts
 */
router.get('/', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT a.*, j.job_name
            FROM alerts a
            LEFT JOIN jobs j ON a.job_id = j.id
            WHERE a.owner_id = $1
            ORDER BY a.created_at DESC
            LIMIT 100
        `, [req.user.id]);
        
        const alerts = result.rows.map(a => ({
            id: a.id,
            ownerID: a.owner_id,
            jobID: a.job_id,
            jobName: a.job_name,
            type: a.type,
            severity: a.severity,
            title: a.title,
            message: a.message,
            actionURL: a.action_url,
            read: a.read,
            createdAt: a.created_at
        }));
        
        res.json(alerts);
    } catch (error) {
        console.error('Get alerts error:', error);
        res.status(500).json({ error: 'Failed to fetch alerts' });
    }
});

/**
 * GET /api/alerts/unread-count
 */
router.get('/unread-count', async (req, res) => {
    try {
        const result = await pool.query(
            'SELECT COUNT(*) FROM alerts WHERE owner_id = $1 AND read = false',
            [req.user.id]
        );
        
        res.json({ count: parseInt(result.rows[0].count) });
    } catch (error) {
        console.error('Get unread count error:', error);
        res.status(500).json({ error: 'Failed to get unread count' });
    }
});

/**
 * PUT /api/alerts/:id/read
 */
router.put('/:id/read', async (req, res) => {
    try {
        await pool.query(
            'UPDATE alerts SET read = true WHERE id = $1 AND owner_id = $2',
            [req.params.id, req.user.id]
        );
        
        res.json({ message: 'Alert marked as read' });
    } catch (error) {
        console.error('Mark alert read error:', error);
        res.status(500).json({ error: 'Failed to mark alert as read' });
    }
});

/**
 * PUT /api/alerts/read-all
 */
router.put('/read-all', async (req, res) => {
    try {
        await pool.query(
            'UPDATE alerts SET read = true WHERE owner_id = $1',
            [req.user.id]
        );
        
        res.json({ message: 'All alerts marked as read' });
    } catch (error) {
        console.error('Mark all read error:', error);
        res.status(500).json({ error: 'Failed to mark alerts as read' });
    }
});

/**
 * DELETE /api/alerts/:id
 */
router.delete('/:id', async (req, res) => {
    try {
        await pool.query(
            'DELETE FROM alerts WHERE id = $1 AND owner_id = $2',
            [req.params.id, req.user.id]
        );
        
        res.json({ message: 'Alert deleted' });
    } catch (error) {
        console.error('Delete alert error:', error);
        res.status(500).json({ error: 'Failed to delete alert' });
    }
});

module.exports = router;
