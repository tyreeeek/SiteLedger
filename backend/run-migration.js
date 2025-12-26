/**
 * Database Migration Script
 * Sync backend database with iOS app structure
 */

const pool = require('./src/database/db');

async function runMigration() {
    const client = await pool.connect();
    
    try {
        await client.query('BEGIN');
        console.log('🔄 Starting database migration...\n');

        // 1. Create workers table
        console.log('Creating workers table...');
        await client.query(`
            CREATE TABLE IF NOT EXISTS workers (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                name VARCHAR(255) NOT NULL,
                email VARCHAR(255),
                phone VARCHAR(50),
                hourly_rate DECIMAL(10,2) NOT NULL,
                role VARCHAR(100),
                active BOOLEAN DEFAULT true,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                created_by VARCHAR(255)
            )
        `);
        await client.query(`CREATE INDEX IF NOT EXISTS idx_workers_active ON workers(active)`);
        await client.query(`CREATE INDEX IF NOT EXISTS idx_workers_created_by ON workers(created_by)`);
        console.log('✅ Workers table created\n');

        // 2. Create client_payments table
        console.log('Creating client_payments table...');
        await client.query(`
            CREATE TABLE IF NOT EXISTS client_payments (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
                amount DECIMAL(10,2) NOT NULL,
                method VARCHAR(50) CHECK (method IN ('cash', 'check', 'bank_transfer', 'credit_card', 'other')),
                date DATE NOT NULL,
                reference VARCHAR(255),
                notes TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                created_by VARCHAR(255)
            )
        `);
        await client.query(`CREATE INDEX IF NOT EXISTS idx_client_payments_job ON client_payments(job_id)`);
        await client.query(`CREATE INDEX IF NOT EXISTS idx_client_payments_date ON client_payments(date)`);
        console.log('✅ Client payments table created\n');

        // 3. Create ai_insights table
        console.log('Creating ai_insights table...');
        await client.query(`
            CREATE TABLE IF NOT EXISTS ai_insights (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
                job_name VARCHAR(255),
                type VARCHAR(50) CHECK (type IN ('cost_analysis', 'timeline_prediction', 'risk_assessment', 'optimization')),
                title VARCHAR(255) NOT NULL,
                summary TEXT NOT NULL,
                details TEXT,
                confidence INTEGER CHECK (confidence >= 0 AND confidence <= 100),
                recommendations TEXT[],
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        `);
        await client.query(`CREATE INDEX IF NOT EXISTS idx_ai_insights_job ON ai_insights(job_id)`);
        await client.query(`CREATE INDEX IF NOT EXISTS idx_ai_insights_type ON ai_insights(type)`);
        console.log('✅ AI insights table created\n');

        // 4. Update jobs table
        console.log('Updating jobs table...');
        await client.query(`ALTER TABLE jobs ADD COLUMN IF NOT EXISTS location VARCHAR(500)`);
        await client.query(`ALTER TABLE jobs ADD COLUMN IF NOT EXISTS client_payments_total DECIMAL(10,2) DEFAULT 0`);
        await client.query(`ALTER TABLE jobs ADD COLUMN IF NOT EXISTS remaining_balance DECIMAL(10,2) DEFAULT 0`);
        await client.query(`ALTER TABLE jobs ADD COLUMN IF NOT EXISTS total_cost DECIMAL(10,2) DEFAULT 0`);
        await client.query(`ALTER TABLE jobs ADD COLUMN IF NOT EXISTS profit DECIMAL(10,2) DEFAULT 0`);
        await client.query(`ALTER TABLE jobs ADD COLUMN IF NOT EXISTS assigned_workers TEXT[]`);
        
        // Check current enum values and update if needed
        const enumCheck = await client.query(`
            SELECT unnest(enum_range(NULL::job_status))::text as value
        `);
        const existingValues = enumCheck.rows.map(r => r.value);
        console.log('  - Current status values:', existingValues);
        
        const requiredValues = ['planned', 'active', 'completed'];
        for (const value of requiredValues) {
            if (!existingValues.includes(value)) {
                console.log(`  - Adding status value: ${value}`);
                await client.query(`ALTER TYPE job_status ADD VALUE '${value}'`);
            }
        }
        console.log('✅ Jobs table updated\n');

        // 5. Update receipts table
        console.log('Updating receipts table...');
        await client.query(`ALTER TABLE receipts ADD COLUMN IF NOT EXISTS ai_parsed_fields JSONB`);
        
        // Check current category values
        const categoryCheck = await client.query(`
            SELECT DISTINCT category FROM receipts WHERE category IS NOT NULL
        `);
        const existingCategories = categoryCheck.rows.map(r => r.category);
        console.log('  - Current category values:', existingCategories);
        
        // Normalize all categories to lowercase first
        console.log('  - Normalizing categories to lowercase...');
        await client.query(`UPDATE receipts SET category = LOWER(category) WHERE category IS NOT NULL`);
        
        // Map old categories to new ones
        const categoryMap = {
            'other': 'misc',
            'labor': 'misc',
            'permits': 'misc',
            'tools': 'equipment'
        };
        
        for (const [oldCat, newCat] of Object.entries(categoryMap)) {
            const checkExists = await client.query(`SELECT COUNT(*) FROM receipts WHERE category = $1`, [oldCat]);
            if (parseInt(checkExists.rows[0].count) > 0) {
                console.log(`  - Migrating category '${oldCat}' to '${newCat}'`);
                await client.query(`UPDATE receipts SET category = $1 WHERE category = $2`, [newCat, oldCat]);
            }
        }
        
        // Update category constraint
        await client.query(`ALTER TABLE receipts DROP CONSTRAINT IF EXISTS receipts_category_check`);
        await client.query(`ALTER TABLE receipts ADD CONSTRAINT receipts_category_check CHECK (category IN ('materials', 'fuel', 'equipment', 'subcontractors', 'misc'))`);
        console.log('✅ Receipts table updated\n');

        // 6. Update timesheets table
        console.log('Updating timesheets table...');
        
        // Check if column exists before renaming
        const checkUserIdCol = await client.query(`
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name='timesheets' AND column_name='user_id'
        `);
        
        if (checkUserIdCol.rows.length > 0) {
            await client.query(`ALTER TABLE timesheets RENAME COLUMN user_id TO worker_id`);
            console.log('  - Renamed user_id to worker_id');
        }
        
        await client.query(`ALTER TABLE timesheets ADD COLUMN IF NOT EXISTS worker_name VARCHAR(255)`);
        await client.query(`ALTER TABLE timesheets ADD COLUMN IF NOT EXISTS job_name VARCHAR(255)`);
        await client.query(`ALTER TABLE timesheets ADD COLUMN IF NOT EXISTS duration_hours DECIMAL(5,2)`);
        await client.query(`ALTER TABLE timesheets ADD COLUMN IF NOT EXISTS labor_cost DECIMAL(10,2)`);
        console.log('✅ Timesheets table updated\n');

        // 7. Update alerts table
        console.log('Updating alerts table...');
        
        // Check and update severity enum
        const severityCheck = await client.query(`
            SELECT unnest(enum_range(NULL::alert_severity))::text as value
        `);
        const existingSeverities = severityCheck.rows.map(r => r.value);
        console.log('  - Current severity values:', existingSeverities);
        
        const requiredSeverities = ['low', 'medium', 'high'];
        for (const value of requiredSeverities) {
            if (!existingSeverities.includes(value)) {
                console.log(`  - Adding severity value: ${value}`);
                await client.query(`ALTER TYPE alert_severity ADD VALUE '${value}'`);
            }
        }
        
        // Check and update type enum
        const typeCheck = await client.query(`
            SELECT unnest(enum_range(NULL::alert_type))::text as value
        `);
        const existingTypes = typeCheck.rows.map(r => r.value);
        console.log('  - Current type values:', existingTypes);
        
        const requiredTypes = ['budget', 'payment', 'timesheet', 'anomaly', 'info'];
        for (const value of requiredTypes) {
            if (!existingTypes.includes(value)) {
                console.log(`  - Adding type value: ${value}`);
                await client.query(`ALTER TYPE alert_type ADD VALUE '${value}'`);
            }
        }
        
        console.log('✅ Alerts table updated\n');

        // 8. Create function to auto-calculate job financials
        console.log('Creating job financials trigger...');
        await client.query(`
            CREATE OR REPLACE FUNCTION update_job_financials()
            RETURNS TRIGGER AS $$
            DECLARE
                v_job_id UUID;
            BEGIN
                -- Determine job_id from trigger context
                IF TG_OP = 'DELETE' THEN
                    v_job_id := OLD.job_id;
                ELSE
                    v_job_id := NEW.job_id;
                END IF;
                
                -- Calculate client payments total
                UPDATE jobs SET client_payments_total = COALESCE((
                    SELECT SUM(amount) FROM client_payments WHERE job_id = v_job_id
                ), 0) WHERE id = v_job_id;
                
                -- Calculate remaining balance
                UPDATE jobs SET remaining_balance = project_value - client_payments_total
                WHERE id = v_job_id;
                
                RETURN COALESCE(NEW, OLD);
            END;
            $$ LANGUAGE plpgsql
        `);
        
        // Create trigger
        await client.query(`DROP TRIGGER IF EXISTS update_job_on_payment ON client_payments`);
        await client.query(`
            CREATE TRIGGER update_job_on_payment
            AFTER INSERT OR UPDATE OR DELETE ON client_payments
            FOR EACH ROW EXECUTE FUNCTION update_job_financials()
        `);
        console.log('✅ Job financials trigger created\n');

        await client.query('COMMIT');
        console.log('✅ Database migration completed successfully!\n');
        
        // Show table counts
        const tables = ['workers', 'client_payments', 'ai_insights', 'jobs', 'receipts', 'timesheets', 'alerts'];
        console.log('📊 Current table counts:');
        for (const table of tables) {
            const result = await client.query(`SELECT COUNT(*) FROM ${table}`);
            console.log(`  ${table}: ${result.rows[0].count} records`);
        }
        
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('❌ Migration failed:', error.message);
        throw error;
    } finally {
        client.release();
        pool.end();
    }
}

runMigration()
    .then(() => {
        console.log('\n✅ Migration script finished');
        process.exit(0);
    })
    .catch(error => {
        console.error('\n❌ Migration script failed:', error);
        process.exit(1);
    });
