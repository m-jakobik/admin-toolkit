#!/bin/bash

# wrzuc do .config/

# Wymusza natychmiastowe czyszczenie bufora (zapobiega mignięciu pulpitu)
export XSECURELOCK_BLANK_TIMEOUT=0

# To jest KLUCZOWE w XFCE: xsecurelock stworzy dodatkowe, 
# czarne okno pod spodem, które ma zakryć pulpit, 
# nawet jeśli kompozytor XFCE zawiedzie.
export XSECURELOCK_NO_COMPOSITE_OBSCURER=0

# Opcjonalnie: wymusza, by xsecurelock nie czekał na mapowanie okna
export XSECURELOCK_WAIT_TIME_MS=0

# Konfiguracja wyglądu
export LANG=pl_PL.UTF-8
export XSECURELOCK_SAVER=saver_blank
export XSECURELOCK_IMAGE_DURATION=0
export XSECURELOCK_SHOW_DATETIME=1        # Pokazuje datę i godzinę
export XSECURELOCK_SHOW_HOSTNAME=0
export XSECURELOCK_PASSWORD_PROMPT=disco        
export XSECURELOCK_AUTH_TIMEOUT=30        # Jak długo ma być widoczne okno hasła
export XSECURELOCK_FONT="DejaVu Sans"      # Możesz tu wpisać swoją ulubioną czcionkę


# Odpalenie blokady
exec xsecurelock
