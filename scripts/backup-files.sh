#!/bin/bash

# Get the directory where the script is located and go to parent directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration
SOURCE_DIR="$PARENT_DIR/.volumes/fs"
ARCHIVE_DIR="$PARENT_DIR/.volumes/backups/fs"
LOG_FILE="$PARENT_DIR/.volumes/backups/backup.log"
TIMESTAMP="$(date +%Y-%m-%d)"
ARCHIVE="$ARCHIVE_DIR/fs-backup-${TIMESTAMP}.tar.gz"

# Ensure archive directory exists
mkdir -p "$ARCHIVE_DIR"

# Check that source directory exists and is non-empty
if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "$(date): [files] SKIPPED - source directory $SOURCE_DIR does not exist" >> "$LOG_FILE"
    exit 0
fi

# Archive the files volume
if tar -czf "$ARCHIVE" --ignore-failed-read -C "$PARENT_DIR/.volumes" fs; then
    SIZE="$(du -sh "$ARCHIVE" | cut -f1)"
    echo "$(date): [files] SUCCESS - $ARCHIVE ($SIZE)" >> "$LOG_FILE"
else
    echo "$(date): [files] FAILED - archive creation failed" >> "$LOG_FILE"
    exit 1
fi
