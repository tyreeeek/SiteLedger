#!/bin/bash
# Setup Automated Database Backups with Cron
# Run this once on the production server to set up daily backups

echo "⚙️  Setting up automated database backups..."
echo ""

# Make backup script executable
chmod +x /root/siteledger/backend/scripts/backup-database.sh
chmod +x /root/siteledger/backend/scripts/restore-database.sh

echo "✅ Made backup scripts executable"
echo ""

# Create backup directory
mkdir -p /root/backups
echo "✅ Created backup directory: /root/backups"
echo ""

# Add cron job (daily at 2 AM)
CRON_JOB="0 2 * * * /root/siteledger/backend/scripts/backup-database.sh >> /root/backups/backup.log 2>&1"

# Check if cron job already exists
crontab -l 2>/dev/null | grep -q "backup-database.sh"
if [ $? -eq 0 ]; then
    echo "⚠️  Cron job already exists"
else
    # Add cron job
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "✅ Added cron job: Daily backup at 2:00 AM"
fi

echo ""
echo "📋 Current cron jobs:"
crontab -l

echo ""
echo "🧪 Testing backup script..."
/root/siteledger/backend/scripts/backup-database.sh

echo ""
echo "✅ Automated backups configured!"
echo ""
echo "Schedule: Daily at 2:00 AM"
echo "Location: /root/backups/"
echo "Retention: Last 7 backups"
echo "Logs: /root/backups/backup.log"
