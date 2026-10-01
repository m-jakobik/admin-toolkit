#!/bin/bash

set -euo pipefail

############################################
#
#	MiCleaner 1.3
#
#	Wyczysc se OeSa!
#
############################################

# def kolor
RED_BOLD='\033[1;31m'
YELLOW_BOLD='\033[1;33m'
GREEN_BOLD='\033[1;32m'
BLUE_BOLD='\033[1;34m'
NC='\033[0m' #zresetuj kolor
    
# root wannabe
if [ "$EUID" -ne 0 ]; then 
  echo -e "${RED_BOLD}O sudo kolego zapomniałeś! ;]${NC}"
  exit
fi
# czek wolne miejsce
disk_before=$(df / --output=avail | tail -1)

echo -e "${YELLOW_BOLD}<--- ANDIAMO: Porządki w Zoo (Cache + Kernel + Vesktop Fix + Flatpak) --->${NC}"
sleep 2

# Czyszczenie pakietów
echo -e "${YELLOW_BOLD}[1/4] Sprzątanie cache Apt - pakietów...${NC}"
apt-get autoremove -y
apt-get autoclean -y
apt-get clean -y
sleep 2

# ==============================================================================
# Sekcja usuwania starych kerneli
# ==============================================================================
echo -e "${YELLOW_BOLD}[2/4] Usuwam stare kernele (zostawiam RUNNING - PREVIOUS)...${NC}"

# Pobieramy aktualnie działającą wersję (zabezpieczenie absolutne)
running_ver=$(uname -r | sed 's/-generic//g')

# lista zainstalowanych (status 'ii')
all_versions=$(dpkg-query -W -f='${Package} ${Status}\n' 'linux-image-[0-9]*' 2>/dev/null | \
    awk '$2 == "install" && $3 == "ok" && $4 == "installed" {print $1}' | \
    sed 's/linux-image-//g' | \
    sed 's/-generic//g' | \
    sort -V)

# Zostaw 2 najnowsze
versions_to_keep=$(echo "$all_versions" | sort -u | tail -n 2)
# Łączymy "running" oraz "2 najnowsze"
safe_versions=$(echo -e "$running_ver\n$versions_to_keep" | sort -u)

# osierocone moduły kernela
orphan_modules=""

kernel_module_pkgs=$(dpkg-query -W -f='${Package} ${Status}\n' \
    'linux-modules-[0-9]*' \
    'linux-modules-extra-[0-9]*' 2>/dev/null | \
    awk '$2 == "install" && $3 == "ok" && $4 == "installed" {print $1}')

for pkg in $kernel_module_pkgs; do
    case "$pkg" in
        linux-modules-extra-*)
            ver="${pkg#linux-modules-extra-}"
            ;;
        linux-modules-*)
            ver="${pkg#linux-modules-}"
            ;;
        *)
            continue
            ;;
    esac

    ver="${ver%-generic}"

    is_to_keep=0
    for vk in $safe_versions; do
        if [ "$vk" = "$ver" ]; then
            is_to_keep=1
            break
        fi
    done

    if [ $is_to_keep -eq 0 ]; then
        orphan_modules="$orphan_modules $pkg"
    fi
done

if [ -n "$orphan_modules" ]; then
    echo "Łooo widzę stare moduły kernela:"
    echo "$orphan_modules"
else
    echo "Ni mo osieroconych modułów kernela."
fi

to_remove=""
for v in $(echo "$all_versions" | sort -u); do
    # WARUNEK BEZPIECZEŃSTWA: 
    # Jeśli wersja NIE jest w "do zostawienia" ORAZ NIE jest wersją aktualnie uruchomioną
    is_to_keep=0
    for vk in $versions_to_keep; do
        if [ "$vk" = "$v" ]; then
            is_to_keep=1
            break
        fi
    done

    if [ $is_to_keep -eq 0 ] && [ "$v" != "$running_ver" ]; then
        # Szukamy paczek, które mają DOKŁADNIE ten numer wersji w NAZWIE
        pkgs=$(dpkg-query -W -f='${Package}\n' | grep -E "^linux-.*${v}(-|$)" || true)
        to_remove="$to_remove $pkgs"
    fi
done

# wrzuc osierocone moduły do listy pakietów do usunięcia
if [ -n "$orphan_modules" ]; then
    to_remove="$to_remove $orphan_modules"
fi

if [ -z "$to_remove" ]; then
    echo -e "${YELLOW_BOLD}Ola Boga! Brak seniorów w systemie. Nie tykam!${NC}"
else
    echo -e "${RED_BOLD}ZIDENTYFIKOWANO STARE PAKIETY DO USUNIĘCIA:${NC}"
    echo "--------------------------------------------------------"
    echo "$to_remove" | tr ' ' '\n' | sort  # Wyświetla listę w kolumnie, czytelniej
    echo "--------------------------------------------------------"

    # DRY-RUN
    echo -e "${YELLOW_BOLD}SYMULUJEMY PIERWIEJ:${NC}"
    apt-get purge -s $to_remove

    # INTERAKTYWNY BEZPIECZNIK
    echo -e "\n${RED_BOLD}UWAGA!${NC} Powyżej widnieje lista do usunięcia oraz symulacja zmian."
    read -p "Czy na pewno chcesz kontynuować i TRWALE usunąć te pakiety? (y/N): " resp

    if [[ "$resp" =~ ^[yY][eE]?[sS]?$ ]]; then
        echo -e "${YELLOW_BOLD}Rozpoczynam usuwanie...${NC}"
        
        # Główne usuwanie
        apt-get purge -y $to_remove
        apt-get autoremove -y
        sleep 2
    else
        echo -e "${BLUE_BOLD}Anulowano operację. Nic nie zostało usunięte z pakietów.${NC}"
    fi
fi
# Czyszczenie pozostałości (status rc)
        rc_pkgs=$(dpkg -l | awk '$1 == "rc" {print $2}')
        if [ -n "$rc_pkgs" ]; then
            echo -e "${YELLOW_BOLD}Sprzątam resztki konfiguracji (status rc)...${NC}"
            apt-get purge -y $rc_pkgs
           fi
        sleep 2

# ==============================================================================
# Sprzątanie starych nagłówków kernela
# ==============================================================================
echo -e "${YELLOW_BOLD}Sprawdzam istniejące nagłówki kernela...${NC}"

headers_to_remove=""

# zainstalowane pakiety (status 'ii')
installed_headers=$(dpkg-query -W -f='${Package} ${Status}\n' 'linux-headers-*' 2>/dev/null | \
    awk '$2 == "install" && $3 == "ok" && $4 == "installed" {print $1}')

for pkg in $installed_headers; do

    # !zostaw pakiet meta!
    if [ "$pkg" = "linux-headers-generic" ]; then
        continue
    fi

    # obczaj numer wersji z nazwy pakietu
    ver=$(echo "$pkg" | sed 's/^linux-headers-//' | sed 's/-generic$//')

    # sprawdz czy sa na liscie bezpiecznych (to_keep)
    is_to_keep=0
    for vk in $safe_versions; do
        if [ "$vk" = "$ver" ]; then
            is_to_keep=1
            break
        fi
    done

    if [ $is_to_keep -eq 0 ]; then
        headers_to_remove="$headers_to_remove $pkg"
    fi
done

if [ -n "$headers_to_remove" ]; then
    echo -e "${RED_BOLD}ZIDENTYFIKOWANO STARE PAKIETY NAGŁÓWKÓW:${NC}"
    echo "--------------------------------------------------------"
    echo "$headers_to_remove" | tr ' ' '\n'
    echo "--------------------------------------------------------"

    echo -e "${YELLOW_BOLD}SYMULUJEMY PIERWIEJ:${NC}"
    apt-get purge -s $headers_to_remove

    read -p "No i co, usuwamy? (y/N): " resp

    if [[ "$resp" =~ ^[yY][eE]?[sS]?$ ]]; then
        echo -e "${YELLOW_BOLD}Usuwam stare nagłówki przez APT...${NC}"
        apt-get purge -y $headers_to_remove
        apt-get autoremove -y
    else
        echo -e "${BLUE_BOLD}No i co ty robisz najlepszego?${NC}"
    fi
else
    echo "Brak starych nagłówków kernela. Skipujemy"
fi

# Aktualizacja GRUBa
update-grub
echo -e "${GREEN_BOLD}Osom! W kernelach czysto! Lecimy Dalej!${NC}"
sleep 2

# Cache użytkownika
echo -e "${YELLOW_BOLD}[3/4] Czyszczenie cache usera...${NC}"
for user_dir in /home/*; do
    if [ -d "$user_dir" ]; then
        # Tylko miniatury, bez dotykania sterowników graf
        [ -d "$user_dir/.cache/thumbnails" ] && rm -rf "$user_dir/.cache/thumbnails"/*
        echo "Wyczyszczono .cache dla: $(basename "$user_dir")"
    fi
done
sleep 2
# Vencord (Flatpak)
echo -e "${YELLOW_BOLD}[4/4] Czyszczenie śmieci Vencord (Flatpak)...${NC}"
for user_dir in /home/*; do
    V_BASE="$user_dir/.var/app/dev.vencord.Vesktop"
    
    if [ -d "$V_BASE" ]; then
        # Czyścimy cały folder cache (shadery, fonty temp itp.)
        [ -d "$V_BASE/cache" ] && rm -rf "$V_BASE/cache"/*        
        echo "Wyczyszczono dane tymczasowe Vesktop dla: $(basename "$user_dir")"
    fi
done
sleep 2
# Flatpak Crap:
	if command -v flatpak &> /dev/null; then
		echo "Removal zbędnych bibliotek Flatpak..."
		flatpak uninstall --unused -y
		sleep 2
	fi

# Avail space:
disk_after=$(df / --output=avail | tail -1)

# diff (w MB)
freed_space=$(( (disk_after - disk_before) / 1024 ))

echo "----------------------------------------------"
	if [ "$freed_space" -gt 0 ]; then
		echo "Odzyskano: ${freed_space} MB."
	else
		echo -e "${GREEN_BOLD}Kibelek czysty. Nie trza chlorować ;]${NC}"
	fi
echo -e "${GREEN_BOLD}<--- Koniec psot! --->${NC}"
echo -e "${GREEN_BOLD}<--- Va Bene! System lżejszy o parę kilo. --->${NC}"
sleep 5
