#!/bin/bash
# Database Restore Script
# Restores a PostgreSQL database backup
# Usage: ./restore-database.sh <backup_file.sql.gz>

if [ $# -eq 0 ]; then
    echo "❌ Error: No backup file specified"
    echo ""
    echo "Usage: $0 <backup_file.sql.gz>"
    echo ""
    echo "Available backups:"
    ls -lh /root/backups/siteledger_backup_*.sql.gz 2>/dev/null || echo "No backups found"
    exit 1
fi

BACKUP_FILE=$1
DB_NAME="siteledger"
DB_USER="siteledger_user"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Error: Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "⚠️  WARNING: This will OVERWRITE the current database!"
echo "Database: $DB_NAME"
echo "Backup file: $BACKUP_FILE"
echo ""
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Restore cancelled."
    exit 0
fi

echo ""
echo "🗄️  Starting database restore..."

# Decompress if needed
if [[ "$BACKUP_FILE" == *.gz ]]; then
    echo "Decompressing backup..."
    gunzip -c "$BACKUP_FILE" | psql -U "$DB_USER" -h localhost "$DB_NAME"
else
    psql -U "$DB_USER" -h localhost "$DB_NAME" < "$BACKUP_FILE"
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Database restored successfully!"
else
    echo ""
    echo "❌ Restore failed!"
    exit 1
fi
