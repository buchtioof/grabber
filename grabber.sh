#!/bin/bash
export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin
export LC_ALL=C
export LANG=C

# ==============================================================================
#   Script : grabber.sh
#   Version: 0.4 (Full Display)
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
echo "1: Launch grabber | 2: Uninstall | c: Cancel"
read -p ";> " choice
if [ "$choice" = "1" ]; then requirements;
elif [ "$choice" = "2" ]; then rm -rf gbvenv; exit;
elif [ "$choice" = "c" ]; then exit;
else echo "Invalid choice"; exit; fi

##### MAIN VARIABLES #####
DATE=$(date +'%Y-%m-%d_%H:%M:%S')

############ REQUIREMENTS #################

REQUIRED_CMDS=(inxi lscpu lsblk nproc numfmt python3 jq sqlite3)
requirements() {
    echo -n "Checking dependencies... "
    MISSING=()
    for cmd in "${REQUIRED_CMDS[@]}"; do
        command -v "$cmd" >/dev/null 2>&1 || MISSING+=("$cmd")
    done
    if (( ${#MISSING[@]} > 0 )); then
        echo "Missing dependencies: ${MISSING[*]}"
        echo "Install with: sudo apt install ${MISSING[*]}"
        exit 1
    else
        echo "All set!"
    fi
}

############ HARDWARE FETCHER #################
# --- CPU ---
CPU_MODEL=$(lscpu | grep "Model name:" | cut -d: -f2 | sed 's/^ *//')
_VENDOR=$(lscpu | grep "Vendor ID:" | cut -d: -f2 | xargs)
_FAMILY=$(lscpu | grep "CPU family:" | cut -d: -f2 | xargs)
_MODEL=$(lscpu | grep "Model:" | cut -d: -f2 | xargs)
CPU_ID="${_VENDOR} Fam ${_FAMILY} Mod ${_MODEL}"
CPU_FREQUENCY_MIN=$(lscpu | grep "CPU min MHz" | cut -d: -f2 | xargs | cut -d. -f1)
CPU_FREQUENCY_MAX=$(lscpu | grep "CPU max MHz" | cut -d: -f2 | xargs | cut -d. -f1)
CPU_FREQUENCY_CUR=$(grep "cpu MHz" /proc/cpuinfo | head -n1 | cut -d: -f2 | cut -d. -f1 | xargs)
CPU_CORES=$(lscpu | grep "^CPU(s):" | cut -d: -f2 | xargs)
CPU_THREADS=$(nproc)

# --- RAM ---
# On récupère la RAM totale via free -h
RAM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
# On récupère les slots via inxi
RAM_SLOTS=$(inxi -m -c 0 | grep "slots:" | head -n1 | sed -E 's/.*slots: ([0-9]+).*/\1/')
if [ -z "$RAM_SLOTS" ]; then RAM_SLOTS="N/A"; fi

# --- MOTHERBOARD / GPU ---
MB_SERIAL=$(inxi -M -c 0 | grep "Mobo:" | sed -E 's/.*Mobo: (.*) model: (.*) serial: .*/\1 \2/' | xargs)
[ -z "$MB_SERIAL" ] && MB_SERIAL=$(inxi -M -c 0 | grep "Mobo:" | cut -d: -f2 | cut -d',' -f1 | xargs)
GPU_MODEL=$(inxi -G -c 0 | grep "Device-1:" | cut -d: -f2 | xargs)

# --- STORAGE ---
# Calcul du stockage total
SIZES=$(lsblk -dnb | grep -v loop | grep -v boot | tr -s " " | cut -d \  -f4)
TOTAL_STORAGE=0
for SIZE in ${SIZES[@]}; do TOTAL_STORAGE=$((TOTAL_STORAGE + SIZE)); done
TOTAL_STORAGE=$(numfmt --to iec $TOTAL_STORAGE)

# --- SOFTWARE ---
OS=$(lsb_release -d 2>/dev/null | cut -f2 || grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
ARCH=$(uname -m)
KERNEL=$(uname -r)
HOSTNAME=$(hostname)
DEFAULT_IFACE=$(ls /sys/class/net | grep -vE '^(lo|docker|veth|br)' | head -n 1)
MAC_ADDRESS=$(cat "/sys/class/net/$DEFAULT_IFACE/address" 2>/dev/null || echo "Unknown-MAC")

##### JSON PART #####
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
        --arg ram_total "$RAM_TOTAL" \
        --arg total_storage "$TOTAL_STORAGE" \
        --arg hostname "$HOSTNAME" \
        --arg mac_address "$MAC_ADDRESS" \
        --arg os "$OS" \
        --arg arch "$ARCH" \
        --arg desktop_env "${XDG_CURRENT_DESKTOP:-N/A}" \
        --arg window_manager "${XDG_SESSION_TYPE:-N/A}" \
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
            ram_slots: $ram_slots,
            ram_total: $ram_total,
            total_storage: $total_storage
        },
        SOFTWARE: {
            hostname: $hostname,
            mac_address:$mac_address,
            os: $os,
            arch: $arch,
            desktop_env: $desktop_env,
            window_manager: $window_manager,
            kernel: $kernel
        }
        }'
    )
    
    curl -X POST http://localhost:8000/endpoint \
         -H "Content-Type: application/json" \
         -d "$json_data" \
         --connect-timeout 5 || echo "Erreur: Serveur injoignable."
    echo ""
}

python_venv() {
    [ ! -d "./gbvenv" ] && python3 -m venv gbvenv
    source gbvenv/bin/activate
    pip install -q --upgrade pip
    pip install -q -r requirements.txt
    python manage.py runserver 0.0.0.0:8000
}

if [ "$choice" = "1" ]; then
    echo "Starting Python Server..."
    python_venv &
    SERVER_PID=$!
    sleep 5
    echo "Fetching data..."
    json_file
    echo "Dashboard launched at http://localhost:8000"
    wait $SERVER_PID
fi