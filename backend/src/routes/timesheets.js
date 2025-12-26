/**
 * Timesheets Routes
 * Clock in/out and timesheet management
 */

const express = require('express');
const { body, validationResult } = require('express-validator');
const pool = require('../database/db');
const { authenticate, requireOwner } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate);

/**
 * GET /api/timesheets
 * Get all timesheets for the current user
 * Owners: see all timesheets for their jobs
 * Workers: see their own timesheets
 */
router.get('/', async (req, res) => {
    try {
        let result;
        
        if (req.user.role === 'owner') {
            result = await pool.query(`
                SELECT t.*, 
                    u.name as worker_name, 
                    u.hourly_rate,
                    j.job_name
                FROM timesheets t
                JOIN users u ON t.worker_id = u.id
                JOIN jobs j ON t.job_id = j.id
                WHERE t.owner_id = $1
                ORDER BY t.created_at DESC
            `, [req.user.id]);
        } else {
            result = await pool.query(`
                SELECT t.*, 
                    u.name as worker_name, 
                    u.hourly_rate,
                    j.job_name
                FROM timesheets t
                JOIN users u ON t.worker_id = u.id
                JOIN jobs j ON t.job_id = j.id
                WHERE t.worker_id = $1
                ORDER BY t.created_at DESC
            `, [req.user.id]);
        }
        
        const timesheets = result.rows.map(t => ({
            id: t.id,
            ownerID: t.owner_id,
            workerID: t.worker_id,
            workerName: t.worker_name,
            hourlyRate: t.hourly_rate ? parseFloat(t.hourly_rate) : null,
            jobID: t.job_id,
            jobName: t.job_name,
            clockIn: t.clock_in,
            clockOut: t.clock_out,
            hours: t.hours ? parseFloat(t.hours) : null,
            effectiveHours: t.hours ? parseFloat(t.hours) : 
                (t.clock_out ? (new Date(t.clock_out) - new Date(t.clock_in)) / 3600000 : 0),
            status: t.status,
            notes: t.notes,
            clockInLocation: t.clock_in_location,
            clockOutLocation: t.clock_out_location,
            clockInLatitude: t.clock_in_latitude,
            clockInLongitude: t.clock_in_longitude,
            clockOutLatitude: t.clock_out_latitude,
            clockOutLongitude: t.clock_out_longitude,
            distanceFromJobSite: t.distance_from_job_site,
            isLocationValid: t.is_location_valid,
            aiFlags: t.ai_flags,
            createdAt: t.created_at
        }));
        
        res.json(timesheets);
    } catch (error) {
        console.error('Get timesheets error:', error);
        res.status(500).json({ error: 'Failed to fetch timesheets' });
    }
});

/**
 * GET /api/timesheets/active
 * Get active (clocked-in) timesheet for current worker
 */
router.get('/active', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT t.*, j.job_name
            FROM timesheets t
            JOIN jobs j ON t.job_id = j.id
            WHERE t.worker_id = $1 AND t.status = 'working'
            LIMIT 1
        `, [req.user.id]);
        
        if (result.rows.length === 0) {
            return res.json(null);
        }
        
        const t = result.rows[0];
        
        res.json({
            id: t.id,
            jobID: t.job_id,
            jobName: t.job_name,
            clockIn: t.clock_in,
            clockInLocation: t.clock_in_location,
            clockInLatitude: t.clock_in_latitude,
            clockInLongitude: t.clock_in_longitude
        });
    } catch (error) {
        console.error('Get active timesheet error:', error);
        res.status(500).json({ error: 'Failed to fetch active timesheet' });
    }
});

/**
 * POST /api/timesheets
 * Create a timesheet manually (owners and workers)
 * For manual time entry, not real-time clock in/out
 */
router.post('/', [
    body('jobID').notEmpty(),
    body('userID').optional(),
    body('clockIn').optional().isISO8601(),
    body('clockOut').optional().isISO8601(),
    body('hours').optional().isFloat({ min: 0 }),
    body('notes').optional()
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }
        
        const { jobID, userID, clockIn, clockOut, hours, notes } = req.body;
        
        // Determine worker ID
        let workerID = userID || req.user.id;
        
        // Owners can create timesheets for workers, workers can only create for themselves
        if (req.user.role !== 'owner' && workerID !== req.user.id) {
            return res.status(403).json({ error: 'Workers can only create timesheets for themselves' });
        }
        
        // Get job info for owner_id
        const jobResult = await pool.query('SELECT owner_id FROM jobs WHERE id = $1', [jobID]);
        if (jobResult.rows.length === 0) {
            return res.status(404).json({ error: 'Job not found' });
        }
        
        // Calculate hours if clockIn and clockOut provided
        let calculatedHours = hours;
        if (!calculatedHours && clockIn && clockOut) {
            const start = new Date(clockIn);
            const end = new Date(clockOut);
            calculatedHours = (end - start) / (1000 * 60 * 60); // Convert ms to hours
        }
        
        const result = await pool.query(`
            INSERT INTO timesheets (
                owner_id, worker_id, job_id, clock_in, clock_out, hours, status, notes, created_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
            RETURNING *
        `, [
            jobResult.rows[0].owner_id,
            workerID,
            jobID,
            clockIn || new Date().toISOString(),
            clockOut || null,
            calculatedHours || null,
            clockOut ? 'completed' : 'working',
            notes || ''
        ]);
        
        const t = result.rows[0];
        
        res.status(201).json({
            id: t.id,
            ownerID: t.owner_id,
            workerID: t.worker_id,
            jobID: t.job_id,
            clockIn: t.clock_in,
            clockOut: t.clock_out,
            hours: t.hours ? parseFloat(t.hours) : null,
            status: t.status,
            notes: t.notes,
            createdAt: t.created_at
        });
    } catch (error) {
        console.error('Create timesheet error:', error);
        res.status(500).json({ error: 'Failed to create timesheet' });
    }
});

/**
 * POST /api/timesheets/clock-in
 * Clock in to a job (workers)
 */
router.post('/clock-in', [
    body('jobID').notEmpty(),
    body('latitude').optional().isFloat(),
    body('longitude').optional().isFloat()
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }
        
        // Check if already clocked in
        const existing = await pool.query(
            `SELECT id FROM timesheets WHERE worker_id = $1 AND status = 'working'`,
            [req.user.id]
        );
        
        if (existing.rows.length > 0) {
            return res.status(400).json({ error: 'Already clocked in to a job' });
        }
        
        const { jobID, latitude, longitude, location } = req.body;
        
        // Get job info for owner_id
        const jobResult = await pool.query('SELECT owner_id FROM jobs WHERE id = $1', [jobID]);
        if (jobResult.rows.length === 0) {
            return res.status(404).json({ error: 'Job not found' });
        }
        
        const result = await pool.query(`
            INSERT INTO timesheets (
                owner_id, worker_id, job_id, clock_in, status,
                clock_in_location, clock_in_latitude, clock_in_longitude, notes
            ) VALUES ($1, $2, $3, NOW(), 'working', $4, $5, $6, '')
            RETURNING *
        `, [
            jobResult.rows[0].owner_id,
            req.user.id,
            jobID,
            location || null,
            latitude || null,
            longitude || null
        ]);
        
        // Get additional data (worker name, job name)
        const detailsResult = await pool.query(`
            SELECT t.*, u.name as worker_name, j.job_name
            FROM timesheets t
            JOIN users u ON t.worker_id = u.id
            JOIN jobs j ON t.job_id = j.id
            WHERE t.id = $1
        `, [result.rows[0].id]);
        
        const t = detailsResult.rows[0];
        
        res.status(201).json({
            id: t.id,
            ownerID: t.owner_id,
            workerID: t.worker_id,
            workerName: t.worker_name,
            jobID: t.job_id,
            jobName: t.job_name,
            clockIn: t.clock_in,
            clockOut: t.clock_out,
            hours: t.hours,
            effectiveHours: t.hours,
            status: t.status,
            notes: t.notes,
            createdAt: t.created_at
        });
    } catch (error) {
        console.error('Clock in error:', error);
        res.status(500).json({ error: 'Failed to clock in' });
    }
});

/**
 * POST /api/timesheets/clock-out
 * Clock out of current job (workers)
 */
router.post('/clock-out', [
    body('latitude').optional().isFloat(),
    body('longitude').optional().isFloat()
], async (req, res) => {
    try {
        const { latitude, longitude, location, notes } = req.body;
        
        const result = await pool.query(`
            UPDATE timesheets SET
                clock_out = NOW(),
                status = 'completed',
                clock_out_location = $1,
                clock_out_latitude = $2,
                clock_out_longitude = $3,
                notes = COALESCE($4, notes),
                hours = EXTRACT(EPOCH FROM (NOW() - clock_in)) / 3600
            WHERE worker_id = $5 AND status = 'working'
            RETURNING id
        `, [
            location || null,
            latitude || null,
            longitude || null,
            notes,
            req.user.id
        ]);
        
        if (result.rows.length === 0) {
            return res.status(400).json({ error: 'Not clocked in' });
        }
        
        // Fetch complete timesheet details with JOIN
        const detailsResult = await pool.query(`
            SELECT t.*, u.name as worker_name, j.job_name
            FROM timesheets t
            JOIN users u ON t.worker_id = u.id
            JOIN jobs j ON t.job_id = j.id
            WHERE t.id = $1
        `, [result.rows[0].id]);
        
        const t = detailsResult.rows[0];
        
        res.json({
            id: t.id,
            ownerID: t.owner_id,
            workerID: t.worker_id,
            workerName: t.worker_name,
            hourlyRate: parseFloat(t.hourly_rate),
            jobID: t.job_id,
            jobName: t.job_name,
            clockIn: t.clock_in,
            clockOut: t.clock_out,
            hours: t.hours ? parseFloat(t.hours) : null,
            effectiveHours: t.effective_hours ? parseFloat(t.effective_hours) : (t.hours ? parseFloat(t.hours) : 0),
            status: t.status,
            notes: t.notes || '',
            clockInLocation: t.clock_in_location,
            clockOutLocation: t.clock_out_location,
            clockInLatitude: t.clock_in_latitude ? parseFloat(t.clock_in_latitude) : null,
            clockInLongitude: t.clock_in_longitude ? parseFloat(t.clock_in_longitude) : null,
            clockOutLatitude: t.clock_out_latitude ? parseFloat(t.clock_out_latitude) : null,
            clockOutLongitude: t.clock_out_longitude ? parseFloat(t.clock_out_longitude) : null,
            distanceFromJobSite: t.distance_from_job_site ? parseFloat(t.distance_from_job_site) : null,
            isLocationValid: t.is_location_valid,
            aiFlags: t.ai_flags ? JSON.parse(t.ai_flags) : null,
            createdAt: t.created_at
        });
    } catch (error) {
        console.error('Clock out error:', error);
        res.status(500).json({ error: 'Failed to clock out' });
    }
});

/**
 * GET /api/timesheets/job/:jobId
 * Get timesheets for a specific job
 */
router.get('/job/:jobId', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT t.*, u.name as worker_name, u.hourly_rate
            FROM timesheets t
            JOIN users u ON t.worker_id = u.id
            WHERE t.job_id = $1
            ORDER BY t.clock_in DESC
        `, [req.params.jobId]);
        
        const timesheets = result.rows.map(t => ({
            id: t.id,
            ownerID: t.owner_id,
            workerID: t.worker_id,
            workerName: t.worker_name,
            hourlyRate: t.hourly_rate ? parseFloat(t.hourly_rate) : null,
            jobID: t.job_id,
            clockIn: t.clock_in,
            clockOut: t.clock_out,
            hours: t.hours ? parseFloat(t.hours) : null,
            effectiveHours: t.hours ? parseFloat(t.hours) : 
                (t.clock_out ? (new Date(t.clock_out) - new Date(t.clock_in)) / 3600000 : 0),
            status: t.status,
            notes: t.notes,
            createdAt: t.created_at
        }));
        
        res.json(timesheets);
    } catch (error) {
        console.error('Get job timesheets error:', error);
        res.status(500).json({ error: 'Failed to fetch timesheets' });
    }
});

/**
 * PUT /api/timesheets/:id
 * Update a timesheet (owners only - for approval/editing)
 */
router.put('/:id', requireOwner, async (req, res) => {
    try {
        const { hours, status, notes, aiFlags } = req.body;
        
        const result = await pool.query(`
            UPDATE timesheets SET
                hours = COALESCE($1, hours),
                status = COALESCE($2, status),
                notes = COALESCE($3, notes),
                ai_flags = COALESCE($4, ai_flags)
            WHERE id = $5 AND owner_id = $6
            RETURNING *
        `, [hours, status, notes, aiFlags, req.params.id, req.user.id]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Timesheet not found' });
        }
        
        const t = result.rows[0];
        
        res.json({
            id: t.id,
            hours: t.hours ? parseFloat(t.hours) : null,
            status: t.status,
            notes: t.notes
        });
    } catch (error) {
        console.error('Update timesheet error:', error);
        res.status(500).json({ error: 'Failed to update timesheet' });
    }
});

/**
 * DELETE /api/timesheets/:id
 * Delete a timesheet (owners only)
 */
router.delete('/:id', requireOwner, async (req, res) => {
    try {
        const result = await pool.query(
            'DELETE FROM timesheets WHERE id = $1 AND owner_id = $2 RETURNING id',
            [req.params.id, req.user.id]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Timesheet not found' });
        }
        
        res.json({ message: 'Timesheet deleted' });
    } catch (error) {
        console.error('Delete timesheet error:', error);
        res.status(500).json({ error: 'Failed to delete timesheet' });
    }
});

module.exports = router;
