#!/bin/bash

DIR=/opt/grabber
SUM="$DIR/summary.txt"
SUCCESS_LOG=/var/log/grabber-success.log
ERROR_LOG=/var/log/grabber-error.log

tee $SUCCESS_LOG $ERROR_LOG <<EOF1
++++++++++++++++
Début de grabber
++++++++++++++++
================
Récupération des informations sur les paquets
================
EOF1


#Fichier /etc/apt/sources.list
tee -a $SUCCESS_LOG $ERROR_LOG <<EOF2
================
Copie du fichier de configuration /etc/apt/sources.list
================
EOF2

cat /etc/apt/sources.list 2> >(tee -a $ERROR_LOG) > $DIR/sources-list.file

tee -a $SUCCESS_LOG $ERROR_LOG <<EOF3
================
Récupération de la liste des paquets installés
================
EOF3

apt list --installed 2> >(tee -a $ERROR_LOG) > $DIR/apt-installed.cmd \
	&& echo "[OK]: Fichier apt-installed.cmd généré" > tee -a $SUCCES_LOG \
	|| echo "[ECHEC]: Erreur à la génération de apt-installed.cmd" > tee -a $ERROR_LOG


tee -a $SUCCESS_LOG $ERROR_LOG <<EOF4
================
Liste des périphériques USB
================
EOF4

lsusb 2> >(tee -a $ERROR_LOG) > $DIR/lsusb.cmd \
	&& echo "[OK]: Fichier lsusb.cmd généré" > tee -a $SUCCES_LOG \
	|| echo "[ECHEC]: Erreur à la génération de lsusb.cmd" > tee -a $ERROR_LOG

tee -a $SUCCESS_LOG $ERROR_LOG <<EOF5
================
Informations sur le processeur
================
EOF5

lscpu 2> >(tee -a $ERROR_LOG) > $DIR/lscpu.cmd \
	&& echo "[OK]: Fichier lscpu.cmd généré" > tee -a $SUCCES_LOG \
	|| echo "[ECHEC]: Erreur à la génération de lscpu.cmd" > tee -a $ERROR_LOG

tee -a $SUCCESS_LOG $ERROR_LOG <<EOF6
================
Liste des groupes
================
EOF6

cat /etc/group 2> >(tee -a $ERROR_LOG) > $DIR/group.file \
	&& echo "[OK]: Fichier group.file généré" > tee -a $SUCCES_LOG \
	|| echo "[ECHEC]: Erreur à la génération de group.file" > tee -a $ERROR_LOG

tee -a $SUCCESS_LOG $ERROR_LOG <<EOF7
================
Liste des utilisateurs
================
EOF7

cat /etc/passwd 2> >(tee -a $ERROR_LOG) > $DIR/passwd.file \
	&& echo "[OK]: Fichier passwd.file généré" > tee -a $SUCCES_LOG \
	|| echo "[ECHEC]: Erreur à la génération de passwd.file" > tee -a $ERROR_LOG

tee -a $SUCCESS_LOG $ERROR_LOG <<EOF8
================
Informations mémoire
================
EOF8

lsmem 2> >(tee -a $ERROR_LOG) > $DIR/lsmem.cmd \
	&& echo "[OK]: Fichier lsmem.cmd généré" > tee -a $SUCCES_LOG \
	|| echo "[ECHEC]: Erreur à la génération de lsmem.cmd" > tee -a $ERROR_LOG

tee -a $SUCCESS_LOG $ERROR_LOG <<EOF9
================
Liste du matériel
================
EOF9

lspci 2> >(tee -a $ERROR_LOG) > $DIR/lspci.cmd \
	&& echo "[OK]: Fichier lspci.cmd généré" > tee -a $SUCCES_LOG \
	|| echo "[ECHEC]: Erreur à la génération de lspci.cmd" > tee -a $ERROR_LOG

tee -a $SUCCESS_LOG $ERROR_LOG <<EOF10
================
Information démarrage services
================
EOF10

systemd-analyze 2> >(tee -a $ERROR_LOG) > $DIR/systemd-analyze.cmd \
	&& echo "[OK]: Fichier systemd-analyze.cmd généré" > tee -a $SUCCES_LOG \
	|| echo "[ECHEC]: Erreur à la génération de systemd-analyze.cmd" > tee -a $ERROR_LOG

tee -a $SUCCESS_LOG $ERROR_LOG <<EOF11
================
Performances démarrage services
================
EOF11

systemd-analyze blame 2> >(tee -a $ERROR_LOG) > $DIR/systemd-blame.cmd \
	&& echo "[OK]: Fichier systemd-analyze.cmd généré" > tee -a $SUCCES_LOG \
	|| echo "[ECHEC]: Erreur à la génération de systemd-analyze.cmd" > tee -a $ERROR_LOG

tee -a $SUCCESS_LOG $ERROR_LOG <<EOF12
================
Liste des réseaux
================
EOF12

cat /etc/network/interfaces 2> >(tee -a $ERROR_LOG) > $DIR/etc-network-interfaces.file \
	&& echo "[OK]: Fichier etc-network-interfaces.file généré" > tee -a $SUCCES_LOG \
	|| echo "[ECHEC]: Erreur à la génération de etc-network-interfaces.file" > tee -a $ERROR_LOG

tee -a $SUCCESS_LOG $ERROR_LOG <<EOF13
================
Disques et Partitions
================
EOF13

lsblk 2> >(tee -a $ERROR_LOG) > $DIR/lsblk.cmd \
	&& echo "[OK]: Fichier lsblk.cmd généré" > tee -a $SUCCES_LOG \
	|| echo "[ECHEC]: Erreur à la génération de lsblk.cmd" > tee -a $ERROR_LOG

tee -a $SUCCESS_LOG $ERROR_LOG <<EOF14
================
Configuration DNS
================
EOF14

cat /etc/resolv.conf 2> >(tee -a $ERROR_LOG) > $DIR/etc-resolv-conf.file \
	&& echo "[OK]: Fichier etc-resolv-conf.file généré" > tee -a $SUCCES_LOG \
	|| echo "[ECHEC]: Erreur à la génération de etc-resolv-conf.file" > tee -a $ERROR_LOG

declare -a DEVICES
mapfile -t DEVICES < <(lsblk -dn -o NAME |grep -v loop)

declare -A FILES

declare -A PARTITIONS_BY_DISK

FILES=(
    "sources_list.file" "/etc/apt/sources.list*"
    "passwd.file" "/etc/passwd"
    "group.file" "/etc/group"
    "/etc-network-interfaces.file" "/etc/network/interfaces"
    "/etc-resolv-conf.file" "/etc/resolv.conf"
)

for disk in ${DEVICES[@]}; do
    disk_path="/dev/$disk"
    disk_parts=$(lsblk -nr -o PKNAME,PATH $disk_path |grep -vE "^\ " |cut -d " " -f 2)
    PARTITIONS_BY_DISK[$disk]="${disk_parts[@]}"
done

#echo "Combien de disques sur l'ordinateur ? ${#DEVICES[@]}"

#echo "keys: ${!PARTITIONS_BY_DISK[@]}"
#echo "values: ${PARTITIONS_BY_DISK[@]}"

#echo "DEVICES=${DEVICES[@]}" > $DIR/status.log

for disk in ${!PARTITIONS_BY_DISK[@]}; do
    echo "PARTS_$disk=$(printf '%s ' ${PARTITIONS_BY_DISK[$disk]})"
done

#treat_file() {
#    cat $2 | grep '^#' | grep '^$' > $1
#}

#for file in ${!FILES[@]}; do
#    treat_file $file "${FILES[$file]}"
#done

# HARDWARE
CPU_MODEL=$(lscpu -eMODELNAME | tail -n1)
CPU_ID=$(sudo dmidecode -t processor | grep ID | cut -d: -f42 | sed 's/^ *//')
RAM_SIZE=$(lsmem | grep 'Mémoire partagée' | cut -d: -f2 | sed 's/\ //g')
RAM_GEN=$(sudo dmidecode -t memory | grep Type: | grep -v Unknown | tail -n1 | cut -d: -f2 | sed 's/\ //')
SIZES=$(lsblk -dnb | grep -v loop | grep -v boot | tr -s " " | cut -d \  -f4)
STOCKAGE_TOTAL=0

for SIZE in ${sizes[@]}; do
    STOCKAGE_TOTAL+=$SIZE
done

STOCKAGE_TOTAL=$(numfmt --to iec $STOCKAGE_TOTAL)

# SOFTWARE
OS=$(lsb_release -a | grep Description | cut -f2)
ARCH=$(uname -a | cut -d' ' -f10)
KERNEL=$(uname -r)

hardware() {
    echo "[HARDWARE]" > $SUM
    echo "CPU_MODEL = $CPU_MODEL" >> $SUM
    echo "CPU_ID = $CPU_ID" >> $SUM
    echo "RAM_SIZE = $RAM_SIZE" >> $SUM
    echo "RAM_GEN = $RAM_GEN" >> $SUM
    echo "STOCKAGE = $STOCKAGE_TOTAL" >> $SUM
}

software() {
    echo "[SOFTWARE]" > $SUM
    echo "OS = $OS" >> $SUM
    echo "ARCHITECTURE = $ARCH" >> $SUM
    echo "KERNEL = $KERNEL" >> $SUM
    echo "DESKTOP = $XDG_CURRENT_DESKTOP" >> $SUM
    echo "WINDOW MANAGER = $XDG_SESSION_TYPE" >> $SUM
}

hardware
software
