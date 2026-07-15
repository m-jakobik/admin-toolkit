#!/bin/bash

# ==========================================
# Synchronizacja KeePassXC z Google Drive oraz Nextcloud
# z automatycznym backupem wielu plików
# ==========================================


# wrzuc do /etc/cron.weekly/
# Ścieżki do plików do backupu

set -euo pipefail

HOME="/home/f3t1"

FILES=(
  "$HOME/Documents/Backups/PassDatabase.kdbx"
  "$HOME/Documents/Backups/PassDatabase.old.kdbx"
)

# local copy
LOCAL_BASE_DIR="$HOME/Downloads/GDrive/Backupy/KeePass"
LOCAL_CURRENT_DIR="$LOCAL_BASE_DIR/current"
LOCAL_BACKUP_DIR="$LOCAL_BASE_DIR/backup" 
HASH_DIR="$HOME/.cache/keepassxc/keepass_hashes"

# Remote i foldery
#DEST="GDrive:/Backupy/KeePass/current"
#BACKUP="GDrive:/Backupy/KeePass/backup"

# Format: "NAZWA_DO_LOGOW|DEST_FOLDER|BACKUP_FOLDER"
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

    # 1. Kontrole wstępne
    if [ ! -f "$SOURCE" ]; then
        echo "$(date '+%F %T') - Plik $SOURCE nie istnieje, pomijam" >> "$LOG"
        continue
    fi

    # 2. Sprawdzenie czy plik się zmienił
    CURRENT_HASH=$(sha256sum "$SOURCE" | cut -d' ' -f1)
    PREVIOUS_HASH=""
    [ -f "$HASH_FILE" ] && PREVIOUS_HASH=$(cat "$HASH_FILE")

    if [ "$CURRENT_HASH" != "$PREVIOUS_HASH" ]; then
        echo "$(date '+%F %T') - Wykryto zmianę w $FILENAME." >> "$LOG"

        # --- LOKALNA KOPERACJA ---
        # robimy kopie
        if [ -f "$LOCAL_CURRENT_FILE" ]; then
            cp -p "$LOCAL_CURRENT_FILE" "$LOCAL_BACKUP_DIR/$FILENAME.$RUN_TIMESTAMP"
        fi
        
        # Kopiuj do lokalnego 'current'
        cp -p "$SOURCE" "$LOCAL_CURRENT_FILE"
        
        # Weryfikacja lokalnej kopii
        if [ "CURRENT_HASH=$(sha256sum "$SOURCE" | awk '{print $1}')" ]; then
            echo "$CURRENT_HASH" > "$HASH_FILE"
        else
            echo "$(date '+%F %T') - BŁĄD: Suma kontrolna lokalnej kopii nie pasuje!" >> "$LOG"
            continue
        fi

    # Kopiowanie - synchro z backupem (tylko jeśli plik się zmienił)
        SYNC_SUCCESS=true
        for CHMURA in "${CHMURY[@]}"; do
            IFS="|" read -r NAZWA DEST BACKUP_DEST <<< "$CHMURA"
            
            if /usr/bin/rclone copy "$SOURCE" "$DEST" \
                --backup-dir "$BACKUP_DEST" \
                --suffix ".$RUN_TIMESTAMP" \
                --config "$HOME/.config/rclone/rclone.conf" \
                --log-file="$LOG" --log-level INFO; then
                echo "$(date '+%F %T') - Sukces: $FILENAME przesłany do $NAZWA." >> "$LOG"
            else
                echo "$(date '+%F %T') - BŁĄD: Synchronizacja z $NAZWA nieudana!" >> "$LOG"
                SYNC_SUCCESS=false
            fi
        done

    USER_ID=$(id -u f3t1)
    
    if [ "$SYNC_SUCCESS" = true ]; then
        # Wyślij powiadomienie do użytkownika f3t1
        # Musimy określić DBUS_SESSION_BUS_ADDRESS, aby notify-send wiedział, gdzie "pukać"
        sudo -u f3t1 \
        DISPLAY=:0 \
        DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID/bus \
        notify-send \
        "KeePass Sync" \
        "Backup pliku $FILENAME zakończony sukcesem!" \
        --icon=keepassxc
    else
        sudo -u f3t1 \
        DISPLAY=:0 \
        DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID/bus \
        notify-send \
        "KeePass Sync" \
        "BŁĄD podczas backupu pliku $FILENAME!" \
        --urgency=critical \
        --icon=error
    fi
else
    echo "$(date '+%F %T') - Brak zmian w $FILENAME" >> "$LOG"
fi
done
    
