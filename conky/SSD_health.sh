#!/bin/bash

############################################
#
#	SSD - stan dysku dla Conky
#
############################################


DISK=$(lsblk -no PKNAME "$(findmnt -n -o SOURCE /)" | sed 's#^#/dev/#')

/usr/sbin/smartctl -H "$DISK" >/dev/null 2>&1 || {
  echo "SSD: brak dostępu"
  exit 0
}

SMART=$(/usr/sbin/smartctl -H -A "$DISK")
USED=$(echo "$SMART" | grep -i "Percentage Used" | awk '{print $3}')
SPARE=$(echo "$SMART" | grep -i "Available Spare" | awk '{print $3}')
HEALTH=$(echo "$SMART" | grep -i "SMART overall-health" | awk '{print $6}')

# Fallback jeśli brak danych
[ -z "$USED" ] && USED=0
[ -z "$SPARE" ] && SPARE=100
if [ -z "$DISK" ]; then
    echo '${color red}SSD: nie wykryto dysku!${color}'
    exit 0
fi

# Logika ostrzeżeń
if [ "$HEALTH" != "PASSED" ]; then
  echo '${color red}SSD: FAIL${color}'
elif [ "$USED" -ge 90 ]; then
  echo "SSD: ZUŻYCIE ${USED}%"
elif [ "$SPARE" -le 10 ]; then
  echo '${color red}SSD: MAŁO ZAPASU${color}'
else
  echo '${color gray}SSD State:${color} OK, GITARRA!'
fi

