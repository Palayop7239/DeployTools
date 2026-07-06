#!/bin/bash

TMP_DIR=$(mktemp -d)
echo -e "\e[36m[*] Initializing setup environment...\e[0m"
curl -sL https://github.com/charmbracelet/gum/releases/download/v0.14.1/gum_0.14.1_Linux_x86_64.tar.gz | tar xz -C $TMP_DIR
GUM="$TMP_DIR/gum_0.14.1_Linux_x86_64/gum"

clear


$GUM style --border double --margin "1" --padding "1 2" --border-foreground 212 "Server Deployment Toolkit v1.0"

echo "Select the target profile for this machine:"

PROFILE=$($GUM choose "1. Docker Web Host" "2. Pterodactyl Panel Base" "3. Secure Core (No Apps)" "Cancel")


rm -rf $TMP_DIR


clear

case $PROFILE in
    "1. Docker Web Host")
        echo -e "\e[32m[+] Starting Docker deployment...\e[0m"

        apt-get update -y
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
        echo -e "\e[32m[+] Docker installed successfully.\e[0m"
        ;;
        
    "2. Pterodactyl Panel Base")
        echo -e "\e[32m[+] Prepping Pterodactyl Installation...\e[0m"
        apt-get update -y

        bash <(curl -s https://pterodactyl-installer.se)
        ;;
        
    "3. Secure Core (No Apps)")
        echo -e "\e[32m[+] Locking down machine...\e[0m"
        apt-get install ufw -y
        ufw allow 22/tcp
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw --force enable
        echo -e "\e[32m[+] Firewall secured.\e[0m"
        ;;
        
    "Cancel"|"")
        echo -e "\e[31m[-] Deployment aborted.\e[0m"
        exit 0
        ;;
esac

echo -e "\e[32m[+] All tasks complete. Exiting.\e[0m"