#!/bin/bash

############################################
#
#	SSD - stan dysku dla Conky
#
############################################


DISK="/dev/sda"

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

# Logika ostrzeżeń
if [ "$HEALTH" != "PASSED" ]; then
  echo '${color red}SSD: FAIL'
elif [ "$USED" -ge 90 ]; then
  echo "SSD: ZUŻYCIE ${USED}%"
elif [ "$SPARE" -le 10 ]; then
  echo '${color light red}SSD: MAŁO ZAPASU${color}'
else
  echo '${color gray}SSD State:${color} OK, GITARRA!'
fi

