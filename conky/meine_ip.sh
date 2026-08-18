#!/bin/bash

-set uo pipefail

LOG_DIR="$HOME/Scripts/logs"
LOG_FILE="$LOG_DIR/ip_history.txt"

mkdir -p "$LOG_DIR"

LAST_IP_FILE="/tmp/last_known_ip.txt"
LAST_CHANGE_FILE="/tmp/last_ip_change_time.txt"

# Pobieranie danych, z grepem filtrujacym wynik/blad
CURRENT_IP=$(dig +short +time=2 +tries=1 myip.opendns.com @resolver1.opendns.com 2>/dev/null | grep -E '^[0-9.]+$')

if [[ -z "$CURRENT_IP" ]]; then
    CURRENT_IP=$(dig +short +time=2 +tries=1 whoami.cloudflare @1.1.1.1 2>/dev/null | grep -E '^[0-9.]+$')
fi

if [[ -z "$CURRENT_IP" ]]; then
    CURRENT_IP='${color red}Network Error!${color}'
fi

NOW=$(date +%s)

# Logika sprawdzania poprzedniego IP
if [[ -f "$LAST_IP_FILE" ]]; then
    read -r LAST_IP < "$LAST_IP_FILE"
else
    LAST_IP=""
fi

# Logika sprawdzania czasu ostatniej zmiany
if [[ -f "$LAST_CHANGE_FILE" ]]; then
    read -r LAST_TIME < "$LAST_CHANGE_FILE"
    # Jeśli plik jest pusty z jakiegoś powodu, ustaw NOW
    [[ -z "$LAST_TIME" ]] && LAST_TIME=$NOW
else
    LAST_TIME=$NOW
    echo "$NOW" > "$LAST_CHANGE_FILE"
fi

# Wykrywanie zmiany IP
if [[ "$CURRENT_IP" != "$LAST_IP" && -n $LAST_IP ]]; then
    DIFF=$((NOW - LAST_TIME))
    HOURS=$((DIFF / 3600))
    
    # Zapis do logu
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Zmiana: $CURRENT_IP (Poprzedni trwał: ${HOURS}h)" >> "$LOG_FILE"
    
    # Aktualizacja plików tymczasowych
    echo "$CURRENT_IP" > "$LAST_IP_FILE"
    echo "$NOW" > "$LAST_CHANGE_FILE"
    LAST_TIME=$NOW
fi

# Jeśli to pierwsze uruchomienie w ogóle, zapisz obecne IP jako startowe
if [[ ! -f "$LAST_IP_FILE" ]]; then
    echo "$CURRENT_IP" > "$LAST_IP_FILE"
fi

# Obliczenia dla Conky
DIFF=$((NOW - LAST_TIME))
DAYS=$((DIFF / 86400))
HOURS=$(( (DIFF % 86400) / 3600 ))
MINS=$(( (DIFF % 3600) / 60 ))

# Wyświetlanie w Conky (wymaga execpi)
echo "$CURRENT_IP"
echo "\${color gray}Sesja: \${color}${DAYS}d ${HOURS}h ${MINS}m"
