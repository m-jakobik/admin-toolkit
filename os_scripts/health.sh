#!/bin/bash

set -euo pipefail

# Konfiguracja loga
LOG_FILE="/home/f3t1/Scripts/logs/health_cron_log.log"

send_notification() {
    # find user
    local CURRENT_USER=$(who | awk '{print $1}' | head -n1)
    local USER_ID=$(id -u "$CURRENT_USER")

    # no user --> halt
    [[ -z "$CURRENT_USER" ]] && return

    local TITLE="$1"
    local MSG="$2"

    # Wysyłanie powiadomienia z poprawną ścieżką do szyny danych (DBUS)
    runuser -l "$CURRENT_USER" -c "DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID/bus notify-send '$TITLE' '$MSG' --icon=dialog-information"
}

# Kolory w terminalu
	if [ -t 1 ]; then
	    RED='\033[0;31m'
	    GREEN='\033[0;32m'
	    YELLOW='\033[1;33m'
	    NC='\033[0m'
	else
	    # Jeśli skrypt idzie do logu (Cron) to:
	    RED=''
	    GREEN=''
	    YELLOW=''
	    NC=''
	fi

# Funkcja do wyświetlania i logowania jednocześnie
log() {
    local MESSAGE="$1"
    # Wyświetla na ekran (z kolorami jeśli w terminalu)
    echo -e "$MESSAGE"
    # Zapisuje do pliku (bez kolorów, z datą)
    echo -e "$MESSAGE" | sed 's/\x1b\[[0-9;]*m//g' | xargs -I {} echo "$(date '+%Y-%m-%d %H:%M:%S') : {}" >> "$LOG_FILE"
}

log "${YELLOW}========= STAN SYSTEMU - $(date) =========${NC}"

# Zajętość SSD
log "${GREEN}[1/5] Użycie SSD:${NC}"
DISK_INFO=$(df -h | grep '^/dev/' | awk '{ print $5 " użycia na partycji " $1 }')
log "$DISK_INFO"

DISK_PERCENT=$(df / | grep / | awk '{ print $5 }' | sed 's/%//g')
if [ "$DISK_PERCENT" -gt 90 ]; then
    log "${RED}!!! HALT: Mało miejsca na dysku ($DISK_PERCENT%) !!!${NC}"
fi

# S.M.A.R.T.
log "${GREEN}[2/5] Stan dysku (S.M.A.R.T.):${NC}"
    if command -v smartctl &> /dev/null; then
	DISK="/dev/sda"
	SMART_RES=$(smartctl -H $DISK | grep "result")
	log "${SMART_RES:-Nie udało się pobrać statusu}"
    else
	log "${YELLOW}Zainstaluj 'smartmontools', bo było i ni mo :( ${NC}"
    fi

# Temperatury
log "${GREEN}[3/5] Temperatury CPU:${NC}"
    if command -v sensors &> /dev/null; then
	TEMPS=$(sensors | grep -E '(Core|temp1)')
	log "$TEMPS"
    else
	log "${YELLOW}Zainstaluj 'lm-sensors', bo temperatur ni widu...${NC}"
    fi

# Błędy 
log "${GREEN}[4/5] Krytyczne błędy w logach (24h):${NC}"
ERRORS=$(journalctl --since "24 hours ago" -p 0..3 --no-pager | tail -n 5)
if [ -z "$ERRORS" ]; then
    log "Brak krytycznych błędów, bądź logi są czyste :)"
else
    log "${RED}$ERRORS${NC}"
fi

# RAM
log "${GREEN}[5/5] Pamięć RAM:${NC}"
RAM_VAL=$(free -h | awk '/^Mem:/ { print "W uzyciu: " $3 " / Razem: " $2 }')
log "$RAM_VAL"

log "${YELLOW}========= Finito Kobito! =========${NC}"

send_notification "System Health Check" "Diagnostyka zakończona. Sprawdź health.log"
