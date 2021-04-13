#!/bin/bash
# Quelle des Skripts: https://raspberry.tips/raspberrypi-einsteiger/raspberry-pi-datensicherung-erstellen
# Modifiziert von Lukas Knoeller (hobbyblogging.de)
# Vor Nutzung bitte die Pfade entsprechend anpassen und die E-Mailadresse richtig setzen
# Zum Senden von E-Mails auf dem Raspberry kann das Paket ssmtp genutzt werden

#Festplatte einbinden
mount -t cifs -o user=USERNAME,password=PASSWORD,rw,file_mode=0777,dir_mode=0777 //IP/FREIGABE /mnt/nas

#Variablen
BACKUP_PFAD="/mnt/nas/Backup"
BACKUP_ANZAHL="5"
BACKUP_NAME="Sicherung"

#Backup erstellen
dd if=/dev/mmcblk0 of=${BACKUP_PFAD}/${BACKUP_NAME}-$(date +%Y%m%d).img bs=1MB

#Alte Sicherung löschen
pushd ${BACKUP_PFAD}; ls -tr ${BACKUP_PFAD}/${BACKUP_NAME}* | head -n -${BACKUP_ANZAHL} | xargs rm; popd

#Festplatte auswerfen
umount /mnt/nas

#Info versenden
to="mail@example.com"
servername="NAME or IP"
mail -s "Backup Skript" -t $to <<< "Der Server ($servername) hat eben das Backup-Skript ausgeführt."
