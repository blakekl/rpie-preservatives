#!/usr/bin/env bash
###############################################################################
# This is a script backup all save files when using retropie. It syncs the
# local save files to the remote using rclone.
#
# Requires rclone to be installed
# Requires xmlstarlet to be installed
###############################################################################
SYSTEM=$1
EMULATOR=$2
ROM_PATH=$3
FULL_COMMAND=$4
GREEN="\e[92m"
RED="\e[91m"
PLAIN="\e[39m"
TMP="/tmp"
RCLONE_DRIVE="retropie-backup:retropie-backup"

getSystemsExtensionExclusions() {
    mapfile -t < <( xmlstarlet sel -t -m "/systemList/system"  -v "name" -n /etc/emulationstation/es_systems.cfg )
    SYSTEMS=("${MAPFILE[@]}")

    mapfile -t < <( xmlstarlet sel -t -m "/systemList/system"  -v "extension" -n /etc/emulationstation/es_systems.cfg | sed "s/.//" | sed "s/ ./,/g" | sed "s/^/*.{/" | sed "s/$/}/" )
    GAME_EXTENSIONS=("${MAPFILE[@]}")

    for i in "${!SYSTEMS[@]}"; do
        if [ "${SYSTEMS[$i]}" = "$SYSTEM" ]; then
           SYSTEM_INDEX="$i"
        fi
    done
}

normalSync() {
    local ROMSDir="${HOME}/RetroPie/roms"
    local EXCLUDE="${GAME_EXTENSIONS[$SYSTEM_INDEX]}"
    echo "Downloading $SYSTEM save files..."
    echo ""
    rclone sync "$RCLONE_DRIVE/$SYSTEM" "$ROMSDir/$SYSTEM" -P --exclude "*.{state*,xml,txt,chd,DS_Store,oops,0*}" --exclude "media/**" --exclude "mame*/**" --exclude "**sd.raw"  --exclude "Mupen64plus/**"  --exclude "$EXCLUDE"
}

case $SYSTEM in 
    mame)
        ;&
    arcade)
        ;&
    fba)
        ;&
    mame-advmame)
        ;&
    mame-libretro)
        ;&
    mame-mame4all)
        ;&
    mame2016)
        echo "No saves for arcade machines. Exiting."
        sleep 2
        ;;
    *)
        echo "Building exclusion list..."
        getSystemsExtensionExclusions
        normalSync
        ;;
esac
