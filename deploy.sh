#!/bin/bash

TMP_DIR=$(mktemp -d)
GUM_TTY="/dev/tty"

echo -e "\e[36m[*] Bringing up the buddy...\e[0m"
curl -sL https://github.com/charmbracelet/gum/releases/download/v0.14.1/gum_0.14.1_Linux_x86_64.tar.gz | tar xz -C $TMP_DIR > /dev/null 2>&1
GUM="$TMP_DIR/gum_0.14.1_Linux_x86_64/gum"
clear

if [ ! -e "$GUM_TTY" ]; then
    echo -e "\e[31m[-] No /dev/tty available, can't run interactively here. Download the script and run it locally instead.\e[0m"
    rm -rf $TMP_DIR
    exit 1
fi

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
    "4. Setting up a Minecraft Server" \
    "Nothing sorry for calling ya" < "$GUM_TTY")

clear

case $PROFILE in
    "1. Setting up web hosting through Docker")
        $GUM spin --spinner monkey --title "Let me call the Docker dude... hold on." -- bash -c "apt-get update -y && curl -fsSL https://get.docker.com | sh"
        echo -e "\e[32m[+] Docker is up and running. Ready for what's next.\e[0m"
        ;;

    "2. Setting up Pterodactyl")
        $GUM spin --spinner dot --title "Updating stuff before going in..." -- bash -c "apt-get update -y"
        bash <(curl -s https://pterodactyl-installer.se) < "$GUM_TTY"
        ;;

    "3. Initializing UFW for basic web hosting")
        $GUM spin --spinner line --title "Cooking up the wall..." -- bash -c "apt-get install ufw -y && ufw allow 22/tcp && ufw allow 80/tcp && ufw allow 443/tcp && ufw --force enable"
        echo -e "\e[32m[+] Firewall ready. Don't forget to allow the ports you actually need.\e[0m"
        ;;

    "4. Setting up a Minecraft Server")
        if ! command -v jq >/dev/null 2>&1; then
            $GUM spin --spinner dot --title "Grabbing jq real quick..." -- bash -c "apt-get update -y && apt-get install -y jq"
        fi

        SERVER_TYPE=$($GUM choose \
            "Paper" \
            "Purpur" \
            "Fabric" \
            "NeoForge" \
            "Vanilla" \
            "Velocity" < "$GUM_TTY")

        MC_DIR=$($GUM input --placeholder "Where should this live? (e.g. /opt/mc/tbs)" < "$GUM_TTY")
        mkdir -p "$MC_DIR"

        case $SERVER_TYPE in

            "Paper"|"Velocity")
                PROJECT=$(echo "$SERVER_TYPE" | tr '[:upper:]' '[:lower:]')
                UA="palas-deploy-tool/1.0 (https://github.com/Palayop7239/DeployTools)"

                VERSIONS=$(curl -sL -H "User-Agent: $UA" "https://fill.papermc.io/v3/projects/$PROJECT" \
                    | jq -r '.versions | to_entries[] | .value[]' | sort -V -r)
                MC_VERSION=$(echo "$VERSIONS" | $GUM choose < "$GUM_TTY")

                BUILDS_RESPONSE=$(curl -sL -H "User-Agent: $UA" "https://fill.papermc.io/v3/projects/$PROJECT/versions/$MC_VERSION/builds")

                BUILD_ID=$(echo "$BUILDS_RESPONSE" | jq -r '.[] | "\(.id) [\(.channel)]"' \
                    | $GUM choose --header "Pick a build (top = newest)" < "$GUM_TTY" | awk '{print $1}')

                DOWNLOAD_URL=$(echo "$BUILDS_RESPONSE" | jq -r --arg ID "$BUILD_ID" '.[] | select(.id == ($ID|tonumber)) | .downloads."server:default".url')
                JAR_NAME=$(echo "$BUILDS_RESPONSE" | jq -r --arg ID "$BUILD_ID" '.[] | select(.id == ($ID|tonumber)) | .downloads."server:default".name')

                $GUM spin --spinner dot --title "Pulling $PROJECT $MC_VERSION build $BUILD_ID..." -- \
                    curl -sL -H "User-Agent: $UA" -o "$MC_DIR/$JAR_NAME" "$DOWNLOAD_URL"

                ln -sf "$MC_DIR/$JAR_NAME" "$MC_DIR/server.jar"
                ;;

            "Purpur")
                VERSIONS=$(curl -sL "https://api.purpurmc.org/v2/purpur" | jq -r '.versions[]' | tac)
                MC_VERSION=$(echo "$VERSIONS" | $GUM choose < "$GUM_TTY")

                BUILD=$(curl -sL "https://api.purpurmc.org/v2/purpur/$MC_VERSION" | jq -r '.builds.latest')

                $GUM spin --spinner dot --title "Pulling Purpur $MC_VERSION build $BUILD..." -- \
                    curl -sL -o "$MC_DIR/server.jar" "https://api.purpurmc.org/v2/purpur/$MC_VERSION/$BUILD/download"
                ;;

            "Fabric")
                MC_VERSIONS=$(curl -sL "https://meta.fabricmc.net/v2/versions/game" | jq -r '.[] | select(.stable==true) | .version')
                MC_VERSION=$(echo "$MC_VERSIONS" | $GUM choose < "$GUM_TTY")

                LOADER_VERSION=$(curl -sL "https://meta.fabricmc.net/v2/versions/loader" | jq -r '.[0].version')
                INSTALLER_VERSION=$(curl -sL "https://meta.fabricmc.net/v2/versions/installer" | jq -r '.[0].version')

                $GUM spin --spinner dot --title "Pulling Fabric $MC_VERSION (loader $LOADER_VERSION)..." -- \
                    curl -sL -o "$MC_DIR/server.jar" \
                    "https://meta.fabricmc.net/v2/versions/loader/$MC_VERSION/$LOADER_VERSION/$INSTALLER_VERSION/server/jar"
                ;;

            "NeoForge")
                VERSIONS=$(curl -sL "https://maven.neoforged.net/api/maven/versions/releases/net/neoforged/neoforge" | jq -r '.versions[]' | tac)
                NEO_VERSION=$(echo "$VERSIONS" | $GUM choose --header "NeoForge version (e.g. 21.1.x)" < "$GUM_TTY")

                $GUM spin --spinner dot --title "Pulling NeoForge $NEO_VERSION installer..." -- \
                    curl -sL -o "$MC_DIR/installer.jar" \
                    "https://maven.neoforged.net/releases/net/neoforged/neoforge/$NEO_VERSION/neoforge-$NEO_VERSION-installer.jar"

                echo -e "\e[33m[!] Installer downloaded. Run it yourself with:\e[0m"
                echo "    cd $MC_DIR && java -jar installer.jar --installServer"
                ;;

            "Vanilla")
                MANIFEST=$(curl -sL "https://launchermeta.mojang.com/mc/game/version_manifest.json")
                VERSIONS=$(echo "$MANIFEST" | jq -r '.versions[] | select(.type=="release") | .id')
                MC_VERSION=$(echo "$VERSIONS" | $GUM choose < "$GUM_TTY")

                VERSION_URL=$(echo "$MANIFEST" | jq -r --arg V "$MC_VERSION" '.versions[] | select(.id==$V) | .url')
                SERVER_URL=$(curl -sL "$VERSION_URL" | jq -r '.downloads.server.url')

                $GUM spin --spinner dot --title "Pulling Vanilla $MC_VERSION..." -- \
                    curl -sL -o "$MC_DIR/server.jar" "$SERVER_URL"
                ;;
        esac

        if [ -f "$MC_DIR/server.jar" ]; then
            echo "eula=true" > "$MC_DIR/eula.txt"
            echo -e "\e[32m[+] $SERVER_TYPE server dropped in $MC_DIR, eula pre-signed. Fire it up whenever.\e[0m"
        fi
        ;;

    "Nothing sorry for calling ya"|"")
        echo -e "\e[31m[-] Going back to sleep. Don't bring me for nothing bruh.\e[0m"
        rm -rf $TMP_DIR
        exit 0
        ;;

esac

rm -rf $TMP_DIR

echo -e "\e[32m[+] Got the work done. GGs.\e[0m"