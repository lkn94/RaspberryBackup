#!/bin/bash
# Quelle des Skripts: https://raspberry.tips/raspberrypi-einsteiger/raspberry-pi-datensicherung-erstellen
# Modifiziert von Lukas Knoeller (hobbyblogging.de) & Marco Andreas (nags.de)
# QUELLEN: https://github.com/lkn94/RaspberryBackup
#          https://hilftdirweiter.de/backup-des-raspberry-pi-im-laufenden-betrieb/
#          https://hobbyblogging.de/raspberry-pi-vollautomatisch-sichern
#
# Vor der Nutzung bitte die Variablen unten entsprechend anpassen und die E-Mailadresse richtig setzen.
# Zum Senden von E-Mails auf dem Raspberry kann das Paket ssmtp genutzt werden.
# ACHTUNG: Das Mailprogramm muss installiert und Konfiguriert sein:
#    sudo apt-get install ssmtp mailutils
# danach die Datei anpassen: /etc/ssmtp/ssmtp.conf
# und bspw. den Mailserver (usw.) eintragen zB.: mailhub=DeinMailserver
# - Mailtest mit:
#   echo "Der Server $(hostname) hat am $(date +%A), den $(date +%d.%m.%Y) um $(date +%T) Uhr den Mailtest ausgefuehrt." | mail -s"$(hostname) - Mail-Test" testempfaenger@test.de
#
#Erstellte Image-Datei verkleinern, so dass diese später auch auf kleineren SD-Karten eingespielt werden kann:
# Siehe: https://techgeeks.de/raspberry-pi-image-installieren-backup-und-verkleinern/
# benötigtes Programm: (https://github.com/Drewsif/PiShrink) - Installation:
#  wget https://raw.githubusercontent.com/Drewsif/PiShrink/master/pishrink.sh
#  chmod +x pishrink.sh
#  sudo mv pishrink.sh /usr/local/bin

#ACHTUNG: Folgendes Paket muss installiert sein:
# sudo apt install cifs-utils
#ggf zusätzlich nötig: sudo apt install nfs-common
#Prüfe, ob Paket installiert mit: dpkg -l cifs-utils

# Ablauf, für die Installation dieses Scriptes (nachdem die oben genannten Programme installiert wurden!):
# - Datei anlegen, bspw.: /root/BackupPi.sh
# - Inhalt dieser Datei einfügen, Variablen anpassen und speichern
# - Das Script muss nun ausführbar gemacht und verschoben werden:
#     sudo chmod 755 /root/BackupPi.sh
#     sudo mv /root/BackupPi.sh /usr/local/bin/BackupPi.sh
#     sudo chmod +x /usr/local/bin/BackupPi.sh
# - Crontab-Editor öffnen mit:
#     sudo crontab -e
#   Unter der letzten Zeile einen neuen Job anlegen mit
#     00 01 * * * /usr/local/bin/BackupPi.sh > /dev/null
#   (Damit wird jeden Tag um 1 Uhr früh ein Backup gestartet.)
#   ODER - BESSER:
#     0 4  1 * * /usr/local/bin/BackupPi.sh > /dev/null
#     0 4 15 * * /usr/local/bin/BackupPi.sh > /dev/null
#   ALTERNATIV - Direkt in der Datei /ets/crontab das letzte Beispiel - mit Benutzer root - sollte so aussehen:
#     0 4  1 * * root	/usr/local/bin/BackupPi.sh > /dev/null
#     0 4 15 * * root	/usr/local/bin/BackupPi.sh > /dev/null
#   (Damit wird am 1. und am 15. um 4 Uhr das Script gestartet.
#   ... Falls die Mount-Funktion dieses Scripts NICHT genutzt werden soll, dann hier noch folgendes einfügen:
#   ....    @reboot mount -t cifs -o user=meinBenutzername,pass=MeinBenutzerPasswort //IP/backup_Pfad
#   (die Zeile natürlich anpassen...) und die Datei speichern...
# - Das wars...



# VARIABLEN - HIER EDITIEREN
BACKUP_PFAD="/mnt/nas"
BACKUP_ANZAHL="10"
BACKUP_ZIEL="//IP_NAS/PFAD/ZUM/BACKUP"
BACKUP_ZIEL_USER="USERNAME"
BACKUP_ZIEL_PASSWORT="USERPASSWORT"
BACKUP_NAME="Sicherung"
Mail_to="testempfaenger@test.de"
DIENSTE_START_STOP="service mysql"
# ENDE VARIABLEN
 

#Info-Mail bzgl. START versenden
echo "Der Server $(hostname) hat am $(date +%A), den $(date +%d.%m.%Y) um $(date +%T) Uhr das Backup-Skript gestartet..." | mail -s"$(hostname) - Backup Skript" $Mail_to


# Stoppe Dienste vor Backup - ggf. Zeile einkommentieren
#${DIENSTE_START_STOP} stop


#Prüfe auf vorhandenes lokales Backup-Verzeichnis und lege ggf. an
#legt Verzeichnis an, falls es noch nicht existiert und erzeugt keinen Fehler, wenn es schon existiert.
mkdir -p ${BACKUP_PFAD}


#Ziel auf eben angelegtes/geprüftes Verzeichnis einbinden
mount -t cifs -o user=${BACKUP_ZIEL_USER},password=${BACKUP_ZIEL_PASSWORT},rw,file_mode=0777,dir_mode=0777 ${BACKUP_ZIEL} ${BACKUP_PFAD}


#Prüfe auf vorhandenes Backup-Unterverzeichnis und lege ggf. an
#legt Verzeichnis an, falls es noch nicht existiert und erzeugt keinen Fehler, wenn es schon existiert.
mkdir -p ${BACKUP_PFAD}/$(hostname)


#Backup erstellen
Backup_Filename=${BACKUP_PFAD}/$(hostname)/${BACKUP_NAME}-$(date +%Y%m%d-%H%M%S).img
sudo dd if=/dev/mmcblk0 of=${Backup_Filename} bs=1MB
#ALTERNATIV zur vorigen Zeile - Backup gepackt:
#sudo dd if=/dev/mmcblk0 bs=1MB status=progress | gzip > ${Backup_Filename}.zip
#Zurückspielen kann man das mit:
#gunzip -c ${Backup_Filename}.zip | dd of=/dev/mmcblk0


# Starte zuvor beendete Dienste nach dem Backup - ggf. Zeile einkommentieren
#${DIENSTE_START_STOP} start


#Alte Sicherungen löschen
pushd ${BACKUP_PFAD}/$(hostname); ls -tr ${BACKUP_PFAD}/$(hostname)/${BACKUP_NAME}* | head -n -${BACKUP_ANZAHL} | xargs rm; popd


#Erstellte Image-Datei verkleinern, so dass diese später auch auf kleineren SD-Karten eingespielt werden kann:
# Siehe: https://techgeeks.de/raspberry-pi-image-installieren-backup-und-verkleinern/
# benötigtes Programm: (https://github.com/Drewsif/PiShrink)
# wget https://raw.githubusercontent.com/Drewsif/PiShrink/master/pishrink.sh
# Jetzt muss die Datei noch ausführbar gemacht werden und in das /usr/local/bin Verzeichnis kopiert werden.
# chmod +x pishrink.sh
# sudo mv pishrink.sh /usr/local/bin
# Mit folgendem Befehl verkleinert sich nun das erstellte Image:
sudo pishrink.sh ${Backup_Filename} ${Backup_Filename}_bereinigt.img


#NAS-Festplatte auswerfen
umount ${BACKUP_PFAD}


#Info-Mail bzgl. ENDE versenden
echo "Der Server $(hostname) hat am $(date +%A), den $(date +%d.%m.%Y) um $(date +%T) Uhr das Backup-Skript  ausgefuehrt und beendet." | mail -s"$(hostname) - Backup Skript" $Mail_to

