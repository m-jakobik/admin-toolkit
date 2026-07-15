#!/bin/bash

# Współrzędne
LAT="52.25"
LON="21.29"

# temperature_2m, relative_humidity_2m, rain, snowfall, wind_speed_10m, wind_direction_10m
URL="https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&current=temperature_2m,apparent_temperature,surface_pressure,relative_humidity_2m,rain,snowfall,weather_code,wind_speed_10m,wind_direction_10m&models=icon_seamless&timezone=auto&forecast_days=1"

curl -s -m 10 "$URL" -o /tmp/weather_raw.json

# Wyciąganie danych z JSON
TEMP=$(jq '.current.temperature_2m' /tmp/weather_raw.json)
FEEL=$(jq -r '.current.apparent_temperature' /tmp/weather_raw.json)
HUMID=$(jq '.current.relative_humidity_2m' /tmp/weather_raw.json)
RAIN=$(jq '.current.rain' /tmp/weather_raw.json)
SNOW=$(jq '.current.snowfall' /tmp/weather_raw.json)
WIND_S=$(jq '.current.wind_speed_10m' /tmp/weather_raw.json)
WIND_D=$(jq '.current.wind_direction_10m' /tmp/weather_raw.json)
WCODE=$(jq '.current.weather_code' /tmp/weather_raw.json)

# Wyciąganie Wschodu i Zachodu (i formatowanie do samej godziny)
SUNR_RAW=$(jq -r '.daily.sunrise[0]' /tmp/weather_raw.json)
SUNS_RAW=$(jq -r '.daily.sunset[0]' /tmp/weather_raw.json)
SUNR=$(echo $SUNR_RAW | cut -d'T' -f2)
SUNS=$(echo $SUNS_RAW | cut -d'T' -f2)

#obsluga opadow
SUMA=$(echo "scale=1; ($RAIN + $SNOW)/1" | bc -l | sed 's/^\./0./')

# Logika kolorów dla temperatury
if [ "$(echo "$TEMP > 27" | bc -l)" -eq 1 ]; then
    T_COL='${color orange}'      # Powyżej 25: Gorąco (Pomarańczowy)
elif [ "$(echo "$TEMP > 20" | bc -l)" -eq 1 ]; then
    T_COL='${color yellow}'      # Powyżej 20: Słonecznie (Żółty)
elif [ "$(echo "$TEMP < -10" | bc -l)" -eq 1 ]; then
    T_COL='${color blue}'        # Poniżej -10: Bardzo zimno (Niebieski)
elif [ "$(echo "$TEMP < 0" | bc -l)" -eq 1 ]; then
    T_COL='${color lightblue}'   # Poniżej 0: Mróz (Jasnoniebieski)
else
    T_COL='${color white}'       # Od 0 do 19: Standard (Biały)
fi

# Zamiana stopni wiatru na kierunki świata
if [ "$WIND_D" -le 22 ] || [ "$WIND_D" -gt 337 ]; then 
    DIR="N ↓"   # Wieje Z północy NA południe
elif [ "$WIND_D" -le 67 ];  then 
    DIR="NE ↙"
elif [ "$WIND_D" -le 112 ]; then 
    DIR="E ←"   # Wieje ZE wschodu NA zachód
elif [ "$WIND_D" -le 157 ]; then 
    DIR="SE ↖"
elif [ "$WIND_D" -le 202 ]; then 
    DIR="S ↑"   # Wieje Z południa NA północ
elif [ "$WIND_D" -le 247 ]; then 
    DIR="SW ↗"
elif [ "$WIND_D" -le 292 ]; then 
    DIR="W →"   # Wieje Z zachodu NA wschód
else 
    DIR="NW ↘"
fi

# Opis pogodowy
case $WCODE in
0)          DESC="Czyste niebo" ;;
    1)          DESC="Głównie pogodnie" ;;
    2)          DESC="Częściowe zachmurzenie" ;;
    3)          DESC="Całkowite zachmurzenie" ;;
    45|48)      DESC="Mgła" ;;
    51)          DESC="Lekka mżawka" ;;
    53)          DESC="Umiarkowana mżawka" ;;
    55)          DESC="Gęsta mżawka" ;;
    61)          DESC="Lekki deszcz" ;;
    63)          DESC="Umiarkowany deszcz" ;;
    65)          DESC="Silna ulewa" ;;
    66|67)      DESC="Mroźny deszcz" ;;
    71)          DESC="Lekki śnieg" ;;
    73)          DESC="Umiarkowany śnieg" ;;
    75)          DESC="Silna śnieżyca" ;;
    77)          DESC="Śnieg ziarnisty" ;;
    80)          DESC="Słaby deszcz przelotny" ;;
    81)          DESC="Umiarkowany deszcz przelotny" ;;
    82)          DESC="Gwałtowna ulewa przelotna" ;;
    85|86)      DESC="Przelotny śnieg" ;;
    95)          DESC="Burza" ;;
    96|99)      DESC="Burza z gradem" ;;
    *)          DESC="WTF ($WCODE)" ;;
esac

# Łączenie wszystkiego w czytelny format dla Conky
# Możesz to dowolnie układać
{
    echo "$DESC"
    echo '${color gray}Temp: '"\${font :bold}${T_COL}${TEMP}°C\${font}"
    echo '${color gray}Temp Odczuwalna: '"\${font :bold}${T_COL}${FEEL}°C\${font}"
    echo '${color gray}Wilgotność:${color}' "${HUMID}%"
    echo '${color gray}Wiatr:${color}' "${WIND_S} km/h ($DIR)"
    echo '${color gray}Opady:${color}' "R:${RAIN}mm S:${SNOW}cm"
} > /tmp/weather_conky
