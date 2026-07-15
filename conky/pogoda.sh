#!/bin/bash

# Pobieramy wszystkie dane w jednym wywołaniu
DATA=$(curl -s 'https://wttr.in/Sulejowek?format=%t|%C|%w|%h|%l')

# Rozdzielenie danych na zmienne
TEMP=$(echo $DATA | cut -d'|' -f1)           # aktualna temperatura
#TEMP_RANGE=$(echo $DATA | cut -d'|' -f2)     # max/min w nawiasach
WEATHER=$(echo $DATA | cut -d'|' -f2)
WIND=$(echo $DATA | cut -d'|' -f3)
HUM=$(echo $DATA | cut -d'|' -f4)
LOC=$(echo $DATA | cut -d'|' -f5)

# Połączenie aktualnej temp z zakresem max/min
#TEMP_DISPLAY="$TEMP ($TEMP_RANGE)"

# Zamiana opisów pogody na czytelny tekst (ASCII)
case $WEATHER in
  Sunny) WEATHER_TEXT="Słonecznie" ;;
  "Partly cloudy") WEATHER_TEXT="Częściowe zachmurzenie" ;;
  Cloudy) WEATHER_TEXT="Zachmurzenie" ;;
  Rain) WEATHER_TEXT="Deszcz" ;;
  Drizzle) WEATHER_TEXT="Mżawka" ;;
  Thunderstorm) WEATHER_TEXT="Burza" ;;
  Snow) WEATHER_TEXT="Śnieg" ;;
  Mist) WEATHER_TEXT="Mgła" ;;
  *) WEATHER_TEXT="$WEATHER" ;;
esac

# Wyświetlenie w osobnych liniach
echo "Temperatura: $TEMP"
echo "Pogoda: $WEATHER_TEXT"
echo "Wiatr: $WIND"
echo "Wilgotność: $HUM"
echo "Lokacja: $LOC"
