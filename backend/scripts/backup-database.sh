#!/bin/bash

# ============================================================
# SiteLedger Database Backup Script
# Run this script daily via cron for automated backups
# ============================================================

set -e

# Configuration
BACKUP_DIR="/var/backups/siteledger"
DB_NAME="siteledger"
DB_USER="siteledger_user"
RETENTION_DAYS=30
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/siteledger_$DATE.sql.gz"

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Create backup
echo "Creating backup: $BACKUP_FILE"
pg_dump -U $DB_USER $DB_NAME | gzip > $BACKUP_FILE

# Check if backup was successful
if [ -f "$BACKUP_FILE" ]; then
    SIZE=$(ls -lh $BACKUP_FILE | awk '{print $5}')
    echo "✅ Backup successful: $BACKUP_FILE ($SIZE)"
else
    echo "❌ Backup failed!"
    exit 1
fi

# Remove old backups (older than retention period)
echo "Removing backups older than $RETENTION_DAYS days..."
find $BACKUP_DIR -name "siteledger_*.sql.gz" -mtime +$RETENTION_DAYS -delete

# List remaining backups
echo ""
echo "Current backups:"
ls -lh $BACKUP_DIR/*.sql.gz 2>/dev/null || echo "No backups found"

echo ""
echo "Backup complete!"
