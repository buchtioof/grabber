#!/bin/bash
export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin
export LC_ALL=C
export LANG=C

# ==============================================================================
	# Script : grabber.sh
	# Date   : 2025-12-11
	# Version: 0.2
	#
	# Description :
	#   Grabber is a bash program that fetch some informations 
	#   of the computer like memory, storage or cpu for exemple.
	#
	# Usage :
	#   ./grabber.sh
	#
	# Dependancies :
	#   - dmidecode
	#   - inxi
# ==============================================================================

echo ""
echo "==============================="
echo "Welcome to grabber!"

#----- CHECK IF SUDO -----
if [[ $EUID -ne 0 ]]; then
    echo "Please run as root to be able to use superuser commands as dmidecode -> sudo ./grabber.sh"
    echo "==============================="
    exit 1
fi

###### CHECK DEPENDENCIES INSTALLED ############
echo -n "Checking dependencies... "
REQUIRED_CMDS=(inxi dmidecode lscpu lsblk numfmt)
MISSING=()

for cmd in "${REQUIRED_CMDS[@]}"; do
    command -v "$cmd" >/dev/null 2>&1 || MISSING+=("$cmd")
done
if (( ${#MISSING[@]} > 0 )); then
    echo "Missing dependencies:"
    printf ' - %s\n' "${MISSING[@]}"
    echo "Install with: sudo apt install ${MISSING[*]}"
    exit 1
else
    echo "All set!"
fi

echo "It's grabbin time!"
echo "==============================="
echo ""

#----- MAIN VARIABLES -----
DATE=$(date +'%Y-%m-%d_%H%M%S')

# D\C3\A9terminer l'utilisateur r\C3\A9el (celui qui a lanc\C3\A9 sudo)
REAL_USER="${SUDO_USER:-$USER}"

# R\C3\A9cup\C3\A9rer son HOME depuis /etc/passwd (fiable)
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"

# Declare where to store grabber results
NAME_DIR="logs_$DATE"
WORKING_DIR="$REAL_HOME/grabber/$NAME_DIR"
mkdir $WORKING_DIR -p

# Declare the files to be written
SUM_FILE=$WORKING_DIR/summary.txt
SUCCESS_LOG=$WORKING_DIR/grabber-success.log
ERROR_LOG=$WORKING_DIR/grabber-error.log

#----- PROGRAM -----

# Init actual log

touch $SUM_FILE $SUCCESS_LOG $ERROR_LOG

# Starting text for logs
echo -e "Logs of $DATE :\n" > $SUCCESS_LOG
echo -e "Logs of $DATE :\n" > $ERROR_LOG

#--------- Tables associates source file to a file inside grabber folder ---------

#-------- ARRAYS -----------------------------
# FILES arrays
declare -A FILES

FILES=(
    ["sources_list.file"]="/etc/apt/sources.list*"
    ["passwd.file"]="/etc/passwd"
    ["group.file"]="/etc/group"
    ["etc-network-interfaces.file"]="/etc/network/interfaces"
    ["etc-resolv-conf.file"]="/etc/resolv.conf"
)

# CMD arrays
declare -A CMD

CMD=(
	["systemd-analyze.cmd"]="systemd-analyze"
	["systemd-blame.cmd"]="systemd-analyze blame"
	["lspci.cmd"]="lspci"
	["lsmem.cmd"]="lsmem --output-all"
	["lscpu.cmd"]="lscpu"
	["lsusb.cmd"]="lsusb"
	["apt-installed.cmd"]="apt list --installed"
)
#----------------------------------------------

# Call arrays and store in files with same command name then write if success or not in proper log file
treat_file() {
	cat $2 | grep -v '^#' | grep -v '^$' > $1 
	if [ $? -eq 0 ]; then
		echo "[OK]: Fichier $1 g\C3\A9n\C3\A9r\C3\A9" >> $SUCCESS_LOG
	else
		echo "[ECHEC]: Erreur \C3\A0 la g\C3\A9n\C3\A9ration de $1 => Code de sortie $?" >> $ERROR_LOG
	fi
}

for file in "${!FILES[@]}"; do
	treat_file $file "${FILES[$file]}"
done

treat_cmd() {
    eval "$2" > $DIR/$1 2> >(tee -a $ERROR_LOG)
    if [ $? -eq 0 ]; then
    	echo "[OK]: Fichier $1 g\C3\A9n\C3\A9r\C3\A9 avec la commande $2" >> $SUCCESS_LOG
    else
    	echo "[ECHEC]: Erreur \C3\A0 la g\C3\A9n\C3\A9ration de $1 => Code de sortie $?" >> $ERROR_LOG
    fi
}

for cmd in "${!CMD[@]}"; do
	treat_cmd "$cmd" "${CMD[$cmd]}"
done
###############################################

############ WRITING THE SUMMARY #################
# Starting text for summary
hello () {
    echo "+++++++++++++++++++++++++" >> $SUM_FILE
    echo "Grabber startin'" >> $SUM_FILE
    echo "launched the $DATE" >> $SUM_FILE
    echo "+++++++++++++++++++++++++" >> $SUM_FILE
    echo "" >> $SUM_FILE
}

############ HARDWARE FETCHER #################
#------------ CPU ----------------
CPU_MODEL=$(lscpu -eMODELNAME | tail -n1 | cut -d' ' -f1,2,3,4)
CPU_ID=$(dmidecode -t processor | grep ID | cut -d: -f2 | sed 's/^ *//' | xargs)
CPU_FREQUENCY_MIN=$(lscpu | grep MHz | cut -d: -f2 | sed -n '3p' | tr -s " " | sed 's/\ //' | cut -d, -f1)
CPU_FREQUENCY_CUR=$(dmidecode | grep "MHz" | cut -d: -f2 | sed -n '3p' | sed 's/\ //')
CPU_FREQUENCY_MAX=$(dmidecode | grep "MHz" | cut -d: -f2 | sed -n '2p' | sed 's/\ //')
CPU_CORES_NUMBER=$(inxi | grep core | cut -d' ' -f2 | sed 's/-core//')
CPU_THREADS_NUMBER=$(nproc)
#---------------------------------

#------------ RAM ----------------
RAM_SIZE=$(lsmem | grep "Total online memory" | cut -d: -f2 | sed 's/\ *//')
RAM_GEN=$(dmidecode -t memory | grep Type: | grep -v Unknown | tail -n1 | cut -d: -f2 | sed 's/\ //')
RAM_NUMBER=$(dmidecode --type memory | grep 'Rank' | wc -l)
RAM_SLOTS_NUMBER=$(dmidecode --type memory | grep "Number Of Devices" | cut -d: -f2 | sed 's/\ //')
#---------------------------------

#------------ COMPONENTS ---------
MB_SERIAL=$(dmidecode | grep -A 4 "Base Board" | tail -n1 | cut -d: -f2 | sed 's/\ //')

#------------ STORAGE ------------

disks_partitions(){
    declare -a DEVICES
    mapfile -t DEVICES < <(lsblk -dn -o NAME |grep -v loop)

    declare -A PARTITIONS_BY_DISK

    for disk in ${DEVICES[@]}; do
        disk_path="/dev/$disk"
        disk_parts=$(lsblk -nr -o PKNAME,PATH $disk_path |grep -vE "^\ " |cut -d\  -f 2)
        PARTITIONS_BY_DISK[$disk]="${disk_parts[@]}"
    done

    echo "DISKS=${DEVICES[@]}" >> $SUM_FILE

    echo "Partitions in each disks: " >> $SUM_FILE

    for disk in ${!PARTITIONS_BY_DISK[@]}; do
        echo "PARTS_$disk=$(printf '%s ' ${PARTITIONS_BY_DISK[$disk]})" >> $SUM_FILE
    done
}

SIZES=$(lsblk -dnb | grep -v loop | grep -v boot | tr -s " " | cut -d \  -f4)
STOCKAGE_TOTAL=0

for SIZE in ${SIZES[@]}; do
    TOTAL_STORAGE+=$SIZE
done

TOTAL_STORAGE=$(numfmt --to iec $TOTAL_STORAGE)
#---------------------------------

# Compile Hardware informations
hardware() {
    echo "[HARDWARE]" >> $SUM_FILE
    echo "MB_SERIAL = $MB_SERIAL" >> $SUM_FILE
    echo "" >> $SUM_FILE

    echo "--- CPU DATA ---" >> $SUM_FILE
    echo "CPU_MODEL = $CPU_MODEL" >> $SUM_FILE
    echo "CPU_ID = $CPU_ID" >> $SUM_FILE
    echo "CPU_CORES_NUMBER=$CPU_CORES_NUMBER" >> $SUM_FILE
    echo "CPU_THREADS_NUMBER=$CPU_THREADS_NUMBER" >> $SUM_FILE
    echo "CPU_FREQUENCY_MIN=$CPU_FREQUENCY_MIN" >> $SUM_FILE
    echo "CPU_FREQUENCY_CUR=$CPU_FREQUENCY_CUR" >> $SUM_FILE
    echo "CPU_FREQUENCY_MAX=$CPU_FREQUENCY_MAX" >> $SUM_FILE
    echo "" >> $SUM_FILE

    echo "--- GPU DATA ---" >> $SUM_FILE
    echo "GPU_MODEL=$GPU_MODEL" >> $SUM_FILE
    echo "" >> $SUM_FILE

    echo "--- RAM DATA ---" >> $SUM_FILE
    echo "RAM_SIZE = $RAM_SIZE" >> $SUM_FILE
    echo "RAM_GEN = $RAM_GEN" >> $SUM_FILE
    echo "RAM_SLOTS_NUMBER=$RAM_SLOTS_NUMBER" >> $SUM_FILE
    echo "RAM_NUMBER=$RAM_NUMBER" >> $SUM_FILE

    for i in $(seq 1 $RAM_SLOTS_NUMBER); do
	R_SIZE=$(sudo dmidecode --type=memory | grep "Size:" | grep -v "Volatile" | grep -v "Cache" | grep -v "Logical" | cut -d: -f2 | sed -n "${i}p" | sed 's/\ //')
	R_SLOT=$i
	R_FREQ=$(sudo dmidecode --type=memory | grep Speed | grep -v "Memory" | cut -d: -f2 | sed -n "${i}p" | sed 's/\ //')

	echo "RAM_${i}_SIZE=$R_SIZE" >> $SUM_FILE
	echo "RAM_${i}_SLOT=$R_SLOT" >> $SUM_FILE
	echo "RAM_${i}_FREQ=$R_FREQ" >> $SUM_FILE
    done
    echo "" >> $SUM_FILE

    echo "--- STORAGE DATA ---" >> $SUM_FILE
    disks_partitions
    echo "STORAGE = $TOTAL_STORAGE" >> $SUM_FILE
    echo "" >> $SUM_FILE
}

################################################

######## SOFTWARE PART #########################
OS=$(lsb_release -a | grep Description | cut -f2)
ARCH=$(uname -a | cut -d' ' -f10)
KERNEL=$(uname -r)

# Compile Software informations
software() {
    echo "[SOFTWARE]"
    echo "OS = $OS"
    echo "ARCHITECTURE = $ARCH"
    echo "KERNEL = $KERNEL"
    echo "DESKTOP = $XDG_CURRENT_DESKTOP"
    echo "WINDOW MANAGER = $XDG_SESSION_TYPE"
} >> $SUM_FILE

###############################################

# Making the summary
hello
hardware
software

echo "Grabber has complete his mission! Find every logs saved in your home repository /grabber folder."