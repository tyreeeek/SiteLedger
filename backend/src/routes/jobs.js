/**
 * Jobs Routes
 * CRUD operations for jobs
 */

const express = require('express');
const { body, validationResult } = require('express-validator');
const pool = require('../database/db');
const { authenticate, requireOwner } = require('../middleware/auth');

const router = express.Router();

// Helper function to format DATE columns as YYYY-MM-DD strings
function formatDate(date) {
    if (!date) return null;
    // If it's already a string in YYYY-MM-DD format, return it
    if (typeof date === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(date)) {
        return date;
    }
    // If it's a Date object or timestamp, format it
    const d = new Date(date);
    const year = d.getUTCFullYear();
    const month = String(d.getUTCMonth() + 1).padStart(2, '0');
    const day = String(d.getUTCDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
}

// All routes require authentication
router.use(authenticate);

/**
 * GET /api/jobs
 * Get all jobs for the current user
 * Owners: get their own jobs
 * Workers: get assigned jobs
 */
router.get('/', async (req, res) => {
    try {
        let jobs;

        if (req.user.role === 'owner') {
            const result = await pool.query(`
                SELECT 
                    j.*,
                    COALESCE(
                        (SELECT SUM(t.hours * COALESCE(w.hourly_rate, 0))
                         FROM timesheets t
                         LEFT JOIN users w ON t.worker_id = w.id
                         WHERE t.job_id = j.id), 0
                    ) as labor_cost,
                    COALESCE(
                        (SELECT SUM(r.amount)
                         FROM receipts r
                         WHERE r.job_id = j.id), 0
                    ) as receipt_expenses
                FROM jobs j
                WHERE j.owner_id = $1
                ORDER BY j.created_at DESC
            `, [req.user.id]);
            jobs = result.rows;
        } else {
            // Worker: get assigned jobs
            const result = await pool.query(`
                SELECT 
                    j.*,
                    COALESCE(
                        (SELECT SUM(t.hours * COALESCE(w.hourly_rate, 0))
                         FROM timesheets t
                         LEFT JOIN users w ON t.worker_id = w.id
                         WHERE t.job_id = j.id), 0
                    ) as labor_cost,
                    COALESCE(
                        (SELECT SUM(r.amount)
                         FROM receipts r
                         WHERE r.job_id = j.id), 0
                    ) as receipt_expenses
                FROM jobs j
                JOIN worker_job_assignments wja ON j.id = wja.job_id
                WHERE wja.worker_id = $1
                ORDER BY j.created_at DESC
            `, [req.user.id]);
            jobs = result.rows;
        }

        // Get assigned workers for each job
        for (let job of jobs) {
            const workersResult = await pool.query(`
                SELECT worker_id FROM worker_job_assignments WHERE job_id = $1
            `, [job.id]);
            job.assigned_worker_ids = workersResult.rows.map(w => w.worker_id);

            // Calculate fields
            const laborCost = parseFloat(job.labor_cost || 0);
            const receiptExpenses = parseFloat(job.receipt_expenses || 0);
            const projectValue = parseFloat(job.project_value || 0);
            const amountPaid = parseFloat(job.amount_paid || 0);

            job.total_cost = laborCost + receiptExpenses;
            job.profit = projectValue - job.total_cost;
            job.remaining_balance = projectValue - amountPaid;
        }

        // Transform to camelCase
        const transformed = jobs.map(j => ({
            id: j.id,
            ownerID: j.owner_id,
            jobName: j.job_name,
            clientName: j.client_name,
            location: j.location,
            address: j.address,
            street: j.street,
            city: j.city,
            state: j.state,
            zip: j.zip,
            latitude: j.latitude,
            longitude: j.longitude,
            startDate: formatDate(j.start_date),
            endDate: formatDate(j.end_date),
            status: j.status,
            notes: j.notes,
            projectValue: parseFloat(j.project_value || 0),
            amountPaid: parseFloat(j.amount_paid || 0),
            remainingBalance: j.remaining_balance,
            totalCost: j.total_cost,
            profit: j.profit,
            assignedWorkers: j.assigned_worker_ids || [],
            geofenceEnabled: j.geofence_enabled || false,
            geofenceRadius: j.geofence_radius ? parseFloat(j.geofence_radius) : 100,
            createdAt: j.created_at
        }));

        res.json(transformed);
    } catch (error) {
        console.error('Get jobs error:', error);
        res.status(500).json({ error: 'Failed to fetch jobs' });
    }
});

/**
 * GET /api/jobs/:id
 * Get a single job by ID
 */
router.get('/:id', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT j.*,
                calculate_job_labor_cost(j.id) as labor_cost
            FROM jobs j
            WHERE j.id = $1
        `, [req.params.id]);

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Job not found' });
        }

        const j = result.rows[0];

        // Check access
        if (req.user.role === 'owner' && j.owner_id !== req.user.id) {
            return res.status(403).json({ error: 'Access denied' });
        }

        // Get assigned workers
        const workersResult = await pool.query(`
            SELECT worker_id FROM worker_job_assignments WHERE job_id = $1
        `, [j.id]);

        const assignedWorkers = workersResult.rows.map(w => w.worker_id);
        console.log(`[GET JOB] Job ${j.id} has ${assignedWorkers.length} assigned workers: ${JSON.stringify(assignedWorkers)}`);

        res.json({
            id: j.id,
            ownerID: j.owner_id,
            jobName: j.job_name,
            clientName: j.client_name,
            address: j.address,
            street: j.street,
            city: j.city,
            state: j.state,
            zip: j.zip,
            latitude: j.latitude,
            longitude: j.longitude,
            startDate: formatDate(j.start_date),
            endDate: formatDate(j.end_date),
            status: j.status,
            notes: j.notes,
            projectValue: parseFloat(j.project_value),
            amountPaid: parseFloat(j.amount_paid),
            laborCost: parseFloat(j.labor_cost || 0),
            profit: parseFloat(j.project_value) - parseFloat(j.labor_cost || 0),
            remainingBalance: parseFloat(j.project_value) - parseFloat(j.amount_paid),
            assignedWorkers: assignedWorkers,
            createdAt: j.created_at
        });
    } catch (error) {
        console.error('Get job error:', error);
        res.status(500).json({ error: 'Failed to fetch job' });
    }
});

/**
 * POST /api/jobs
 * Create a new job (owners only)
 */
router.post('/', requireOwner, [
    body('jobName').trim().notEmpty(),
    body('clientName').trim().notEmpty(),
    body('projectValue').isFloat({ min: 0.01 }),
    body('amountPaid').optional().isFloat({ min: 0 }),
    body('startDate').isISO8601()
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }

        const {
            jobName, clientName, address, street, city, state, zip, latitude, longitude,
            startDate, endDate, status, notes, projectValue, amountPaid,
            assignedWorkers, geofenceEnabled, geofenceLatitude, geofenceLongitude, geofenceRadius
        } = req.body;

        // Construct full address for backward compatibility if not provided
        const fullAddress = address || [street, city, state, zip].filter(Boolean).join(', ');

        // Validate amountPaid doesn't exceed projectValue
        if (amountPaid && amountPaid > projectValue) {
            return res.status(400).json({ error: 'Amount paid cannot exceed project value' });
        }

        const result = await pool.query(`
            INSERT INTO jobs (
                owner_id, job_name, client_name, address,
                street, city, state, zip,
                latitude, longitude, start_date, end_date,
                status, notes, project_value, amount_paid,
                geofence_enabled, geofence_radius
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)
            RETURNING *
        `, [
            req.user.id,
            jobName,
            clientName,
            fullAddress || '',
            street || null,
            city || null,
            state || null,
            zip || null,
            latitude || null,
            longitude || null,
            startDate,
            endDate || null,
            status || 'active',
            notes || '',
            projectValue,
            amountPaid || 0,
            geofenceEnabled || false,
            geofenceRadius || 100
        ]);

        const job = result.rows[0];

        // Assign workers if provided
        if (assignedWorkers && assignedWorkers.length > 0) {
            for (const workerId of assignedWorkers) {
                await pool.query(`
                    INSERT INTO worker_job_assignments (worker_id, job_id)
                    VALUES ($1, $2)
                    ON CONFLICT DO NOTHING
                `, [workerId, job.id]);
                
                // Create notification for assigned worker
                try {
                    await pool.query(`
                        INSERT INTO notifications (user_id, type, title, message, data)
                        VALUES ($1, $2, $3, $4, $5)
                    `, [
                        workerId,
                        'job_assignment',
                        'New Job Assignment',
                        `You have been assigned to: ${jobName}`,
                        JSON.stringify({ jobId: job.id, jobName, clientName })
                    ]);
                    console.log(`✅ Notification created for worker ${workerId} on job ${job.id}`);
                } catch (notifError) {
                    console.error('Failed to create notification:', notifError);
                    // Don't fail job creation if notification fails
                }
            }
        }

        res.status(201).json({
            id: job.id,
            ownerID: job.owner_id,
            jobName: job.job_name,
            clientName: job.client_name,
            address: job.address,
            latitude: job.latitude,
            longitude: job.longitude,
            startDate: formatDate(job.start_date),
            endDate: formatDate(job.end_date),
            status: job.status,
            notes: job.notes,
            projectValue: parseFloat(job.project_value),
            amountPaid: parseFloat(job.amount_paid),
            geofenceEnabled: job.geofence_enabled || false,
            geofenceRadius: job.geofence_radius ? parseFloat(job.geofence_radius) : 100,
            createdAt: job.created_at
        });
    } catch (error) {
        console.error('Create job error:', error);
        res.status(500).json({ error: 'Failed to create job' });
    }
});

/**
 * PUT /api/jobs/:id
 * Update a job (owners only)
 */
router.put('/:id', requireOwner, async (req, res) => {
    try {
        // Verify ownership
        const existing = await pool.query(
            'SELECT owner_id FROM jobs WHERE id = $1',
            [req.params.id]
        );

        if (existing.rows.length === 0) {
            return res.status(404).json({ error: 'Job not found' });
        }

        if (existing.rows[0].owner_id !== req.user.id) {
            return res.status(403).json({ error: 'Access denied' });
        }

        const {
            jobName, clientName, address, street, city, state, zip, latitude, longitude,
            startDate, endDate, status, notes, projectValue, amountPaid,
            assignedWorkers, geofenceEnabled, geofenceLatitude, geofenceLongitude, geofenceRadius
        } = req.body;

        const result = await pool.query(`
            UPDATE jobs SET
                job_name = COALESCE($1, job_name),
                client_name = COALESCE($2, client_name),
                address = COALESCE($3, address),
                street = COALESCE($4, street),
                city = COALESCE($5, city),
                state = COALESCE($6, state),
                zip = COALESCE($7, zip),
                latitude = $8,
                longitude = $9,
                start_date = COALESCE($10, start_date),
                end_date = $11,
                status = COALESCE($12, status),
                notes = COALESCE($13, notes),
                project_value = COALESCE($14, project_value),
                amount_paid = COALESCE($15, amount_paid),
                geofence_enabled = COALESCE($16, geofence_enabled),
                geofence_radius = COALESCE($17, geofence_radius)
            WHERE id = $18
            RETURNING *
        `, [
            jobName, clientName, address, street, city, state, zip, latitude, longitude,
            startDate, endDate, status, notes, projectValue, amountPaid,
            geofenceEnabled, geofenceRadius,
            req.params.id
        ]);

        const job = result.rows[0];

        // Update worker assignments if provided
        if (assignedWorkers !== undefined) {
            // Get current assignments to detect new ones
            const currentAssignments = await pool.query(
                'SELECT worker_id FROM worker_job_assignments WHERE job_id = $1',
                [job.id]
            );
            const currentWorkerIds = currentAssignments.rows.map(r => r.worker_id);
            
            // Remove existing assignments
            await pool.query('DELETE FROM worker_job_assignments WHERE job_id = $1', [job.id]);

            // Add new assignments and create notifications for newly assigned workers
            for (const workerId of assignedWorkers) {
                await pool.query(`
                    INSERT INTO worker_job_assignments (worker_id, job_id)
                    VALUES ($1, $2)
                `, [workerId, job.id]);
                
                // Only notify if this is a new assignment (not already assigned)
                if (!currentWorkerIds.includes(workerId)) {
                    try {
                        await pool.query(`
                            INSERT INTO notifications (user_id, type, title, message, data)
                            VALUES ($1, $2, $3, $4, $5)
                        `, [
                            workerId,
                            'job_assignment',
                            'New Job Assignment',
                            `You have been assigned to: ${jobName}`,
                            JSON.stringify({ jobId: job.id, jobName, clientName })
                        ]);
                        console.log(`✅ Notification created for newly assigned worker ${workerId} on job ${job.id}`);
                    } catch (notifError) {
                        console.error('Failed to create notification:', notifError);
                        // Don't fail job update if notification fails
                    }
                }
            }
        }

        res.json({
            id: job.id,
            ownerID: job.owner_id,
            jobName: job.job_name,
            clientName: job.client_name,
            address: job.address,
            latitude: job.latitude,
            longitude: job.longitude,
            startDate: formatDate(job.start_date),
            endDate: formatDate(job.end_date),
            status: job.status,
            notes: job.notes,
            projectValue: parseFloat(job.project_value),
            amountPaid: parseFloat(job.amount_paid),
            geofenceEnabled: job.geofence_enabled || false,
            geofenceRadius: job.geofence_radius ? parseFloat(job.geofence_radius) : 100,
            createdAt: job.created_at
        });
    } catch (error) {
        console.error('Update job error:', error);
        res.status(500).json({ error: 'Failed to update job' });
    }
});

/**
 * POST /api/jobs/:id/assign-worker
 * Assign a worker to a job (owners only)
 */
router.post('/:id/assign-worker', requireOwner, async (req, res) => {
    try {
        const { workerID } = req.body;
        const jobID = req.params.id;
        const ownerID = req.user.id;

        console.log(`[ASSIGN-WORKER] Attempting to assign worker: ${workerID} to job: ${jobID} for owner: ${ownerID}`);

        if (!workerID) {
            console.log('[ASSIGN-WORKER] Missing workerID in request body');
            return res.status(400).json({ error: 'workerID is required' });
        }

        // Verify job belongs to owner
        const jobCheck = await pool.query(
            'SELECT id FROM jobs WHERE id = $1 AND owner_id = $2',
            [jobID, ownerID]
        );

        if (jobCheck.rows.length === 0) {
            console.log(`[ASSIGN-WORKER] Job ${jobID} not found for owner ${ownerID}`);
            return res.status(404).json({ error: 'Job not found' });
        }

        // Verify worker belongs to owner
        const workerCheck = await pool.query(
            'SELECT id FROM users WHERE id = $1 AND owner_id = $2 AND role = $3',
            [workerID, ownerID, 'worker']
        );

        if (workerCheck.rows.length === 0) {
            console.log(`[ASSIGN-WORKER] Worker ${workerID} not found for owner ${ownerID}`);
            return res.status(404).json({ error: 'Worker not found' });
        }

        // Add assignment (ignore if already exists)
        const result = await pool.query(`
            INSERT INTO worker_job_assignments (worker_id, job_id)
            VALUES ($1, $2)
            ON CONFLICT (worker_id, job_id) DO NOTHING
            RETURNING worker_id
        `, [workerID, jobID]);

        console.log(`[ASSIGN-WORKER] Successfully assigned worker ${workerID} to job ${jobID}`);

        // Create notification and send email if this is a new assignment
        if (result.rows.length > 0) {
            try {
                // Get job details
                const jobDetails = await pool.query(
                    'SELECT name, address FROM jobs WHERE id = $1',
                    [jobID]
                );

                // Get worker details
                const workerDetails = await pool.query(
                    'SELECT name, email FROM users WHERE id = $1',
                    [workerID]
                );

                const job = jobDetails.rows[0];
                const worker = workerDetails.rows[0];

                // Create in-app notification
                await pool.query(`
                    INSERT INTO notifications (user_id, type, title, message, data)
                    VALUES ($1, $2, $3, $4, $5)
                `, [
                    workerID,
                    'job_assignment',
                    'New Job Assignment',
                    `You've been assigned to ${job.name}`,
                    JSON.stringify({ job_id: jobID, job_name: job.name })
                ]);

                // Send email notification
                const { sendJobAssignmentNotification } = require('../utils/emailService');
                await sendJobAssignmentNotification(
                    worker.email,
                    worker.name,
                    job.name,
                    job.address
                );

                console.log(`[ASSIGN-WORKER] Notification and email sent to worker ${workerID}`);
            } catch (notificationError) {
                // Log but don't fail the assignment if notification fails
                console.error('[ASSIGN-WORKER] Failed to send notification:', notificationError);
            }
        }

        res.json({ message: 'Worker assigned to job' });
    } catch (error) {
        console.error('Assign worker error:', error);
        res.status(500).json({ error: 'Failed to assign worker' });
    }
});

/**
 * DELETE /api/jobs/:id/unassign-worker/:workerId
 * Unassign a worker from a job (owners only)
 */
router.delete('/:id/unassign-worker/:workerId', requireOwner, async (req, res) => {
    try {
        // Verify job belongs to owner
        const jobCheck = await pool.query(
            'SELECT id FROM jobs WHERE id = $1 AND owner_id = $2',
            [req.params.id, req.user.id]
        );

        if (jobCheck.rows.length === 0) {
            return res.status(404).json({ error: 'Job not found' });
        }

        // Remove assignment
        await pool.query(
            'DELETE FROM worker_job_assignments WHERE worker_id = $1 AND job_id = $2',
            [req.params.workerId, req.params.id]
        );

        res.json({ message: 'Worker unassigned from job' });
    } catch (error) {
        console.error('Unassign worker error:', error);
        res.status(500).json({ error: 'Failed to unassign worker' });
    }
});

/**
 * DELETE /api/jobs/:id
 * Delete a job (owners only)
 */
router.delete('/:id', requireOwner, async (req, res) => {
    try {
        const result = await pool.query(
            'DELETE FROM jobs WHERE id = $1 AND owner_id = $2 RETURNING id',
            [req.params.id, req.user.id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Job not found' });
        }

        res.json({ message: 'Job deleted' });
    } catch (error) {
        console.error('Delete job error:', error);
        res.status(500).json({ error: 'Failed to delete job' });
    }
});

module.exports = router;
