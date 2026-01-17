/**
 * Notifications Routes
 * Handles in-app notifications for users
 */

const express = require('express');
const pool = require('../database/db');
const { authenticate } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate);

/**
 * GET /api/notifications
 * Get notifications for current user
 */
router.get('/', async (req, res) => {
    try {
        const { limit = 20, offset = 0 } = req.query;

        const result = await pool.query(`
            SELECT id, type, title, message, read, data, created_at
            FROM notifications
            WHERE user_id = $1
            ORDER BY created_at DESC
            LIMIT $2 OFFSET $3
        `, [req.user.id, limit, offset]);

        // Get unread count
        const countResult = await pool.query(
            'SELECT COUNT(*) as unread_count FROM notifications WHERE user_id = $1 AND read = false',
            [req.user.id]
        );

        res.json({
            notifications: result.rows,
            unreadCount: parseInt(countResult.rows[0].unread_count),
            hasMore: result.rows.length === parseInt(limit)
        });
    } catch (error) {
        console.error('Get notifications error:', error);
        res.status(500).json({ error: 'Failed to fetch notifications' });
    }
});

/**
 * PUT /api/notifications/:id/read
 * Mark notification as read
 */
router.put('/:id/read', async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(`
            UPDATE notifications
            SET read = true
            WHERE id = $1 AND user_id = $2
            RETURNING *
        `, [id, req.user.id]);

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Notification not found' });
        }

        res.json({ notification: result.rows[0] });
    } catch (error) {
        console.error('Mark notification read error:', error);
        res.status(500).json({ error: 'Failed to update notification' });
    }
});

/**
 * PUT /api/notifications/mark-all-read
 * Mark all notifications as read
 */
router.put('/mark-all-read', async (req, res) => {
    try {
        await pool.query(
            'UPDATE notifications SET read = true WHERE user_id = $1 AND read = false',
            [req.user.id]
        );

        res.json({ message: 'All notifications marked as read' });
    } catch (error) {
        console.error('Mark all notifications read error:', error);
        res.status(500).json({ error: 'Failed to update notifications' });
    }
});

/**
 * DELETE /api/notifications/:id
 * Delete a notification
 */
router.delete('/:id', async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            'DELETE FROM notifications WHERE id = $1 AND user_id = $2 RETURNING id',
            [id, req.user.id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Notification not found' });
        }

        res.json({ message: 'Notification deleted' });
    } catch (error) {
        console.error('Delete notification error:', error);
        res.status(500).json({ error: 'Failed to delete notification' });
    }
});

module.exports = router;
