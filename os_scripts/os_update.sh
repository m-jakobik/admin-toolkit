#!/bin/bash

#########################
#
#
#  Debian based OS update&&upgrade 
#
#
########################

set -euo pipefail

cd "$(dirname "$0")"

# --- colours ---
C_GREEN='\033[0;32m'
C_CYAN='\033[0;36m'
C_YELLOW='\033[1;33m'
C_RED='\033[0;31m'
C_BOLD='\033[1m'
C_RESET='\033[0m'

TUDEJ=$(date "+%Y-%m-%d %H:%M")
PRIMARY_MIRROR="pl.archive.ubuntu.com/ubuntu"
FALLBACK_MIRROR="archive.ubuntu.com/ubuntu"
SOURCES_LIST="$HOME/Scripts/tmp/sources.list"
LOG="$HOME/Scripts/logs/aktualizacja.log"
mkdir -p "$(dirname "$LOG")" "$(dirname "$SOURCES_LIST")"

# --- functions ---

check_internet() {
    curl -fsSL --connect-timeout 5 https://deb.debian.org > /dev/null 2>&1
}

if curl -4 -fsI --max-time 10 "http://${PRIMARY_MIRROR}/dists/noble/InRelease" >/dev/null; then
    UBUNTU_MIRROR="$PRIMARY_MIRROR"
    echo "Primary mirror dostepny: $PRIMARY_MIRROR"
else
    echo "Primary mirror NIE DOSTEPNY! - sprawdzam fallback: $FALLBACK_MIRROR"

    if curl -4 -fsI --max-time 10 "http://${FALLBACK_MIRROR}/dists/noble/InRelease" >/dev/null; then
        UBUNTU_MIRROR="$FALLBACK_MIRROR"
        echo "Fallback mirror dostepny: $FALLBACK_MIRROR"
    else
        echo "BLAD! Dzejms Blad: Primary i fallback sa niedostepne!"
        exit 1
    fi
fi


echo "Jedziemy z: $UBUNTU_MIRROR"
sleep 3

mkdir -p "$(dirname "$SOURCES_LIST")"

cat > "$SOURCES_LIST" <<EOF
deb http://${UBUNTU_MIRROR} noble main restricted universe multiverse
deb http://${UBUNTU_MIRROR} noble-updates main restricted universe multiverse
deb http://${UBUNTU_MIRROR} noble-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu noble-security main restricted universe multiverse
EOF

send_notif() {
    notify-send "Aktualizacja Systemu" "$1" -i software-update-available
}

log_message() {
    local kolor="$1"
    local tresc="$2"
    if [[ -z "$tresc" ]]; then
        tresc="$kolor"
        kolor="$C_RESET"
    fi
    echo -e "${kolor}${tresc}${C_RESET}"
    echo -e "${tresc}" | sed 's/\x1b\[[0-9;]*m//g' >> "$LOG"
}

show_progress() {
    local pid=$1
    local delay=0.5
    if [[ -z "$pid" ]]; then return; fi

    echo -n -e "${C_YELLOW}Procesuje mordo, Poczeaj "
    while kill -0 "$pid" 2>/dev/null; do
        echo -n "#"
        sleep "$delay"
    done
    echo -e " [GOTOWE]${C_RESET}"
}

    offer_full_upgrade() {

    log_message "${C_BOLD}" "Sprawdzam możliwość Full Upgrade..."

    if ! sudo apt-get -s full-upgrade 2>&1 | grep -q "^Inst "; then
        log_message "${C_GREEN}" "Brak pakietów wymagających Full Upgrade."
        return 0
    fi

    log_message "${C_YELLOW}" "Pykniemy Full Upgrade?"
    log_message "${C_YELLOW}" "Wpadnie nowy kernel/dodatkowe pakiety ;)"

    local full_decyzja    

    echo ""
    echo -e "${C_YELLOW}${C_BOLD}Wychylic Lubelskigo Fulla? (t/T/y/Y):${C_RESET}\c"

    read -r -t 60 full_decyzja || full_decyzja="n"

    if [[ "$full_decyzja" =~ ^[tTyY]$ ]]; then

        log_message "${C_GREEN}" "Chlup! Lubelski Full..."

        if sudo -E apt-get \
	    -o Dir::Etc::sourcelist="$SOURCES_LIST" \
	    -o Dir::Etc::sourceparts="-" \
	    -o APT::Get::List-Cleanup="0" \
            -o Dpkg::Options::="--force-confdef" \
            -o Dpkg::Options::="--force-confold" \
            full-upgrade -y 2>&1 | tee >(while IFS= read -r line; do
                echo "$(date '+%H:%M:%S') $line" >> "$LOG"
            done)
        then
            log_message "${C_GREEN}" "Luubelski Full wychylon Dla Jego!"
        else
            log_message "${C_RED}" "No i Rozlales Fulla! :("
            return 1
        fi

    else
        log_message "${C_YELLOW}" "No i po ptokach! Pominięto Full Upgrade."
    fi
}

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=l

echo -e "${C_BOLD}Odpalam wrotki...${C_RESET}"
sudo -v || exit 1 

send_notif "Czeking De Aktualizejszynz..."

echo -e "${C_CYAN}###############################################################${C_RESET}"
log_message "${C_CYAN}${C_BOLD}" "       Aptitude Na Pelnej Kurtyzanie! v2.1"
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
sudo apt-get -o Dir::Etc::sourcelist="$SOURCES_LIST" \
             -o Dir::Etc::sourceparts="-" \
             -o APT::Get::List-Cleanup="0" \
             update >> "$LOG" 2>&1 &

PID_ZADANIA=$!

show_progress "$PID_ZADANIA"

if wait "$PID_ZADANIA"; then
    echo "APT update gr8 sakces m8!"
else
    echo "BLAD: apt-get update sie wywalil na ryja! :("
    exit 1
fi

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

    offer_full_upgrade

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
