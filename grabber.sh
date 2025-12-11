#!/bin/bash

# ==============================================================================
	# Script : grabber.sh
	# Auteur : IDIR Ramzi
	# Date   : 2025-12-11
	# Version: 0.1
	#
	# Description :
	#   Grabber est un script bash qui récup toutes les infos
	#   hardware et software de l'ordinateur hôte
	#
	# Usage :
	#   ./grabber.sh
	#
	# Dépendances :
	#   - droits <<write>> dans le dossier /opt/grabber et /var/log/grabber
# ==============================================================================

# Def des variables principales
DATE=$(date +'%Y-%m-%d-%H%M%S')
DIR=/opt/grabber
DIR_USED=$DIR/$DATE
SUM="summary.txt"
DIR_SUM=$DIR_USED/$SUM
SUCCESS_LOG=$DIR_GRABBER/grabber-success.log
ERROR_LOG=$DIR_GRABBER/grabber-error.log

mkdir $DIR_USED
touch $DIR_SUM

# Texte de démarrage
hello () {
echo "++++++++++++++++++++" >> $DIR_SUM
echo "Démarrage de grabber" >> $DIR_SUM
echo "lancé le $DATE" >> $DIR_SUM
echo "++++++++++++++++++++" >> $DIR_SUM
echo "" >> $DIR_SUM
}

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
    echo "[HARDWARE]" > $DIR_SUM
    echo "CPU_MODEL = $CPU_MODEL" >> $DIR_SUM
    echo "CPU_ID = $CPU_ID" >> $DIR_SUM
    echo "RAM_SIZE = $RAM_SIZE" >> $DIR_SUM
    echo "RAM_GEN = $RAM_GEN" >> $DIR_SUM
    echo "STOCKAGE = $STOCKAGE_TOTAL" >> $DIR_SUM
}

software() {
    echo "[SOFTWARE]" > $DIR_SUM
    echo "OS = $OS" >> $DIR_SUM
    echo "ARCHITECTURE = $ARCH" >> $DIR_SUM
    echo "KERNEL = $KERNEL" >> $DIR_SUM
    echo "DESKTOP = $XDG_CURRENT_DESKTOP" >> $DIR_SUM
    echo "WINDOW MANAGER = $XDG_SESSION_TYPE" >> $DIR_SUM
}

hello
hardware
software
