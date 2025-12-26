const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

async function createDemoAccount() {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    // 1. Create demo owner account
    const hashedPassword = await bcrypt.hash('demo123', 10);
    const userResult = await client.query(`
      INSERT INTO users (name, email, password_hash, role, active, created_at)
      VALUES ($1, $2, $3, $4, $5, NOW())
      ON CONFLICT (email) DO UPDATE SET active = true
      RETURNING id
    `, ['Demo Owner', 'demo@siteledger.com', hashedPassword, 'owner', true]);
    
    const ownerID = userResult.rows[0].id;
    console.log(`✅ Created demo owner: demo@siteledger.com / demo123`);
    console.log(`   Owner ID: ${ownerID}`);
    
    // 2. Create sample jobs
    const jobs = [
      {
        jobName: 'Kitchen Remodel - 456 Oak Ave',
        clientName: 'Sarah Johnson',
        projectValue: 45000,
        amountPaid: 20000,
        address: '456 Oak Avenue, San Francisco, CA',
        status: 'active'
      },
      {
        jobName: 'Bathroom Renovation - 789 Pine St',
        clientName: 'Michael Chen',
        projectValue: 28000,
        amountPaid: 15000,
        address: '789 Pine Street, Oakland, CA',
        status: 'active'
      },
      {
        jobName: 'Deck Construction - 321 Elm Dr',
        clientName: 'David Martinez',
        projectValue: 18000,
        amountPaid: 18000,
        address: '321 Elm Drive, Berkeley, CA',
        status: 'completed'
      }
    ];
    
    const jobIDs = [];
    for (const job of jobs) {
      const result = await client.query(`
        INSERT INTO jobs (owner_id, job_name, client_name, project_value, amount_paid, address, status, start_date, created_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, NOW() - INTERVAL '30 days', NOW())
        RETURNING id
      `, [ownerID, job.jobName, job.clientName, job.projectValue, job.amountPaid, job.address, job.status]);
      
      jobIDs.push(result.rows[0].id);
      console.log(`✅ Created job: ${job.jobName} ($${job.projectValue.toLocaleString()})`);
    }
    
    // 3. Create sample workers (they're users with role='worker')
    const workers = [
      { name: 'Carlos Rodriguez', hourlyRate: 35, email: 'carlos@demo.com' },
      { name: 'James Wilson', hourlyRate: 28, email: 'james@demo.com' },
      { name: 'Maria Garcia', hourlyRate: 32, email: 'maria@demo.com' }
    ];
    
    const workerIDs = [];
    for (const worker of workers) {
      const workerHash = await bcrypt.hash('worker123', 10);
      const result = await client.query(`
        INSERT INTO users (owner_id, name, email, password_hash, role, hourly_rate, active, created_at)
        VALUES ($1, $2, $3, $4, 'worker', $5, true, NOW())
        ON CONFLICT (email) DO NOTHING
        RETURNING id
      `, [ownerID, worker.name, worker.email, workerHash, worker.hourlyRate]);
      
      if (result.rows.length > 0) {
        workerIDs.push(result.rows[0].id);
        console.log(`✅ Created worker: ${worker.name} ($${worker.hourlyRate}/hr)`);
      }
    }
    
    // 4. Create sample receipts
    const receipts = [
      {
        jobID: jobIDs[0],
        vendor: 'Home Depot',
        amount: 1247.83,
        category: 'materials',
        date: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000), // 5 days ago
        notes: 'Lumber, drywall, screws'
      },
      {
        jobID: jobIDs[0],
        vendor: 'Lowes',
        amount: 892.50,
        category: 'materials',
        date: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000),
        notes: 'Paint, brushes, primer'
      },
      {
        jobID: jobIDs[1],
        vendor: 'Ferguson Plumbing',
        amount: 1540.00,
        category: 'materials',
        date: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000),
        notes: 'Fixtures, pipes, valves'
      },
      {
        jobID: jobIDs[1],
        vendor: 'Tile Shop',
        amount: 678.25,
        category: 'materials',
        date: new Date(Date.now() - 12 * 24 * 60 * 60 * 1000),
        notes: 'Bathroom tiles, grout'
      },
      {
        jobID: jobIDs[2],
        vendor: 'Lumber Yard',
        amount: 2340.00,
        category: 'materials',
        date: new Date(Date.now() - 40 * 24 * 60 * 60 * 1000),
        notes: 'Pressure-treated lumber for deck'
      }
    ];
    
    for (const receipt of receipts) {
      await client.query(`
        INSERT INTO receipts (owner_id, job_id, vendor, amount, category, receipt_date, notes, ai_confidence, created_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, 0.95, NOW())
      `, [ownerID, receipt.jobID, receipt.vendor, receipt.amount, receipt.category, receipt.date, receipt.notes]);
      
      console.log(`✅ Created receipt: ${receipt.vendor} - $${receipt.amount}`);
    }
    
    // 5. Create sample timesheets
    const timesheets = [
      { jobID: jobIDs[0], workerID: workerIDs[0], hours: 8, date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000) },
      { jobID: jobIDs[0], workerID: workerIDs[0], hours: 7.5, date: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000) },
      { jobID: jobIDs[0], workerID: workerIDs[1], hours: 6, date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000) },
      { jobID: jobIDs[1], workerID: workerIDs[1], hours: 8, date: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000) },
      { jobID: jobIDs[1], workerID: workerIDs[2], hours: 7, date: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000) },
      { jobID: jobIDs[1], workerID: workerIDs[2], hours: 8, date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000) },
      { jobID: jobIDs[2], workerID: workerIDs[0], hours: 40, date: new Date(Date.now() - 35 * 24 * 60 * 60 * 1000) },
      { jobID: jobIDs[2], workerID: workerIDs[1], hours: 30, date: new Date(Date.now() - 35 * 24 * 60 * 60 * 1000) }
    ];
    
    for (const ts of timesheets) {
      await client.query(`
        INSERT INTO timesheets (owner_id, worker_id, job_id, clock_in, clock_out, hours, status, created_at)
        VALUES ($1, $2, $3, $4, $5, $6, 'completed', NOW())
      `, [ownerID, ts.workerID, ts.jobID, ts.date, ts.date, ts.hours]);
      
      console.log(`✅ Created timesheet: ${ts.hours} hours on job`);
    }
    
    await client.query('COMMIT');
    
    console.log('\n🎉 DEMO ACCOUNT CREATED SUCCESSFULLY!\n');
    console.log('📧 Email: demo@siteledger.com');
    console.log('🔑 Password: demo123\n');
    console.log('🌐 Go to: https://siteledger.ai/auth/signin');
    console.log('   Sign in and see all the data!\n');
    console.log('📊 Dashboard will show:');
    console.log('   - 3 jobs ($91,000 total project value)');
    console.log('   - 5 receipts ($6,698.58 in expenses)');
    console.log('   - 8 timesheets (labor costs)');
    console.log('   - Real-time profit calculations\n');
    console.log('✨ AI OCR is ready - try uploading a receipt!\n');
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Error creating demo account:', error);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

createDemoAccount().catch(console.error);
