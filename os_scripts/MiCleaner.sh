#!/bin/bash

set -euo pipefail

############################################
#
#	MiCleaner 1.2
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

echo -e "${YELLOW_BOLD}<--- ANDIAMO: Porządki w Mint 22.3 (Cache + Kernel + Vesktop Fix + Flatpak) --->${NC}"
sleep 2

# Aptitude - Czyszczenie pakietów
echo -e "${YELLOW_BOLD}[1/4] Sprzątanie cache Apt - pakietów...${NC}"
apt-get autoclean -y
apt-get autoremove -y
apt-get clean -y
sleep 2

# ==============================================================================
# Sekcja usuwania starych kerneli i sprzątania syfu z /boot
# ==============================================================================
echo -e "${YELLOW_BOLD}[2/4] Usuwam stare kernele (zostawiam RUNNING - PREVIOUS)...${NC}"

# Pobieramy aktualnie działającą wersję (zabezpieczenie absolutne)
running_ver=$(uname -r | sed 's/-generic//g')

# Pobieramy listę wersji zainstalowanych (tylko status 'ii')
all_versions=$(dpkg-query -W -f='${Package} ${Status}\n' 'linux-image-[0-9]*' | grep 'install ok installed' | awk '{print $1}' | sed 's/linux-image-//g' | sed 's/-generic//g' | sort -V)

# Zostaw 2 najnowsze
versions_to_keep=$(echo "$all_versions" | sort -u | tail -n 2)
# Łączymy "running" oraz "2 najnowsze"
safe_versions=$(echo -e "$running_ver\n$versions_to_keep" | sort -u)

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
        # grep -F sprawia, że kropki są traktowane dosłownie (fixed string)
        pkgs=$(dpkg-query -W -f='${Package}\n' | grep -F "$v")
        to_remove="$to_remove $pkgs"
    fi
done

if [ -z "$to_remove" ]; then
    echo -e "${YELLOW_BOLD}Ola Boga! Tylko 1 lub 2 kernele w systemie. Nie usuwam nic!${NC}"
else
    echo -e "${RED_BOLD}ZIDENTYFIKOWANO STARE PAKIETY DO USUNIĘCIA:${NC}"
    echo "--------------------------------------------------------"
    echo "$to_remove" | tr ' ' '\n' | sort  # Wyświetla listę w kolumnie, czytelniej
    echo "--------------------------------------------------------"

    # DRY-RUN
    echo -e "${YELLOW_BOLD}SYMULACJA (Dry-run) za pomocą apt:${NC}"
    apt-get purge -s $to_remove

    # INTERAKTYWNY BEZPIECZNIK
    echo -e "\n${RED_BOLD}UWAGA!${NC} Powyżej widnieje lista do usunięcia oraz symulacja zmian."
    read -p "Czy na pewno chcesz kontynuować i TRWALE usunąć te pakiety? (y/N): " resp

    if [[ "$resp" =~ ^[yY][eE]?[sS]?$ ]]; then
        echo -e "${YELLOW_BOLD}Rozpoczynam usuwanie...${NC}"
        
        # Główne usuwanie
        sudo apt-get purge -y $to_remove
        sudo apt-get autoremove -y
        
        # Czyszczenie pozostałości (status rc)
        rc_pkgs=$(dpkg -l | grep '^rc' | awk '{print $2}')
        if [ -n "$rc_pkgs" ]; then
            echo -e "${YELLOW_BOLD}Sprzątam resztki konfiguracji (status rc)...${NC}"
            sudo apt-get purge -y $rc_pkgs
           fi
        sleep 2
    else
        echo -e "${BLUE_BOLD}Anulowano operację. Nic nie zostało usunięte z pakietów.${NC}"
    fi
fi

# Dodatkowy krok: czyszczenie pozostałości w /boot po usuniętych kernelach
echo -e "\n${YELLOW_BOLD}Czyszczenie pozostałości w /boot...${NC}"

# lista wersji, co zostawily pliki w /boot
all_boot_versions=$(ls /boot/vmlinuz-* /boot/initrd.img-* /boot/config-* /boot/System.map-* 2>/dev/null | \
    sed -r 's|.*/(vmlinuz\|initrd.img\|config\|System.map)-||' | \
    sed 's/-generic//g' | sort -u)

for v in $all_boot_versions; do
    # Pomijamy, jeśli to pusta zmienna (wynik braku plików)
    [ -z "$v" ] && continue

    is_to_keep=0
    for vk in $versions_to_keep; do
        if [ "$vk" = "$v" ]; then
            is_to_keep=1
            break
        fi
    done

    if [ $is_to_keep -eq 0 ] && [ "$v" != "$running_ver" ]; then
        if [ -n "$v" ]; then
            echo "Usuwam osierocone pliki dla wersji: $v"
            sudo rm -f /boot/*-"$v"-generic
        fi
    fi
done

# ==============================================================================
# Sprzątanie nagłówków w /usr/src/
# ==============================================================================
echo -e "${YELLOW_BOLD}Sprawdzam nagłówki w /usr/src/...${NC}"
cd /usr/src
headers_to_remove=""

for dir in linux-headers-*; do
    # Sprawdzamy czy to faktycznie katalog
    [ -d "$dir" ] || continue
    
    ver=$(echo "$dir" | sed 's/linux-headers-//g' | sed 's/-generic//g')
    
    # Warunek: nie zostawiamy wersji aktualnej i tych z listy "do zachowania"
    if [[ ! "$safe_versions" =~ "$ver" ]]; then
        headers_to_remove="$headers_to_remove $dir"
    fi

done

if [ -n "$headers_to_remove" ]; then
    echo -e "${RED_BOLD}ZIDENTYFIKOWANO NAGŁÓWKI DO USUNIĘCIA:${NC}"
    echo "$headers_to_remove" | tr ' ' '\n'
    
    read -p "Czy chcesz usunąć powyższe nagłówki z /usr/src/? (y/N): " resp
    if [[ "$resp" =~ ^[yY][eE]?[sS]?$ ]]; then
        for dir in $headers_to_remove; do
            # Dodatkowe zabezpieczenie przed pustą zmienną
            [ -n "$dir" ] && sudo rm -rf "$dir"
            echo "Usunięto: $dir"
        done
    else
        echo -e "${BLUE_BOLD}Anulowano usuwanie nagłówków.${NC}"
    fi
else
    echo "Brak zbędnych nagłówków w /usr/src/."
fi

# Aktualizacja GRUBa
sudo update-grub
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
