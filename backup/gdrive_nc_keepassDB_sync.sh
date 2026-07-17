#!/usr/bin/env bash

# ==========================================
# Synchro KeePassXC with Google Drive + Nextcloud
# with auto versioning and hash checking
# ==========================================


# put into /etc/cron.weekly/
# paths to passDB

set -euo pipefail

FILES=(
  "$HOME/Documents/Backups/PassDatabase.kdbx"
  "$HOME/Documents/Backups/PassDatabase.old.kdbx"
)

# local copy
LOCAL_BASE_DIR="$HOME/Downloads/GDrive/Backupy/KeePass"
LOCAL_CURRENT_DIR="$LOCAL_BASE_DIR/current"
LOCAL_BACKUP_DIR="$LOCAL_BASE_DIR/backup" 
HASH_DIR="$HOME/.cache/keepassxc/keepass_hashes"

# Format: "NAME4LOGS|DEST_FOLDER|BACKUP_FOLDER"
CHMURY=(
    "GDrive|GDrive:/Backupy/KeePass/current|GDrive:/Backupy/KeePass/backup"
    "NextCloud|nc:/Backupy/KeePass/current|nc:/Backupy/KeePass/backup"
)
LOG="$HOME/Scripts/logs/keepass-sync.log"

mkdir -p \
    "$LOCAL_CURRENT_DIR" \
    "$LOCAL_BACKUP_DIR" \
    "$HASH_DIR" \
    "$(dirname "$LOG")"

# MAIN
for SOURCE in "${FILES[@]}"; do
    FILENAME=$(basename "$SOURCE")
    HASH_FILE="$HASH_DIR/$FILENAME.sha256"
    LOCAL_CURRENT_FILE="$LOCAL_CURRENT_DIR/$FILENAME"
    RUN_TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

    # 1. Initial checks
    if [ ! -f "$SOURCE" ]; then
        echo "$(date '+%F %T') - File $SOURCE does not exist, skipping" >> "$LOG"
        continue
    fi

    # 2. Did the file change?
    CURRENT_HASH=$(sha256sum "$SOURCE" | cut -d' ' -f1)
    PREVIOUS_HASH=""
    [ -f "$HASH_FILE" ] && PREVIOUS_HASH=$(cat "$HASH_FILE")

    if [ "$CURRENT_HASH" != "$PREVIOUS_HASH" ]; then
        echo "$(date '+%F %T') - Change detected in $FILENAME." >> "$LOG"

        # --- local work ---
        # Local copy
        if [ -f "$LOCAL_CURRENT_FILE" ]; then
            cp -p "$LOCAL_CURRENT_FILE" "$LOCAL_BACKUP_DIR/$FILENAME.$RUN_TIMESTAMP"
        fi
        
        # Copy to a local 'current'
        cp -p "$SOURCE" "$LOCAL_CURRENT_FILE"
        
        # Verify local copy
        LOCAL_HASH=$(sha256sum "$LOCAL_CURRENT_FILE" | awk '{print $1}')

        if [ "$CURRENT_HASH" = "$LOCAL_HASH" ]; then
             echo "$CURRENT_HASH" > "$HASH_FILE"
        else
            echo "$(date '+%F %T') - ERROR: Checksum mismatch for local copy!" >> "$LOG"
         continue
        fi

    # Copy - synchro with backup (only in case of a change)
        SYNC_SUCCESS=true
        for CHMURA in "${CHMURY[@]}"; do
            IFS="|" read -r NAZWA DEST BACKUP_DEST <<< "$CHMURA"
            
            if /usr/bin/rclone copy "$SOURCE" "$DEST" \
                --backup-dir "$BACKUP_DEST" \
                --suffix ".$RUN_TIMESTAMP" \
                --config "$HOME/.config/rclone/rclone.conf" \
                --log-file="$LOG" --log-level INFO; then
                echo "$(date '+%F %T') - Success: $FILENAME sent to $NAZWA." >> "$LOG"
            else
                echo "$(date '+%F %T') - ERROR: Synchro with $NAZWA has failed!" >> "$LOG"
                SYNC_SUCCESS=false
            fi
        done

    USER_ID=$(id -u)
    
    if [ "$SYNC_SUCCESS" = true ]; then
        # Send notify to current user
        # specify DBUS_SESSION_BUS_ADDRESS, so that notify-send knows where to knock
        sudo -u "$USER" \
        DISPLAY=:0 \
        DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID/bus \
        notify-send \
        "KeePass Sync" \
        "Creating a backup of $FILENAME succeeded!" \
        --icon=keepassxc
    else
        sudo -u "$USER" \
        DISPLAY=:0 \
        DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID/bus \
        notify-send \
        "KeePass Sync" \
        "ERROR during creation of backup of $FILENAME!" \
        --urgency=critical \
        --icon=error
    fi
else
    echo "$(date '+%F %T') - No changes in $FILENAME" >> "$LOG"
fi
done
    
