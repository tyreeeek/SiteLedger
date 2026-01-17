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
const logger = require('../config/logger');

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

        const { 
            email, password, name, role = 'owner', hourlyRate, phone, 
            companyName, addressStreet, addressCity, addressState, addressZip 
        } = req.body;

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

        // Create user with new schema
        const result = await pool.query(`
            INSERT INTO users (
                email, password_hash, name, role, hourly_rate, phone, 
                company_name, address_street, address_city, address_state, address_zip
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
            RETURNING id, email, name, role, active, hourly_rate, phone, photo_url, owner_id, created_at, 
                      company_name, address_street, address_city, address_state, address_zip
        `, [
            email, passwordHash, name, role, hourlyRate || null, phone || null,
            companyName || null, addressStreet || null, addressCity || null, 
            addressState || null, addressZip || null
        ]);

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
                createdAt: user.created_at,
                companyName: user.company_name,
                addressStreet: user.address_street,
                addressCity: user.address_city,
                addressState: user.address_state,
                addressZip: user.address_zip
            },
            accessToken,
            token: accessToken // alias for clients expecting `token`
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
            accessToken,
            token: accessToken // alias for clients expecting `token`
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
            SELECT 
                id, email, name, role, active, hourly_rate, phone, photo_url, owner_id, 
                apple_user_id, worker_permissions, created_at,
                company_name, company_logo, address_street, address_city, address_state, 
                address_zip, company_phone, company_email
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

        // Get bank details if they exist
        const bankDetailsResult = await pool.query(
            'SELECT bank_name, account_holder_name, account_number, routing_number, account_type FROM users WHERE id = $1',
            [user.id]
        );
        const bankDetails = bankDetailsResult.rows[0];

        // If worker, get owner's company branding
        let companyBranding = {
            companyName: user.company_name,
            companyLogo: user.company_logo,
            addressStreet: user.address_street,
            addressCity: user.address_city,
            addressState: user.address_state,
            addressZip: user.address_zip,
            companyPhone: user.company_phone,
            companyEmail: user.company_email
        };

        if (user.role === 'worker' && user.owner_id) {
            const ownerResult = await pool.query(`
                SELECT company_name, company_logo, address_street, address_city, address_state, 
                       address_zip, company_phone, company_email
                FROM users WHERE id = $1
            `, [user.owner_id]);
            
            if (ownerResult.rows.length > 0) {
                const owner = ownerResult.rows[0];
                companyBranding = {
                    companyName: owner.company_name,
                    companyLogo: owner.company_logo,
                    addressStreet: owner.address_street,
                    addressCity: owner.address_city,
                    addressState: owner.address_state,
                    addressZip: owner.address_zip,
                    companyPhone: owner.company_phone,
                    companyEmail: owner.company_email
                };
            }
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
            createdAt: user.created_at,
            // Return bank info if user is viewing their own profile
            bankInfo: {
                bankName: bankDetails.bank_name,
                accountHolderName: bankDetails.account_holder_name,
                accountNumber: bankDetails.account_number,
                routingNumber: bankDetails.routing_number,
                accountType: bankDetails.account_type
            },
            // Company branding (from owner or worker's owner)
            ...companyBranding
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
    body('photoURL').optional(),
    body('bankInfo').optional()
], async (req, res) => {
    try {
        const { name, phone, photoURL, bankInfo } = req.body;

        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            // Update basic info
            const result = await client.query(`
                UPDATE users 
                SET name = COALESCE($1, name),
                    phone = COALESCE($2, phone),
                    photo_url = COALESCE($3, photo_url)
                WHERE id = $4
                RETURNING id, email, name, role, active, hourly_rate, phone, photo_url, created_at
            `, [name, phone, photoURL, req.user.id]);

            // Update bank info if provided
            if (bankInfo) {
                await client.query(`
                    UPDATE users 
                    SET bank_name = $1,
                        account_holder_name = $2,
                        account_number = $3,
                        routing_number = $4,
                        account_type = $5
                    WHERE id = $6
                `, [
                    bankInfo.bankName || null,
                    bankInfo.accountHolderName || null,
                    bankInfo.accountNumber || null,
                    bankInfo.routingNumber || null,
                    bankInfo.accountType || null,
                    req.user.id
                ]);
            }

            await client.query('COMMIT');

            const user = result.rows[0];

            // Fetch updated bank info to return
            const bankDetailsResult = await client.query(
                'SELECT bank_name, account_holder_name, account_number, routing_number, account_type FROM users WHERE id = $1',
                [req.user.id]
            );
            const bankDetails = bankDetailsResult.rows[0];

            res.json({
                id: user.id,
                email: user.email,
                name: user.name,
                role: user.role,
                active: user.active,
                hourlyRate: user.hourly_rate,
                phone: user.phone,
                photoURL: user.photo_url,
                createdAt: user.created_at,
                bankInfo: {
                    bankName: bankDetails.bank_name,
                    accountHolderName: bankDetails.account_holder_name,
                    accountNumber: bankDetails.account_number,
                    routingNumber: bankDetails.routing_number,
                    accountType: bankDetails.account_type
                }
            });
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
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
 * Send password reset email (generates reset token or link based on platform)
 * Body params:
 *   - email: user email
 *   - platform: 'web' or 'mobile' (optional, defaults to 'mobile')
 */
router.post('/forgot-password', [
    body('email').isEmail().normalizeEmail()
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ error: 'Invalid email format' });
        }

        const { email, platform } = req.body;
        const isWebRequest = platform === 'web';

        // Log the request details
        logger.info('Password reset requested', {
            email,
            platform: platform || 'not specified',
            isWebRequest,
            userAgent: req.headers['user-agent']
        });

        // Check if user exists
        const userResult = await pool.query(
            'SELECT id, email, name FROM users WHERE email = $1',
            [email]
        );

        if (userResult.rows.length === 0) {
            // Don't reveal if email exists - just return success
            return res.json({
                message: 'If an account exists, a reset link has been sent',
                platform: isWebRequest ? 'web' : 'mobile'
            });
        }

        const user = userResult.rows[0];

        // Generate reset token - 6-character code for both web and mobile
        const crypto = require('crypto');
        let resetToken = Math.random().toString(36).substring(2, 8).toUpperCase();

        const resetExpires = new Date(Date.now() + 3600000); // 1 hour

        // Store reset token in database
        await pool.query(
            'UPDATE users SET reset_token = $1, reset_token_expires = $2 WHERE id = $3',
            [resetToken, resetExpires, user.id]
        );

        // Send password reset email (same code-based email for both web and mobile)
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
                platform: isWebRequest ? 'web' : 'mobile',
                resetUrl: isWebRequest ? `https://siteledger.ai/reset-password?token=${resetToken}` : null,
                testInstructions: isWebRequest
                    ? 'For development: Click the reset URL above'
                    : 'For development: Save this token to reset your password'
            });
        } else {
            res.json({
                message: 'If an account exists, a reset link has been sent',
                platform: isWebRequest ? 'web' : 'mobile'
            });
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

        // Log for debugging
        logger.info('Reset password attempt', { token, tokenLength: token?.length });

        // Find user with valid reset token (case-insensitive)
        const userResult = await pool.query(
            'SELECT id FROM users WHERE UPPER(reset_token) = UPPER($1) AND reset_token_expires > NOW()',
            [token]
        );

        if (userResult.rows.length === 0) {
            // Check if token exists but is expired
            const expiredCheck = await pool.query(
                'SELECT id, reset_token_expires FROM users WHERE UPPER(reset_token) = UPPER($1)',
                [token]
            );

            if (expiredCheck.rows.length > 0) {
                logger.warn('Expired reset token used', { token });
                return res.status(400).json({ error: 'Reset code has expired. Please request a new one.' });
            }

            logger.warn('Invalid reset token used', { token });
            return res.status(400).json({ error: 'Invalid reset code. Please check the code and try again.' });
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

const APPLE_SIGNIN_CONFIG = {
    clientID: process.env.APPLE_CLIENT_ID || 'ai.siteledger.web',
    teamID: process.env.APPLE_TEAM_ID,
    keyID: process.env.APPLE_KEY_ID,
    redirectURI: process.env.APPLE_REDIRECT_URI || 'https://siteledger.ai/auth/signin',
    privateKeyPath: process.env.APPLE_PRIVATE_KEY_PATH || 'apple-private-key.p8'
};

let cachedApplePrivateKey = null;

const loadApplePrivateKey = () => {
    if (process.env.APPLE_PRIVATE_KEY && process.env.APPLE_PRIVATE_KEY.trim()) {
        if (!cachedApplePrivateKey) {
            cachedApplePrivateKey = process.env.APPLE_PRIVATE_KEY.replace(/\\n/g, '\n');
        }
        return cachedApplePrivateKey;
    }

    if (cachedApplePrivateKey) {
        return cachedApplePrivateKey;
    }

    try {
        const resolvedPath = path.resolve(__dirname, '../..', APPLE_SIGNIN_CONFIG.privateKeyPath);
        cachedApplePrivateKey = fs.readFileSync(resolvedPath, 'utf8');
        return cachedApplePrivateKey;
    } catch (readError) {
        logger.error('Failed to load Apple private key', {
            error: readError.message,
            path: APPLE_SIGNIN_CONFIG.privateKeyPath
        });
        throw readError;
    }
};

const exchangeAuthorizationCode = async (authorizationCode) => {
    if (!authorizationCode) {
        throw new Error('Authorization code is required');
    }

    const missingConfig = [];
    if (!APPLE_SIGNIN_CONFIG.teamID) missingConfig.push('APPLE_TEAM_ID');
    if (!APPLE_SIGNIN_CONFIG.keyID) missingConfig.push('APPLE_KEY_ID');

    if (missingConfig.length > 0) {
        throw new Error(`Missing Apple Sign-In configuration: ${missingConfig.join(', ')}`);
    }

    const clientSecret = await appleSignin.getClientSecret({
        clientID: APPLE_SIGNIN_CONFIG.clientID,
        teamID: APPLE_SIGNIN_CONFIG.teamID,
        keyIdentifier: APPLE_SIGNIN_CONFIG.keyID,
        privateKey: loadApplePrivateKey()
    });

    const tokenResponse = await appleSignin.getAuthorizationToken(authorizationCode, {
        clientID: APPLE_SIGNIN_CONFIG.clientID,
        clientSecret,
        redirectUri: APPLE_SIGNIN_CONFIG.redirectURI
    });

    return tokenResponse;
};

/**
 * POST /api/auth/apple
 * Apple Sign In - Flexible endpoint supporting both iOS and web formats
 * iOS sends: { identityToken, authorizationCode, appleUserID, fullName?, email? }
 * Web sends: { identityToken, authorizationCode, user: { email, name } }
 */
router.post('/apple', async (req, res) => {
    const requestStartedAt = Date.now();

    try {
        const {
            identityToken,
            authorizationCode,
            appleUserID,  // iOS format
            user,         // Web format
            email: providedEmail,
            fullName: providedFullName,
            name: providedName
        } = req.body;

        let tokenToVerify = identityToken || null;
        let appleUserId = appleUserID || null;
        let email = providedEmail || (user && user.email) || null;
        let derivedFullName = providedFullName || providedName || (user && user.name) || null;

        if (!tokenToVerify && !authorizationCode) {
            logger.warn('Apple Sign-In rejected: missing identity token and authorization code');
            return res.status(400).json({ error: 'Identity token or authorization code required' });
        }

        logger.info('Apple Sign-In request received', {
            hasIdentityToken: !!identityToken,
            hasAuthorizationCode: !!authorizationCode,
            hasAppleUserID: !!appleUserID,
            hasEmail: !!email
        });

        if (!tokenToVerify && authorizationCode) {
            try {
                const tokenResponse = await exchangeAuthorizationCode(authorizationCode);
                tokenToVerify = tokenResponse.id_token || tokenToVerify;

                const decodedFromExchange = tokenResponse.id_token ? jwt.decode(tokenResponse.id_token) : null;
                appleUserId = appleUserId || decodedFromExchange?.sub || null;
                email = email || tokenResponse.email || decodedFromExchange?.email || null;

                if (!derivedFullName) {
                    const pieces = [
                        decodedFromExchange?.given_name,
                        decodedFromExchange?.family_name
                    ].filter(Boolean);
                    if (pieces.length > 0) {
                        derivedFullName = pieces.join(' ');
                    }
                }

                logger.info('Apple authorization code exchanged successfully', {
                    hasIdentityToken: !!tokenToVerify,
                    hasAppleUserId: !!appleUserId,
                    hasEmail: !!email
                });
            } catch (exchangeError) {
                logger.error('Apple Sign-In authorization code exchange failed', {
                    error: exchangeError.message,
                });
                return res.status(400).json({ error: 'Unable to verify Apple authorization code' });
            }
        }

        let appleResponse = null;

        if (tokenToVerify) {
            try {
                appleResponse = await appleSignin.verifyIdToken(tokenToVerify, {
                    audience: APPLE_SIGNIN_CONFIG.clientID,
                    ignoreExpiration: process.env.NODE_ENV !== 'production'
                });
                appleUserId = appleUserId || appleResponse.sub;
                email = email || appleResponse.email;

                if (!derivedFullName) {
                    const pieces = [appleResponse.given_name, appleResponse.family_name].filter(Boolean);
                    if (pieces.length > 0) {
                        derivedFullName = pieces.join(' ');
                    }
                }

                logger.info('Apple identity token verified', {
                    appleUserId,
                    hasEmail: !!email
                });
            } catch (verifyError) {
                logger.warn('Apple identity token verification failed; falling back to decoded token data', {
                    error: verifyError.message
                });

                const decoded = jwt.decode(tokenToVerify);
                appleUserId = appleUserId || decoded?.sub || null;
                email = email || decoded?.email || null;

                if (!derivedFullName) {
                    const pieces = [decoded?.given_name, decoded?.family_name].filter(Boolean);
                    if (pieces.length > 0) {
                        derivedFullName = pieces.join(' ');
                    }
                }
            }
        }

        if (!appleUserId) {
            logger.error('Apple Sign-In rejected: appleUserId missing after processing');
            return res.status(400).json({ error: 'Apple User ID required' });
        }

        // Check if user exists with this Apple ID
        let existingUser = await pool.query(
            'SELECT * FROM users WHERE apple_user_id = $1',
            [appleUserId]
        );

        if (existingUser.rows.length === 0 && !email) {
            logger.error('Apple Sign-In rejected: email missing for new user registration', { appleUserId });
            return res.status(400).json({ error: 'Email required for Apple Sign In' });
        }

        let userId, role;

        if (existingUser.rows.length > 0) {
            // Existing Apple user - sign in
            const userRecord = existingUser.rows[0];
            userId = userRecord.id;
            role = userRecord.role;
        } else {
            // Check if email already exists (link accounts)
            const normalizedEmail = email?.toLowerCase();
            const emailUser = await pool.query(
                'SELECT * FROM users WHERE LOWER(email) = LOWER($1)',
                [normalizedEmail]
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
            } else {
                // Create new user
                const fullName = (derivedFullName && derivedFullName.trim()) || 'Apple User';
                logger.info('Creating new Apple user', { email: normalizedEmail, appleUserId });
                const newUser = await pool.query(
                    `INSERT INTO users (email, name, role, apple_user_id, created_at) 
                     VALUES ($1, $2, $3, $4, NOW()) 
                     RETURNING id, role`,
                    [normalizedEmail, fullName, 'owner', appleUserId]
                );
                userId = newUser.rows[0].id;
                role = newUser.rows[0].role;
            }
        }

        // Generate JWT token
        const { accessToken } = generateTokens(userId);

        // Fetch full user data to return complete profile (same as normal login)
        const fullUserResult = await pool.query(`
            SELECT id, email, name, role, active, hourly_rate, phone, photo_url, owner_id, worker_permissions, created_at
            FROM users WHERE id = $1
        `, [userId]);

        const fullUser = fullUserResult.rows[0];

        logger.info('Apple Sign-In successful', {
            userId,
            role: fullUser.role,
            durationMs: Date.now() - requestStartedAt
        });

        res.json({
            user: {
                id: fullUser.id,
                email: fullUser.email,
                name: fullUser.name,
                role: fullUser.role,
                active: fullUser.active,
                hourlyRate: fullUser.hourly_rate,
                phone: fullUser.phone,
                photoURL: fullUser.photo_url,
                ownerId: fullUser.owner_id,
                assignedJobIDs: [], // Empty array for owners
                workerPermissions: fullUser.worker_permissions,
                createdAt: fullUser.created_at
            },
            accessToken,
            token: accessToken // alias for clients expecting `token`
        });

    } catch (error) {
        logger.error('Apple Sign In error', {
            error: error.message,
            stack: error.stack
        });
        res.status(500).json({ error: 'Apple Sign In failed' });
    }
});

/**
 * POST /api/auth/google
 * Google Sign In - verify ID token and create/login user
 */
router.post('/google', async (req, res) => {
    try {
        const { credential } = req.body;

        if (!credential) {
            logger.warn('Google Sign-In rejected: missing credential');
            return res.status(400).json({ error: 'Google credential required' });
        }

        logger.info('Google Sign-In request received');

        // Verify the Google ID token
        const { OAuth2Client } = require('google-auth-library');
        const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

        const ticket = await client.verifyIdToken({
            idToken: credential,
            audience: process.env.GOOGLE_CLIENT_ID
        });

        const payload = ticket.getPayload();
        const googleUserId = payload.sub;
        const email = payload.email;
        const name = payload.name || email.split('@')[0];

        if (!googleUserId || !email) {
            logger.error('Google Sign-In rejected: missing user data');
            return res.status(400).json({ error: 'Invalid Google credential' });
        }

        // Check if user exists with this Google ID
        let existingUser = await pool.query(
            'SELECT * FROM users WHERE google_user_id = $1',
            [googleUserId]
        );

        let userId, role;

        if (existingUser.rows.length > 0) {
            // Existing Google user - sign in
            const userRecord = existingUser.rows[0];
            userId = userRecord.id;
            role = userRecord.role;
        } else {
            // Check if email already exists (link accounts)
            const emailUser = await pool.query(
                'SELECT * FROM users WHERE LOWER(email) = LOWER($1)',
                [email]
            );

            if (emailUser.rows.length > 0) {
                // Link existing account to Google ID
                const userRecord = emailUser.rows[0];
                await pool.query(
                    'UPDATE users SET google_user_id = $1 WHERE id = $2',
                    [googleUserId, userRecord.id]
                );
                userId = userRecord.id;
                role = userRecord.role;
            } else {
                // Create new user
                logger.info('Creating new Google user', { email, googleUserId });
                const newUser = await pool.query(
                    `INSERT INTO users (email, name, role, google_user_id, created_at) 
                     VALUES ($1, $2, $3, $4, NOW()) 
                     RETURNING id, role`,
                    [email, name, 'owner', googleUserId]
                );
                userId = newUser.rows[0].id;
                role = newUser.rows[0].role;
            }
        }

        // Generate JWT token
        const { accessToken } = generateTokens(userId);

        // Fetch full user data
        const fullUserResult = await pool.query(`
            SELECT id, email, name, role, active, hourly_rate, phone, photo_url, owner_id, worker_permissions, created_at
            FROM users WHERE id = $1
        `, [userId]);

        const fullUser = fullUserResult.rows[0];

        logger.info('Google Sign-In successful', { userId, role });

        res.json({
            user: {
                id: fullUser.id,
                email: fullUser.email,
                name: fullUser.name,
                role: fullUser.role,
                active: fullUser.active,
                hourlyRate: fullUser.hourly_rate,
                phone: fullUser.phone,
                photoURL: fullUser.photo_url,
                ownerId: fullUser.owner_id,
                assignedJobIDs: [],
                workerPermissions: fullUser.worker_permissions,
                createdAt: fullUser.created_at
            },
            accessToken,
            token: accessToken
        });

    } catch (error) {
        logger.error('Google Sign In error', {
            error: error.message,
            stack: error.stack
        });
        res.status(500).json({ error: 'Google Sign In failed' });
    }
});

/**
 * GET /api/auth/apple/callback
 * Apple Sign In OAuth callback - redirects to frontend with token
 */
router.get('/apple/callback', async (req, res) => {
    try {
        const { code, state } = req.query;

        logger.info('Apple callback received', { hasCode: !!code, state });

        if (!code) {
            logger.warn('Apple callback missing code');
            return res.redirect('https://siteledger.ai/auth/signin?error=apple_no_code');
        }

        // Exchange code for token via our own Apple endpoint
        const result = await exchangeAuthorizationCode(code);

        if (!result.id_token) {
            logger.error('Apple callback: no id_token in exchange result');
            return res.redirect('https://siteledger.ai/auth/signin?error=apple_token_exchange_failed');
        }

        // Verify the token
        const appleResponse = await appleSignin.verifyIdToken(result.id_token, {
            audience: APPLE_SIGNIN_CONFIG.clientID,
            ignoreExpiration: process.env.NODE_ENV !== 'production'
        });

        const appleUserId = appleResponse.sub;
        const email = appleResponse.email;

        if (!appleUserId || !email) {
            logger.error('Apple callback: missing user data', { hasUserId: !!appleUserId, hasEmail: !!email });
            return res.redirect('https://siteledger.ai/auth/signin?error=apple_missing_user_data');
        }

        // Check if user exists
        let existingUser = await pool.query(
            'SELECT * FROM users WHERE apple_user_id = $1',
            [appleUserId]
        );

        let userId, role;

        if (existingUser.rows.length > 0) {
            const userRecord = existingUser.rows[0];
            userId = userRecord.id;
            role = userRecord.role;
        } else {
            // Check if email exists
            const emailUser = await pool.query(
                'SELECT * FROM users WHERE LOWER(email) = LOWER($1)',
                [email]
            );

            if (emailUser.rows.length > 0) {
                // Link existing account
                const userRecord = emailUser.rows[0];
                await pool.query(
                    'UPDATE users SET apple_user_id = $1 WHERE id = $2',
                    [appleUserId, userRecord.id]
                );
                userId = userRecord.id;
                role = userRecord.role;
            } else {
                // Create new user
                const fullName = [appleResponse.given_name, appleResponse.family_name]
                    .filter(Boolean)
                    .join(' ') || 'Apple User';

                logger.info('Creating new Apple user', { email, appleUserId });

                const newUser = await pool.query(
                    `INSERT INTO users (email, name, role, apple_user_id, created_at) 
                     VALUES ($1, $2, $3, $4, NOW()) 
                     RETURNING id, role`,
                    [email, fullName, 'owner', appleUserId]
                );
                userId = newUser.rows[0].id;
                role = newUser.rows[0].role;
            }
        }

        // Generate JWT token
        const { accessToken } = generateTokens(userId);

        // Fetch full user data
        const fullUserResult = await pool.query(`
            SELECT id, email, name, role, active, hourly_rate, phone, photo_url, owner_id, worker_permissions, created_at
            FROM users WHERE id = $1
        `, [userId]);

        const fullUser = fullUserResult.rows[0];

        logger.info('Apple callback successful, redirecting to frontend', { userId, role });

        // Redirect to frontend with token and user data in URL
        const redirectUrl = new URL('https://siteledger.ai/auth/signin');
        redirectUrl.searchParams.set('apple_success', '1');
        redirectUrl.searchParams.set('token', accessToken);
        redirectUrl.searchParams.set('user', JSON.stringify({
            id: fullUser.id,
            email: fullUser.email,
            name: fullUser.name,
            role: fullUser.role,
            active: fullUser.active,
            hourlyRate: fullUser.hourly_rate,
            phone: fullUser.phone,
            photoURL: fullUser.photo_url,
            ownerId: fullUser.owner_id,
            assignedJobIDs: [],
            workerPermissions: fullUser.worker_permissions,
            createdAt: fullUser.created_at
        }));

        res.redirect(redirectUrl.toString());

    } catch (error) {
        logger.error('Apple callback error', {
            error: error.message,
            stack: error.stack
        });
        res.redirect('https://siteledger.ai/auth/signin?error=apple_callback_failed');
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
