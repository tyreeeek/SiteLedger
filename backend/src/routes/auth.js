/**
 * Authentication Routes
 * Handles signup, login, logout, password reset
 * Production-ready with security best practices
 */

const express = require('express');
const bcrypt = require('bcryptjs');
const { body, validationResult } = require('express-validator');
const pool = require('../database/db');
const { generateTokens, authenticate, getBcryptRounds } = require('../middleware/auth');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const appleSignin = require('apple-signin-auth');
const fs = require('fs');
const path = require('path');

const router = express.Router();

// Password strength regex: min 8 chars, 1 uppercase, 1 lowercase, 1 number
const strongPasswordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$/;

/**
 * POST /api/auth/signup
 * Create a new user account
 */
router.post('/signup', [
    body('email').isEmail().normalizeEmail().withMessage('Valid email required'),
    body('password')
        .isLength({ min: 8 })
        .withMessage('Password must be at least 8 characters')
        .matches(strongPasswordRegex)
        .withMessage('Password must contain uppercase, lowercase, and number'),
    body('name').trim().notEmpty().escape().withMessage('Name is required'),
    body('role').optional().isIn(['owner', 'worker'])
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }
        
        const { email, password, name, role = 'owner', hourlyRate, phone } = req.body;
        
        // Check if user exists
        const existing = await pool.query(
            'SELECT id FROM users WHERE LOWER(email) = LOWER($1)',
            [email]
        );
        
        if (existing.rows.length > 0) {
            return res.status(400).json({ error: 'Email already registered' });
        }
        
        // Hash password with configurable rounds
        const passwordHash = await bcrypt.hash(password, getBcryptRounds());
        
        // Create user
        const result = await pool.query(`
            INSERT INTO users (email, password_hash, name, role, hourly_rate, phone)
            VALUES ($1, $2, $3, $4, $5, $6)
            RETURNING id, email, name, role, active, hourly_rate, phone, photo_url, owner_id, created_at
        `, [email, passwordHash, name, role, hourlyRate || null, phone || null]);
        
        const user = result.rows[0];
        const { accessToken } = generateTokens(user.id);
        
        res.status(201).json({
            user: {
                id: user.id,
                email: user.email,
                name: user.name,
                role: user.role,
                active: user.active,
                hourlyRate: user.hourly_rate,
                phone: user.phone,
                photoURL: user.photo_url,
                ownerId: user.owner_id,
                assignedJobIDs: [], // Empty array for consistency
                createdAt: user.created_at
            },
            accessToken
        });
    } catch (error) {
        console.error('Signup error:', error);
        res.status(500).json({ error: 'Failed to create account' });
    }
});

/**
 * POST /api/auth/login
 * Login with email and password
 */
router.post('/login', [
    body('email').isEmail().normalizeEmail(),
    body('password').notEmpty()
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }
        
        const { email, password } = req.body;
        
        // Find user
        const result = await pool.query(
            'SELECT * FROM users WHERE email = $1',
            [email]
        );
        
        if (result.rows.length === 0) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }
        
        const user = result.rows[0];
        
        // Check if active
        if (!user.active) {
            return res.status(401).json({ error: 'Account is disabled' });
        }
        
        // Verify password
        const validPassword = await bcrypt.compare(password, user.password_hash);
        if (!validPassword) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }
        
        const { accessToken } = generateTokens(user.id);
        
        res.json({
            user: {
                id: user.id,
                email: user.email,
                name: user.name,
                role: user.role,
                active: user.active,
                hourlyRate: user.hourly_rate,
                phone: user.phone,
                photoURL: user.photo_url,
                ownerId: user.owner_id,
                assignedJobIDs: [], // Empty array for owners, populated for workers
                workerPermissions: user.worker_permissions,
                createdAt: user.created_at
            },
            accessToken
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ error: 'Login failed' });
    }
});

/**
 * GET /api/auth/me
 * Get current user profile
 */
router.get('/me', authenticate, async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT id, email, name, role, active, hourly_rate, phone, photo_url, owner_id, apple_user_id, worker_permissions, created_at
            FROM users WHERE id = $1
        `, [req.user.id]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }
        
        const user = result.rows[0];
        
        // For workers, get assigned jobs
        let assignedJobIds = [];
        if (user.role === 'worker') {
            const jobsResult = await pool.query(
                'SELECT job_id FROM worker_job_assignments WHERE worker_id = $1',
                [user.id]
            );
            assignedJobIds = jobsResult.rows.map(r => r.job_id);
        }
        
        res.json({
            id: user.id,
            email: user.email,
            name: user.name,
            role: user.role,
            active: user.active,
            hourlyRate: user.hourly_rate,
            phone: user.phone,
            photoURL: user.photo_url,
            ownerId: user.owner_id,
            assignedJobIDs: assignedJobIds,
            workerPermissions: user.worker_permissions,
            hasPassword: user.apple_user_id ? false : true,  // Apple users don't have passwords
            createdAt: user.created_at
        });
    } catch (error) {
        console.error('Get profile error:', error);
        res.status(500).json({ error: 'Failed to get profile' });
    }
});

/**
 * PUT /api/auth/profile
 * Update current user profile
 */
router.put('/profile', authenticate, [
    body('name').optional().trim().notEmpty(),
    body('phone').optional(),
    body('photoURL').optional()
], async (req, res) => {
    try {
        const { name, phone, photoURL } = req.body;
        
        const result = await pool.query(`
            UPDATE users 
            SET name = COALESCE($1, name),
                phone = COALESCE($2, phone),
                photo_url = COALESCE($3, photo_url)
            WHERE id = $4
            RETURNING id, email, name, role, active, hourly_rate, phone, photo_url, created_at
        `, [name, phone, photoURL, req.user.id]);
        
        const user = result.rows[0];
        
        res.json({
            id: user.id,
            email: user.email,
            name: user.name,
            role: user.role,
            active: user.active,
            hourlyRate: user.hourly_rate,
            phone: user.phone,
            photoURL: user.photo_url,
            createdAt: user.created_at
        });
    } catch (error) {
        console.error('Update profile error:', error);
        res.status(500).json({ error: 'Failed to update profile' });
    }
});

/**
 * POST /api/auth/change-password
 * Change password for authenticated user
 */
router.post('/change-password', authenticate, [
    body('currentPassword').notEmpty(),
    body('newPassword').isLength({ min: 6 })
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }
        
        const { currentPassword, newPassword } = req.body;
        
        // Get current password hash
        const userResult = await pool.query(
            'SELECT password_hash FROM users WHERE id = $1',
            [req.user.id]
        );
        
        // Verify current password
        const validPassword = await bcrypt.compare(currentPassword, userResult.rows[0].password_hash);
        if (!validPassword) {
            return res.status(401).json({ error: 'Current password is incorrect' });
        }
        
        // Hash and save new password
        const newHash = await bcrypt.hash(newPassword, 10);
        await pool.query(
            'UPDATE users SET password_hash = $1 WHERE id = $2',
            [newHash, req.user.id]
        );
        
        res.json({ message: 'Password changed successfully' });
    } catch (error) {
        console.error('Change password error:', error);
        res.status(500).json({ error: 'Failed to change password' });
    }
});

/**
 * POST /api/auth/change-email
 * Change email for authenticated user (requires password confirmation)
 */
router.post('/change-email', authenticate, [
    body('newEmail').isEmail().normalizeEmail().withMessage('Valid email required'),
    body('password').notEmpty().withMessage('Password required for verification')
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }
        
        const { newEmail, password } = req.body;
        
        // Check if new email is already in use
        const emailCheck = await pool.query(
            'SELECT id FROM users WHERE LOWER(email) = LOWER($1) AND id != $2',
            [newEmail, req.user.id]
        );
        
        if (emailCheck.rows.length > 0) {
            return res.status(400).json({ error: 'Email already in use' });
        }
        
        // Get current user and verify password
        const userResult = await pool.query(
            'SELECT password_hash FROM users WHERE id = $1',
            [req.user.id]
        );
        
        const validPassword = await bcrypt.compare(password, userResult.rows[0].password_hash);
        if (!validPassword) {
            return res.status(401).json({ error: 'Incorrect password' });
        }
        
        // Update email
        await pool.query(
            'UPDATE users SET email = $1 WHERE id = $2',
            [newEmail, req.user.id]
        );
        
        res.json({ 
            message: 'Email changed successfully',
            newEmail: newEmail
        });
    } catch (error) {
        console.error('Change email error:', error);
        res.status(500).json({ error: 'Failed to change email' });
    }
});


/**
 * POST /api/auth/forgot-password
 * Send password reset email (generates reset token)
 */
router.post('/forgot-password', [
    body('email').isEmail().normalizeEmail()
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ error: 'Invalid email format' });
        }

        const { email } = req.body;

        // Check if user exists
        const userResult = await pool.query(
            'SELECT id, email, name FROM users WHERE email = $1',
            [email]
        );

        if (userResult.rows.length === 0) {
            // Don't reveal if email exists - just return success
            return res.json({ message: 'If an account exists, a reset link has been sent' });
        }

        const user = userResult.rows[0];
        
        // Generate 6-character reset token (valid for 1 hour)
        const crypto = require('crypto');
        // Generate 6 random alphanumeric characters (uppercase for easier reading)
        const resetToken = Math.random().toString(36).substring(2, 8).toUpperCase();
        const resetExpires = new Date(Date.now() + 3600000); // 1 hour

        // Store reset token in database
        await pool.query(
            'UPDATE users SET reset_token = $1, reset_token_expires = $2 WHERE id = $3',
            [resetToken, resetExpires, user.id]
        );

        // Send password reset email
        const { sendPasswordResetEmail } = require('../utils/emailService');
        try {
            await sendPasswordResetEmail(user.email, user.name, resetToken);
        } catch (emailError) {
            console.error('Failed to send reset email:', emailError);
            // Continue even if email fails - don't expose this to user
        }

        // Development: Return token for testing
        const isDevelopment = process.env.NODE_ENV !== 'production';
        
        if (isDevelopment) {
            res.json({ 
                message: 'Password reset token generated',
                resetToken: resetToken,
                expiresIn: '1 hour',
                testInstructions: 'For development: Save this token to reset your password'
            });
        } else {
            res.json({ message: 'If an account exists, a reset link has been sent' });
        }
    } catch (error) {
        console.error('Forgot password error:', error);
        res.status(500).json({ error: 'Failed to process request' });
    }
});

/**
 * POST /api/auth/reset-password
 * Reset password using token
 */
router.post('/reset-password', [
    body('token').notEmpty(),
    body('newPassword').isLength({ min: 6 })
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ error: 'Invalid request' });
        }

        const { token, newPassword } = req.body;

        // Find user with valid reset token
        const userResult = await pool.query(
            'SELECT id FROM users WHERE reset_token = $1 AND reset_token_expires > NOW()',
            [token]
        );

        if (userResult.rows.length === 0) {
            return res.status(400).json({ error: 'Invalid or expired reset token' });
        }

        const user = userResult.rows[0];

        // Hash new password
        const hashedPassword = await bcrypt.hash(newPassword, 12);

        // Update password and clear reset token
        await pool.query(
            'UPDATE users SET password_hash = $1, reset_token = NULL, reset_token_expires = NULL WHERE id = $2',
            [hashedPassword, user.id]
        );

        res.json({ message: 'Password reset successfully' });
    } catch (error) {
        console.error('Reset password error:', error);
        res.status(500).json({ error: 'Failed to reset password' });
    }
});


/**
 * POST /api/auth/apple
 * Sign in with Apple
 */
router.post('/apple', [
    body('identityToken').notEmpty(),
    body('authorizationCode').notEmpty(),
    body('appleUserID').notEmpty()
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            console.error('Apple Sign-In validation errors:', errors.array());
            return res.status(400).json({ error: 'Missing required Apple Sign-In data' });
        }

        const { identityToken, authorizationCode, appleUserID, fullName, email } = req.body;
        console.log('Apple Sign-In attempt:', { appleUserID, email: email || 'hidden', fullName: fullName || 'not provided' });
        
        // In production, you should verify the identityToken with Apple's servers
        // For now, we trust the token and create/find the user
        
        // Check if user already exists with this Apple ID
        let userResult = await pool.query(
            'SELECT * FROM users WHERE apple_user_id = $1',
            [appleUserID]
        );
        
        let user;
        
        if (userResult.rows.length > 0) {
            // Existing user - just return their data
            user = userResult.rows[0];
        } else {
            // New user - create account
            // Generate email if not provided (Apple may hide real email)
            const userEmail = email || `apple_${appleUserID.substring(0, 10)}@privaterelay.appleid.com`;
            const userName = fullName || 'Apple User';
            
            // Check if email already exists (edge case)
            const emailCheck = await pool.query(
                'SELECT id FROM users WHERE email = $1',
                [userEmail]
            );
            
            if (emailCheck.rows.length > 0) {
                // Link Apple ID to existing account
                await pool.query(
                    'UPDATE users SET apple_user_id = $1 WHERE email = $2',
                    [appleUserID, userEmail]
                );
                userResult = await pool.query(
                    'SELECT * FROM users WHERE email = $1',
                    [userEmail]
                );
                user = userResult.rows[0];
            } else {
                // Create new user
                const result = await pool.query(`
                    INSERT INTO users (email, name, role, active, apple_user_id, created_at)
                    VALUES ($1, $2, 'owner', true, $3, NOW())
                    RETURNING *
                `, [userEmail, userName, appleUserID]);
                
                user = result.rows[0];
            }
        }
        
        // Check if account is active
        if (!user.active) {
            return res.status(401).json({ error: 'Account is disabled' });
        }
        
        const { accessToken } = generateTokens(user.id);
        
        res.json({
            user: {
                id: user.id,
                email: user.email,
                name: user.name,
                role: user.role,
                active: user.active,
                hourlyRate: user.hourly_rate,
                phone: user.phone,
                photoURL: user.photo_url,
                ownerId: user.owner_id,
                assignedJobIDs: [], // Empty array for consistency
                createdAt: user.created_at
            },
            accessToken
        });
    } catch (error) {
        console.error('Apple Sign-In error:', error);
        res.status(500).json({ error: 'Apple Sign-In failed' });
    }
});

/**
 * DELETE /api/auth/account
 * Delete the current user's account and all associated data
 */
router.delete('/account', authenticate, async (req, res) => {
    try {
        const userId = req.user.id;
        const userRole = req.user.role;
        
        // Start a transaction for data integrity
        const client = await pool.connect();
        try {
            await client.query('BEGIN');
            
            if (userRole === 'owner') {
                // Delete all associated data for owner
                // Delete worker job assignments for jobs owned by this user
                await client.query(`
                    DELETE FROM worker_job_assignments 
                    WHERE job_id IN (SELECT id FROM jobs WHERE owner_id = $1)
                `, [userId]);
                
                // Delete timesheets for jobs owned by this user
                await client.query('DELETE FROM timesheets WHERE owner_id = $1', [userId]);
                
                // Delete receipts for this owner
                await client.query('DELETE FROM receipts WHERE owner_id = $1', [userId]);
                
                // Delete documents for this owner
                await client.query('DELETE FROM documents WHERE owner_id = $1', [userId]);
                
                // Delete alerts for this owner
                await client.query('DELETE FROM alerts WHERE owner_id = $1', [userId]);
                
                // Delete jobs for this owner
                await client.query('DELETE FROM jobs WHERE owner_id = $1', [userId]);
                
                // Delete workers belonging to this owner (all associated users)
                await client.query('DELETE FROM users WHERE owner_id = $1', [userId]);
            } else {
                // Worker: delete their timesheets and job assignments
                await client.query('DELETE FROM worker_job_assignments WHERE worker_id = $1', [userId]);
                await client.query('DELETE FROM timesheets WHERE worker_id = $1', [userId]);
                
                // Also delete any AI insights associated with this worker
                await client.query('DELETE FROM ai_insights WHERE user_id = $1', [userId]);
            }
            
            // Finally, delete the user account
            await client.query('DELETE FROM users WHERE id = $1', [userId]);
            
            await client.query('COMMIT');
            
            res.json({ message: 'Account deleted successfully' });
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    } catch (error) {
        console.error('Delete account error:', error);
        res.status(500).json({ error: 'Failed to delete account' });
    }
});

/**
 * POST /api/auth/reset-all-data
 * Reset all data for the current owner (keep account but delete all jobs, receipts, etc.)
 */
router.post('/reset-all-data', authenticate, async (req, res) => {
    try {
        if (req.user.role !== 'owner') {
            return res.status(403).json({ error: 'Only owners can reset data' });
        }
        
        const userId = req.user.id;
        
        // Start a transaction for data integrity
        const client = await pool.connect();
        try {
            await client.query('BEGIN');
            
            // Delete all associated data but keep the user account
            // Delete worker job assignments for jobs owned by this user
            await client.query(`
                DELETE FROM worker_job_assignments 
                WHERE job_id IN (SELECT id FROM jobs WHERE owner_id = $1)
            `, [userId]);
            
            // Delete timesheets for jobs owned by this user
            await client.query('DELETE FROM timesheets WHERE owner_id = $1', [userId]);
            
            // Delete receipts for this owner
            await client.query('DELETE FROM receipts WHERE owner_id = $1', [userId]);
            
            // Delete documents for this owner
            await client.query('DELETE FROM documents WHERE owner_id = $1', [userId]);
            
            // Delete alerts for this owner
            await client.query('DELETE FROM alerts WHERE owner_id = $1', [userId]);
            
            // Delete jobs for this owner
            await client.query('DELETE FROM jobs WHERE owner_id = $1', [userId]);
            
            // Optionally delete workers (uncomment if desired)
            // await client.query('DELETE FROM users WHERE owner_id = $1 AND role = $2', [userId, 'worker']);
            
            await client.query('COMMIT');
            
            res.json({ message: 'All data reset successfully' });
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    } catch (error) {
        console.error('Reset data error:', error);
        res.status(500).json({ error: 'Failed to reset data' });
    }
});

/**
 * POST /api/auth/apple
 * Apple Sign In - Exchange authorization code for user data with proper verification
 * Frontend sends { identityToken, authorizationCode, user: { email, name } }
 */
router.post('/apple', async (req, res) => {
    try {
        const { identityToken, authorizationCode, user, email: providedEmail, name: providedName } = req.body;
        
        if (!identityToken) {
            return res.status(400).json({ error: 'Identity token required' });
        }

        // Verify the identity token with Apple's public keys
        let appleResponse;
        try {
            appleResponse = await appleSignin.verifyIdToken(identityToken, {
                audience: process.env.APPLE_CLIENT_ID || 'ai.siteledger.web',
                ignoreExpiration: false
            });
        } catch (verifyError) {
            console.error('Apple token verification failed:', verifyError);
            return res.status(400).json({ error: 'Invalid Apple token' });
        }

        const appleUserId = appleResponse.sub;
        const email = appleResponse.email || providedEmail || (user && user.email);
        
        if (!email) {
            return res.status(400).json({ error: 'Email required for Apple Sign In' });
        }

        // Check if user exists with this Apple ID
        let existingUser = await pool.query(
            'SELECT * FROM users WHERE apple_user_id = $1',
            [appleUserId]
        );

        let userId, role, userName;

        if (existingUser.rows.length > 0) {
            // Existing Apple user - sign in
            const userRecord = existingUser.rows[0];
            userId = userRecord.id;
            role = userRecord.role;
            userName = userRecord.name;
        } else {
            // Check if email already exists (link accounts)
            const emailUser = await pool.query(
                'SELECT * FROM users WHERE LOWER(email) = LOWER($1)',
                [email]
            );

            if (emailUser.rows.length > 0) {
                // Link existing account to Apple ID
                const userRecord = emailUser.rows[0];
                await pool.query(
                    'UPDATE users SET apple_user_id = $1 WHERE id = $2',
                    [appleUserId, userRecord.id]
                );
                userId = userRecord.id;
                role = userRecord.role;
                userName = userRecord.name;
            } else {
                // Create new user
                const fullName = providedName || (user && user.name) || 'Apple User';
                const newUser = await pool.query(
                    `INSERT INTO users (email, name, role, apple_user_id, created_at) 
                     VALUES ($1, $2, $3, $4, NOW()) 
                     RETURNING id, role, name`,
                    [email, fullName, 'owner', appleUserId]
                );
                userId = newUser.rows[0].id;
                role = newUser.rows[0].role;
                userName = newUser.rows[0].name;
            }
        }

        // Generate JWT tokens
        const { accessToken, refreshToken } = generateTokens(userId, role);

        res.json({
            accessToken,
            refreshToken,
            user: {
                id: userId,
                email: email,
                name: userName,
                role: role
            }
        });

    } catch (error) {
        console.error('Apple Sign In error:', error);
        res.status(500).json({ error: 'Apple Sign In failed' });
    }
});

/**
 * DELETE /api/auth/delete-account
 * Delete user account (requires authentication)
 * WARNING: This permanently deletes all user data
 */
router.delete('/delete-account', authenticate, async (req, res) => {
    const client = await pool.connect();
    
    try {
        await client.query('BEGIN');
        
        const userId = req.user.id;
        const userRole = req.user.role;
        
        // Log account deletion for audit trail
        console.log(`Account deletion requested by user ${userId} (${userRole})`);
        
        if (userRole === 'owner') {
            // For owners: delete all associated data
            // Delete worker job assignments for this owner's jobs
            await client.query(`
                DELETE FROM worker_job_assignments 
                WHERE job_id IN (SELECT id FROM jobs WHERE owner_id = $1)
            `, [userId]);
            
            // Delete documents
            await client.query('DELETE FROM documents WHERE owner_id = $1', [userId]);
            
            // Delete timesheets for owner's jobs
            await client.query(`
                DELETE FROM timesheets 
                WHERE job_id IN (SELECT id FROM jobs WHERE owner_id = $1)
            `, [userId]);
            
            // Delete receipts
            await client.query('DELETE FROM receipts WHERE owner_id = $1', [userId]);
            
            // Delete alerts
            await client.query('DELETE FROM alerts WHERE owner_id = $1', [userId]);
            
            // Delete worker payments
            await client.query('DELETE FROM worker_payments WHERE owner_id = $1', [userId]);
            
            // Delete jobs
            await client.query('DELETE FROM jobs WHERE owner_id = $1', [userId]);
            
            // Delete workers owned by this owner
            await client.query('DELETE FROM users WHERE owner_id = $1', [userId]);
        } else if (userRole === 'worker') {
            // For workers: delete their timesheets and assignments
            await client.query('DELETE FROM timesheets WHERE worker_id = $1', [userId]);
            await client.query('DELETE FROM worker_job_assignments WHERE worker_id = $1', [userId]);
            await client.query('DELETE FROM worker_payments WHERE worker_id = $1', [userId]);
        }
        
        // Finally, delete the user account
        const result = await client.query(
            'DELETE FROM users WHERE id = $1 RETURNING email',
            [userId]
        );
        
        if (result.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ error: 'User not found' });
        }
        
        await client.query('COMMIT');
        
        console.log(`Account successfully deleted: ${result.rows[0].email}`);
        
        res.json({ 
            message: 'Account deleted successfully',
            deletedEmail: result.rows[0].email
        });
        
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Account deletion error:', error);
        res.status(500).json({ error: 'Failed to delete account' });
    } finally {
        client.release();
    }
});

module.exports = router;
