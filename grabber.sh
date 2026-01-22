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

##### Start process #####
echo "   ____     ____        _        ____     ____  U _____ u   ____     "                                                                                                                
echo 'U /"___|uU |  _"\ u U  /"\  u U | __")uU | __")u\| ___"|/U |  _"\ u  '
echo '\| |  _ / \| |_) |/  \/ _ \/   \|  _ \/ \|  _ \/ |  _|"   \| |_) |/  '
echo " | |_| |   |  _ <    / ___ \    | |_) |  | |_) | | |___    |  _ <    "
echo "  \____|   |_| \_\  /_/   \_\   |____/   |____/  |_____|   |_| \_\   "
echo "  _)(|_    //   \ \_ \ \  \ \  _|| \ \_  _|| \ \_ <<   >>  / /  \ \  "
echo " (__)__)  (__)  (__)(__)  (__)(__) (__)(__) (__)(__) (__) (__)  (__) "      
echo ""
echo "Welcome to grabber!"

#----- Verify sudo command -----
if [[ $EUID -ne 0 ]]; then
    echo "Please run as root to be able to use superuser commands as dmidecode -> sudo ./grabber.sh"
    exit 1
fi
echo ""

#----- Verify dependecies available -----
REQUIRED_CMDS_SIMPLE=(inxi dmidecode lscpu lsblk nproc numfmt)
REQUIRED_CMDS_FULL=(inxi dmidecode lscpu lsblk nproc numfmt python3 jq)

requirements_simple() {
    echo -n "Checking dependencies... "
    MISSING=()

    for cmd in "${REQUIRED_CMDS_SIMPLE[@]}"; do
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
}

requirements_full() {
    echo -n "Checking dependencies... "
    MISSING=()

    for cmd in "${REQUIRED_CMDS_FULL[@]}"; do
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
}

#----- Ask what user wants to do -----
echo "What you want grabber to do for you?"
echo "1: Simple grab (Just make a summary file with your computer data)"
echo "2: Full grab (Grab and makes a showcase webpage)"

read -p " 1 / 2 / Cancel(c):- " choice
if [ "$choice" = "1" ]; then 
echo "Simple task for today"
requirements_simple
elif [ "$choice" = "2" ];then
echo "Big work for today"
requirements_full
elif [ "$choice" = "c" ];then
echo "Installation cancelled"
exit
else 
echo "No choices detected!"
fi


##### MAIN VARIABLES #####

DATE=$(date +'%Y-%m-%d_%H:%M:%S')

# Check who is behind sudo command then fetch his $HOME
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"

# Declare where to store grabber results
NAME_DIR="logs_$DATE"
WORKING_DIR="$REAL_HOME/grabber/$NAME_DIR"
mkdir $WORKING_DIR -p

# Declare the files to be written
SUM_FILE=$WORKING_DIR/summary.txt
SUCCESS_LOG=$WORKING_DIR/grabber-success.log
ERROR_LOG=$WORKING_DIR/grabber-error.log

# Create the logs files
touch $SUM_FILE $SUCCESS_LOG $ERROR_LOG

# Starting text for logs
echo -e "Logs of $DATE :\n" > $SUCCESS_LOG
echo -e "Logs of $DATE :\n" > $ERROR_LOG

#--------- Tables associates source file to a file inside grabber folder, we won't use it atm ---------

#-------- ARRAYS -----------------------------
## FILES arrays
#declare -A FILES

#FILES=(
#    ["sources_list.file"]="/etc/apt/sources.list*"
#    ["passwd.file"]="/etc/passwd"
#    ["group.file"]="/etc/group"
#    ["etc-network-interfaces.file"]="/etc/network/interfaces"
#    ["etc-resolv-conf.file"]="/etc/resolv.conf"
#)

## CMD arrays
#declare -A CMD

#CMD=(
#	["systemd-analyze.cmd"]="systemd-analyze"
#	["systemd-blame.cmd"]="systemd-analyze blame"
#	["lspci.cmd"]="lspci"
#	["lsmem.cmd"]="lsmem --output-all"
#	["lscpu.cmd"]="lscpu"
#	["lsusb.cmd"]="lsusb"
#	["apt-installed.cmd"]="apt list --installed"
#)
#----------------------------------------------

## Call arrays and store in files with same command name then write if success or not in proper log file
#treat_file() {
#	cat $2 | grep -v '^#' | grep -v '^$' > $1 
#	if [ $? -eq 0 ]; then
#		echo "[OK]: Fichier $1 géneré" >> $SUCCESS_LOG
#	else
#		echo "[ECHEC]: Erreur a la génération de $1 => Code de sortie $?" >> $ERROR_LOG
#	fi
#}

#for file in "${!FILES[@]}"; do
#	treat_file $file "${FILES[$file]}"
#done

#treat_cmd() {
#    eval "$2" > $DIR/$1 2> >(tee -a $ERROR_LOG)
#    if [ $? -eq 0 ]; then
#    	echo "[OK]: Fichier $1 géneré avec la commande $2" >> $SUCCESS_LOG
#    else
#    	echo "[ECHEC]: Erreur a la génération de $1 => Code de sortie $?" >> $ERROR_LOG
#   fi
#}

#for cmd in "${!CMD[@]}"; do
#	treat_cmd "$cmd" "${CMD[$cmd]}"
#done
###############################################

############ WRITING THE SUMMARY #################
# Starting text for summary
hello () {
    echo "+++++++++++++++++++++++++" >> $SUM_FILE
    echo "Grabber startin'" >> $SUM_FILE
    echo "launched the $DATE by $REAL_USER" >> $SUM_FILE
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
CPU_CORES=$(inxi | grep core | cut -d' ' -f2 | sed 's/-core//')
CPU_THREADS=$(nproc)
#---------------------------------

#------------ RAM ----------------
RAM_SIZE=$(lsmem | grep "Total online memory" | cut -d: -f2 | sed 's/\ *//')
RAM_NUMBER=$(dmidecode --type memory | grep 'Rank' | wc -l)
RAM_SLOTS=$(dmidecode --type memory | grep "Number Of Devices" | cut -d: -f2 | sed 's/\ //')
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
TOTAL_STORAGE=0

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
    echo "CPU_CORES=$CPU_CORES" >> $SUM_FILE
    echo "CPU_THREADS=$CPU_THREADS" >> $SUM_FILE
    echo "CPU_FREQUENCY_MIN=$CPU_FREQUENCY_MIN" >> $SUM_FILE
    echo "CPU_FREQUENCY_CUR=$CPU_FREQUENCY_CUR" >> $SUM_FILE
    echo "CPU_FREQUENCY_MAX=$CPU_FREQUENCY_MAX" >> $SUM_FILE
    echo "" >> $SUM_FILE

    echo "--- GPU DATA ---" >> $SUM_FILE
    echo "GPU_MODEL=$GPU_MODEL" >> $SUM_FILE
    echo "" >> $SUM_FILE

    echo "--- RAM DATA ---" >> $SUM_FILE
    echo "RAM_SIZE = $RAM_SIZE" >> $SUM_FILE
    echo "RAM_SLOTS=$RAM_SLOTS" >> $SUM_FILE
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
HOSTNAME=$(hostname)

# Compile Software informations
software() {
    echo "[SOFTWARE]"
    echo "OS = $OS"
    echo "HOSTNAME = $HOSTNAME"
    echo "ARCHITECTURE = $ARCH"
    echo "KERNEL = $KERNEL"
    echo "DESKTOP_ENV = $XDG_CURRENT_DESKTOP"
    echo "WINDOW_MANAGER = $XDG_SESSION_TYPE"
} >> $SUM_FILE

###############################################

##### JSON PART ###############################
json_file() { 
    json_data=$(jq -n \
        --arg motherboard "$MB_SERIAL" \
        --arg cpu_model "$CPU_MODEL" \
        --arg cpu_id "$CPU_ID" \
        --arg cpu_cores "$CPU_CORES" \
        --arg cpu_threads "$CPU_THREADS" \
        --arg cpu_frequency_min "$CPU_FREQUENCY_MIN" \
        --arg cpu_frequency_cur "$CPU_FREQUENCY_CUR" \
        --arg cpu_frequency_max "$CPU_FREQUENCY_MAX" \
        --arg gpu_model "$GPU_MODEL" \
        --arg ram_slots "$RAM_SLOTS" \
        --arg hostname "$HOSTNAME" \
        --arg os "$OS" \
        --arg arch "$ARCH" \
        --arg desktop_env "$XDG_CURRENT_DESKTOP" \
        --arg window_manager "$XDG_SESSION_TYPE" \
        --arg kernel "$KERNEL" \
        '{
        HARDWARE: {
            motherboard: $motherboard,
            cpu_model: $cpu_model,
            cpu_id: $cpu_id,
            cpu_cores: $cpu_cores,
            cpu_threads: $cpu_threads,
            cpu_frequency_min: $cpu_frequency_min,
            cpu_frequency_cur: $cpu_frequency_cur,
            cpu_frequency_max: $cpu_frequency_max,
            gpu_model: $gpu_model,
            ram_slots: $ram_slots
        },
        SOFTWARE: {
            hostname: $hostname,
            os: $os,
            arch: $arch,
            desktop_env: $desktop_env,
            window_manager: $window_manager,
            kernel: $kernel
        }
        }'
    )
    
    # Envoi au serveur
    curl -X POST http://localhost:8000/endpoint \
         -H "Content-Type: application/json" \
         -d "$json_data"
}

python_venv() {
    if [ ! -d "./gbvenv" ]; then
        echo "Virtual environement doesn't exist, creating one..."
        python3 -m venv gbvenv
    fi
    source gbvenv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    uvicorn app:app --reload --host 0.0.0.0 --port 8000
}

# Making the summary
echo "It's grabbin time!"
hello
echo "Fetching hardware data..."
hardware
echo "Fetching software data..."
software
echo "Writing everything in summary.txt"
if [ "$choice" = "1" ]; then 
    echo "Grabber has complete his mission! Find every logs saved in your home repository inside the /grabber folder."
    echo "See you space cowboy..."
else
    echo "Creating a python virtual environement and starting server..."
    # 1. On lance la fonction python_venv en arrière-plan avec '&'
    python_venv &
    
    # On récupère l'ID du processus du serveur pour pouvoir l'attendre plus tard
    SERVER_PID=$!

    echo "Waiting for server to initialize (10s)..."
    # 2. On attend quelques secondes que uvicorn soit bien démarré
    sleep 10

    echo "Pushing fetch data into json file..."
    # 3. Maintenant que le serveur tourne, on envoie le JSON
    json_file

    echo "Grabber has complete his mission! Find every logs saved in your home repository inside the /grabber folder."
    echo "Server is running on http://localhost:8000. Press Ctrl+C to stop."
    
    # 4. On empêche le script de se fermer (ce qui tuerait le serveur si configuré ainsi)
    wait $SERVER_PID
fi