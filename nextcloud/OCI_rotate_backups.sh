#!/bin/bash

#OCI CLI: Upewnij się, że na serwerze masz zainstalowany oci-cli i jest on autoryzowany #(oci setup config).

VOLUME_ID="ocid1.volume.oc1.eu-frankfurt-1.ab..." # OCID wolumenu
COMPARTMENT_ID="ocid1.compartment.oc1..aaaa..." # moj NC

echo "--- Start rotacji backupów ---"

echo "Tworzę nowy OS_FULL backup..."
NEW_BACKUP=$(oci bv volume-backup create --volume-id $VOLUME_ID --type FULL --display-name "NCDATA_Full_$(date +%Y%m%d)")
NEW_BACKUP_ID=$(echo $NEW_BACKUP | jq -r '.data.id')

# AVAILABLE?
echo "Czekam na dostępność backupu (ID: $NEW_BACKUP_ID)..."
while true; do
    STATE=$(oci bv volume-backup get --volume-backup-id $NEW_BACKUP_ID | jq -r '.data."lifecycle-state"')
    if [ "$STATE" == "AVAILABLE" ]; then
        echo "Backup gotowy!"
        break
    fi
    sleep 30
done

# 3. Usuwamy stare backupy (tutaj musisz być ostrożny!)
# Filtr usuwania: W punkcie 3. nie usuwaj "wszystkiego". Najbezpieczniej jest pobrać listę #backupów (oci bv volume-backup list), posortować je po dacie (time-created) i usunąć tylko #te, które są starsze niż Twój nowy, przedostatni Full.
echo "Czyszczenie starych backupów..."
# oci bv volume-backup delete --volume-backup-id <STARY_ID>

echo "--- Rotacja zakończona sukcesem ---"
