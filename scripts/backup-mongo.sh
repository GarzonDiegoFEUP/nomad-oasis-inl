#!/bin/bash

# Get the directory where the script is located and go to parent directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration
DUMP_DIR="$PARENT_DIR/.volumes/mongo"
ARCHIVE_DIR="$PARENT_DIR/.volumes/backups/mongo"
LOG_FILE="$PARENT_DIR/.volumes/backups/backup.log"
CONTAINER_NAME="nomad_oasis_mongo"
DATABASE_NAME="nomad_oasis_v1"
TIMESTAMP="$(date +%Y-%m-%d)"
ARCHIVE="$ARCHIVE_DIR/mongo-backup-${TIMESTAMP}.tar.gz"

# Ensure archive directory exists
mkdir -p "$ARCHIVE_DIR"

# Run mongodump inside the container (dumps to /backup = .volumes/mongo on host)
if docker exec "$CONTAINER_NAME" mongodump -d "$DATABASE_NAME" -o "/backup"; then
    # Archive the dump
    if tar -czf "$ARCHIVE" -C "$DUMP_DIR" .; then
        SIZE="$(du -sh "$ARCHIVE" | cut -f1)"
        echo "$(date): [mongo] SUCCESS - $ARCHIVE ($SIZE)" >> "$LOG_FILE"
    else
        echo "$(date): [mongo] FAILED - archive creation failed" >> "$LOG_FILE"
        exit 1
    fi
else
    echo "$(date): [mongo] FAILED - mongodump exited with error" >> "$LOG_FILE"
    exit 1
fi
