/**
 * Password Management Routes
 * Allows Apple Sign In users to set a password for their account
 */

const express = require('express');
const bcrypt = require('bcryptjs');
const { authenticate } = require('../middleware/auth');
const pool = require('../database/db');

const router = express.Router();

/**
 * POST /api/password/set
 * Allows a user to set a password if they signed in with Apple
 * Requires authentication
 * Body: { password: string }
 */
router.post('/set', authenticate, async (req, res) => {
    try {
        const userId = req.user.id;
        const { password } = req.body;
        if (!password || password.length < 6) {
            return res.status(400).json({ error: 'Password must be at least 6 characters' });
        }
        const passwordHash = await bcrypt.hash(password, 10);
        await pool.query('UPDATE users SET password_hash = $1 WHERE id = $2', [passwordHash, userId]);
        res.json({ message: 'Password set successfully' });
    } catch (error) {
        console.error('Set password error:', error);
        res.status(500).json({ error: 'Failed to set password' });
    }
});

module.exports = router;
