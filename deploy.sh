#!/bin/bash

TMP_DIR=$(mktemp -d)
echo -e "\e[36m[*] Bringing up the buddy...\e[0m"
curl -sL https://github.com/charmbracelet/gum/releases/download/v0.14.1/gum_0.14.1_Linux_x86_64.tar.gz | tar xz -C $TMP_DIR > /dev/null 2>&1
GUM="$TMP_DIR/gum_0.14.1_Linux_x86_64/gum"
clear

HOUR=$(date +"%H")
if [ $HOUR -lt 12 ]; then
    GREETING="Good morning, dude."
elif [ $HOUR -lt 18 ]; then
    GREETING="Good afternoon, dude."
else
    GREETING="Late night coding session? Let's get to work."
fi

echo -e "\e[1;33m$GREETING\e[0m\n"

$GUM style --border double --margin "1" --padding "1 2" --border-foreground 212 "Pala's Deploying Utilities v1.0"

echo "What are we up to today?:"

PROFILE=$($GUM choose \
    "1. Setting up web hosting through Docker" \
    "2. Setting up Pterodactyl" \
    "3. Initializing UFW for basic web hosting" \
    "Nothing sorry for calling ya")

clear

case $PROFILE in
    "1. Setting up web hosting through Docker")
        $GUM spin --spinner monkey --title "Let me call the Docker dude... hold on." -- bash -c "apt-get update -y && curl -fsSL https://get.docker.com | sh"
        echo -e "\e[32m[+] Docker is up and running. Ready for what's next.\e[0m"
        ;;
        
    "2. Setting up Pterodactyl")
        $GUM spin --spinner dot --title "Updating stuff before going in..." -- bash -c "apt-get update -y"
        bash <(curl -s https://pterodactyl-installer.se)
        ;;
        
    "3. Initializing UFW for basic web hosting")
        $GUM spin --spinner line --title "Cooking up the wall..." -- bash -c "apt-get install ufw -y && ufw allow 22/tcp && ufw allow 80/tcp && ufw allow 443/tcp && ufw --force enable"
        echo -e "\e[32m[+] Firewall ready. Don't forget to allow the ports you actually need.\e[0m"
        ;;
        
    "Nothing sorry for calling ya"|"")
        echo -e "\e[31m[-] Going back to sleep. Don't bring me for nothing bruh.\e[0m"
        rm -rf $TMP_DIR
        exit 0
        ;;
esac


rm -rf $TMP_DIR

echo -e "\e[32m[+] Got the work done. GGs.\e[0m"