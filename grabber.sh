#!/bin/bash
export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin
export LC_ALL=C
export LANG=C

# ==============================================================================
#   Script : grabber.sh
#   Version: 0.9
# ==============================================================================

##### MAIN VARIABLES #####
ALERT='\033[0;31m'      # RED
SUCCESS='\033[0;32m'    # GREEN
WARNING='\033[0;33m'    # YELLOW
ECM='\033[0m'           # END COLOR MESSAGE

ADMIN_ADDRESS=${HOST:-0.0.0.0}
PORT=${PORT:-8000}

##############################

######### CLEANUP END ##########

cleanup() {
    echo -e "\n${WARNING}> Closing the Server...${ECM}"
    kill $SERVER_PID
    echo ""
    echo "See you space cowboy..."
    exit 0
}

##############################

########## ADMIN PANEL ##########

server() {

    # Create if needed the data folder
    if [ ! -d "./data" ]; then
        mkdir -p data
    fi

    # Generate an SSH key for Paramiko
    mkdir -p ./data/keys
    if [ ! -f "data/keys/id_ed25519" ]; then
        echo ""
        echo -e "${YELLOW}No SSH key detected, generating one...${ECM}"
        ssh-keygen -t ed25519 -f ./data/keys/id_ed25519 -N "" -q
        echo "${GREEN}> Done!${ECM}"
    fi

    if [ ! -f "./data/keys/secret.key" ]; then
        echo -e "${YELLOW}No Django Secret Key detected, generating one...${ECM}"
        openssl rand -base64 48 > ./data/keys/secret.key
    fi

    # Generate session token and save in a variable
    export SESSION_TOKEN=$(openssl rand -hex 32)

    # Prepare DB
    echo "Checking database..."
    python manage.py makemigrations > /dev/null
    python manage.py migrate --noinput > /dev/null

    # Check for admin user
    echo "Checking Admin existence..."
    if ! python ./lib/check_admin.py > /dev/null 2>&1; then

        if [[ -n "$DJANGO_SUPERUSER_USERNAME" && -n "$DJANGO_SUPERUSER_PASSWORD" ]]; then
            echo "Creating default admin from .env variables..."
            python manage.py createsuperuser --noinput > /dev/null 2>&1 || echo -e "${WARNING}> Failed to create admin. Password might be too common.${ECM}"
        else
            echo -e "${WARNING}> No Superuser detected and no credentials found in .env!${ECM}"
            echo -e "${WARNING}> To create one later, run: docker exec -it grabber-prod python manage.py createsuperuser${ECM}"
        fi
    else
        echo -e "${WARNING}> Done!${ECM}"
    fi

    # Place static files inside "staticfiles" Django folder
    echo "Collecting static files..."
    python manage.py collectstatic --noinput --ignore "input.css" > /dev/null
    
    echo "Starting the server..."
    export DJANGO_ALLOWED_HOST=$ADMIN_ADDRESS

    # Check if user added settings
    if [[ -z "$ADMIN_ADDRESS" || "$ADMIN_ADDRESS" == "null" ]]; then 
        echo -e "${WARNING}> No Address set in settings.json, address "localhost" is chosen${ECM}"
    fi
    sleep 1
    if [[ -z "$PORT" || "$PORT" == "null" ]]; then 
        echo -e "${WARNING}> No Address set in settings.json, port "8000" is chosen${ECM}";
    fi

    # Run server in background
    sleep 2
    export DJANGO_ALLOWED_HOST=$ADMIN_ADDRESS
    gunicorn config.wsgi:application --bind 0.0.0.0:$PORT --workers 3 --access-logfile - &
    SERVER_PID=$!

    trap cleanup INT

    echo ""
    echo -e "${SUCCESS}> Dashboard launched at http://$ADMIN_ADDRESS:$PORT${ECM}"
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
echo "Hello World!"
echo ""
echo "Starting Admin Panel..."
server

##############################