#!/bin/bash
export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin
export LC_ALL=C
export LANG=C

# ==============================================================================
#   Script : grabber.sh
#   Version: 0.5 (Full Display)
# ==============================================================================

##### MAIN VARIABLES #####
ALERT='\033[0;31m'
SUCCESS='\033[0;32m'
WARNING='\033[0;33m'
ECM='\033[0m' # stands for END COLOR MESSAGE

ADMIN_ADDRESS=$(cat settings.json | jq -r .ip_address)
PORT=$(cat settings.json | jq -r .port)

########## REQUIREMENTS ##########

REQUIRED_CMDS=(python3 sqlite3 jq)
requirements() {
    echo -n "Checking dependencies... "
    MISSING=()
    for cmd in "${REQUIRED_CMDS[@]}"; do
        command -v "$cmd" >/dev/null 2>&1 || MISSING+=("$cmd")
    done
    if (( ${#MISSING[@]} > 0 )); then
        echo "${ALERT}> Missing dependencies: ${MISSING[*]}${ECM}"
        echo "> Install with: sudo apt install ${MISSING[*]}"
        exit 1
    else
        echo "All set!"
    fi
}

##############################

########## ADMIN PANEL ##########

server() {

    # Check if venv already exists
    if [ ! -d "./gbvenv" ]; then
        python3 -m venv gbvenv
    fi

    # Run venv
    source gbvenv/bin/activate
    pip install -q --upgrade pip
    pip install -q -r requirements.txt

    echo "Checking Superuser existence..."
    if ! python check_admin.py; then
        echo -e "${ALERT}> No Superuser detected! Create one now in order to use Grabber normally.${ECM}"
        echo ""
        python manage.py createsuperuser
    fi

    # Check if user added settings
    if [[ "$ADMIN_ADDRESS" == "null" ]]; then 
        echo -e "${WARNING}> No Address set in settings.json, address "localhost" is chosen${ECM}"
        ADMIN_ADDRESS="localhost" 
    fi
    sleep 1
    if [[ "$PORT" == "null" ]]; then 
        echo -e "${WARNING}> No Address set in settings.json, port "8000" is chosen${ECM}"; 
        PORT="8000"
    fi

    # Run server in background
    sleep 2
    export DJANGO_ALLOWED_HOST=$ADMIN_ADDRESS
    python manage.py runserver $ADMIN_ADDRESS:$PORT > /dev/null &
    SERVER_PID=$!

    trap 'echo -e "\n${WARNING}> Closing the Server...${ECM}"; kill $SERVER_PID; exit 0' INT

    echo ""
    echo -e "${SUCCESS}> Dashboard launched at http://$ADMIN_ADDRESS:$PORT${ECM}"
    echo "> End the session with "CTRL+C""
    echo ""
    echo "[SERVER LOGS]"

    wait $SERVER_PID
}

##############################

########## USER INTERACTION ##########
echo "   ____     ____                 ____     ____  U _____  u   ____     "                                  
echo 'U /\/__|uU |  _"\ u     _     U | o°°)uU | _U")u\| ___"|/ U |  _"\ u  '
echo '\| |  _ / \| |_) |/ U  /0\  u  \|  _ \/ \|  _ \/ |  _|     \| |_) |/  '
echo " | |_| |   |  _ <    \/ 3 \/    | |_) |  | |_) | | |___     |  _ <    "
echo "  \____|   |_| \_\   / ___ \    |____/   |____/  |_____|    |_| \_\   "
echo "  _)(|_    //   \ \_ \ \  \ \  _|| \ \_  _|| \ \_ <<   >>   / /  \ \  "
echo " (__)__)  (__)  (__)(__)  (__)(__) (__)(__) (__)(__) (__)  (__)  (__) "      
echo ""

echo "Welcome, this is the admin side of Grabber"
echo "1: Launch grabber | 2: Uninstall | c: Cancel"
read -p ";> " choice

if [ "$choice" = "1" ]; then

    requirements
    echo ""
    echo "Starting Admin Panel..."
    server

elif [ "$choice" = "2" ]; then 
    echo "Not available atm, uninstall manually by using "rm -rf gbvenv""
    # rm -rf gbvenv 
    exit

elif [ "$choice" = "c" ]; then 
    echo "See you space, cowboy..."
    exit

else echo "Your choice has an error, please retry."; exit; 

fi