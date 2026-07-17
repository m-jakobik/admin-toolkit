#!/usr/bin/env bash

#########################
#
#
#  Debian based OS update&&upgrade 
#
#
########################

set -euo pipefail

# 1. go where the script is
cd "$(dirname "$0")"

# --- colours ---
C_GREEN='\033[0;32m'
C_CYAN='\033[0;36m'
C_YELLOW='\033[1;33m'
C_RED='\033[0;31m'
C_BOLD='\033[1m'
C_RESET='\033[0m'

TUDEJ=$(date "+%Y-%m-%d %H:%M")
LOG="/home/f3t1/Scripts/logs/aktualizacja.log"
mkdir -p "$(dirname "$LOG")"

# --- functions ---

check_internet() {
    curl -fsSL --connect-timeout 5 https://deb.debian.org > /dev/null 2>&1
}

send_notif() {
    notify-send "Aktualizacja Systemu" "$1" -i software-update-available
}

log_message() {
    local kolor="$1"
    local tresc="$2"
    if [ -z "$tresc" ]; then
        tresc="$kolor"
        kolor="$C_RESET"
    fi
    echo -e "${kolor}${tresc}${C_RESET}"
    echo -e "${tresc}" | sed 's/\x1b\[[0-9;]*m//g' >> "$LOG"
}

show_progress() {
    local pid=$1
    local delay=0.5
    if [ -z "$pid" ]; then return; fi

    echo -n -e "${C_YELLOW}Procesuje mordo, Poczeaj "
    while kill -0 "$pid" 2>/dev/null; do
        echo -n "#"
        sleep $delay
    done
    echo -e " [GOTOWE]${C_RESET}"
}

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=l

echo -e "${C_BOLD}Odpalam wrotki...${C_RESET}"
sudo -v || exit 1 

send_notif "Czeking De Aktualizejszynz..."

echo -e "${C_CYAN}###############################################################${C_RESET}"
log_message "${C_CYAN}${C_BOLD}" "       Aptitude Na Pelnej Kurtyzanie! (FINAL 2.0)"
log_message "${C_CYAN}" "               >> Dzis: $TUDEJ <<"
echo -e "${C_CYAN}###############################################################${C_RESET}"

# NET CHECK
if ! check_internet; then
    log_message "${C_RED}" "HALLO! Lipton! Brak neta. Sprawdź kabel albo Wi-Fi!"
    sleep 10
    exit 1
fi

# LIST AKTUALIZATOR
log_message "${C_BOLD}" "[1/3] Aktualizuję listę aplikacji..."
sudo apt-get update >> "$LOG" 2>&1 &
PID_ZADANIA=$!
show_progress "$PID_ZADANIA"

# NO I CO TAM W TRAWIE PUSZCZY?
log_message "${C_BOLD}" "[2/3] Co zaktualizujemy?"
send_notif "Gotowe - czek terminal typie!"
sudo apt-get upgrade -s -V 2>&1 | while IFS= read -r line; do
    echo "$(date '+%H:%M:%S') $line" | tee -a "$LOG"
done

echo ""
echo -e "${C_YELLOW}${C_BOLD}JeGit? (t/n): ${C_RESET}\c"
read -r -t 60 decyzja || decyzja="n"

if [[ "$decyzja" =~ ^[tTyY]$ ]]; then
    
    log_message "${C_GREEN}" "Installieren In Progress, ja..."
    
if sudo -E apt-get \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    upgrade -y 2>&1 | tee >(while IFS= read -r line; do
        echo "$(date '+%H:%M:%S') $line" >> "$LOG"
    done)    
then

    # POSPRZATAJ
    log_message "${C_BOLD}" "[3/3] Sprzatam Cache..."
    sudo apt-get autoclean >> "$LOG" 2>&1
    sudo apt-get clean >> "$LOG" 2>&1
    
    send_notif "System zaktualizowany! All Done!"
    log_message "${C_GREEN}${C_BOLD}" "\n########################## System ist aktualen! ;] ######################"
    log_message "${C_GREEN}${C_BOLD}" "########################## Finished at: $(date "+%H:%M") ##################"
    sleep 5

else
    send_notif "Upgrade FAILED! :("
    log_message "${C_RED}${C_BOLD}" "Upgrade sie wykrzaczyl!"
    sleep 5
    exit 1
    fi

else
    send_notif "Aktualizacja przerwana! :("
        log_message "${C_RED}${C_BOLD}" "Apgrejd Halted!"
        sleep 5
fi

log_message "${C_CYAN}" "#############################################################################################\n"
