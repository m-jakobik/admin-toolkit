#!/bin/bash

URL="https://dvt.strangled.net/status.php"

# -L podąża za przekierowaniami (301/302)
# -I pobiera tylko nagłówki (szybciej)
STATUS=$(/usr/bin/curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$URL")

if [ "$STATUS" = "200" ]; then
    echo 'ONLINE'
else
    echo 'OFFLINE'
fi
