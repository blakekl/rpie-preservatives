#!/usr/bin/env bash
###############################################################################
# This is a script to backup all save files when using retropie. It syncs the
# local save files to the remote using rclone.
#
# Requires rclone to be installed
# Requires xmlstarlet to be installed
###############################################################################

###############################################################################
# This is the variable that is your backup on the remote. No changes are
# necessary if you followed the instructions in the readme and setup your 
# rclone remote with these names. Otherwise, you'll need to proved a new value
# here to whatever you named your drive.
###############################################################################
RCLONE_DRIVE="retropie-backup:retropie-backup"

###############################################################################
# This is the rest of the script that performs the actual work. Do not modiy
# anything below this unless you know what you're doing.
###############################################################################
COMMAND=$1
SYSTEM=$2
EMULATOR=$3
ROM_PATH=$4
FULL_COMMAND=$5
GREEN="\e[92m"
RED="\e[91m"
PLAIN="\e[39m"

###############################################################################
# Scans the /etc/emulationstation/es_systems.cfg file to find the extensions of
# rom files. This data is then used to build an exclusion list, so we don't
# end up syncing large rom files by mistake.
###############################################################################
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

###############################################################################
# uses rclone to sync the remote directory with the local file system for the
# system we are running. 
###############################################################################
sync() {
    local ROMS_DIR="${HOME}/RetroPie/roms/${SYSTEM}"
    local EXCLUDE="${GAME_EXTENSIONS[$SYSTEM_INDEX]}"
    local SOURCE=""
    local DEST=""
    if [ "$COMMAND" = "download" ]; then
        SOURCE="${RCLONE_DRIVE}/${SYSTEM}"
        DEST="${ROMS_DIR}"
    else
        SOURCE="${ROMS_DIR}"
        DEST="${RCLONE_DRIVE}/${SYSTEM}"
    fi
    echo ""
    echo "  Syncing $SYSTEM save files..."
    rclone sync "${SOURCE}" "${DEST}" -P \
        --exclude "*.{state*,xml,txt,chd,ips,ups,bps,DS_Store,oops,0*}" \
        --exclude "media/**" \
        --exclude "mame*/**" \
        --exclude "**sd.raw" \
        --exclude "Mupen64plus/**" \
        --exclude "User/Cache**" \
        --exclude "User/Config**" \
        --exclude "User/Logs**" \
        --exclude "PSP/SYSTEM/**" \
        --exclude "$EXCLUDE"
}

###############################################################################
# Checks whether a system is calid to sync or not. If valid, syncs the system.
# Skips syncing on systems that don't support it (mostly mame). This function
# is not complete, as I don't have roms for all the systems supported by
# retroarch, and I don't plan on emulating them all either.
###############################################################################
syncIfValidSystem() {
    case $SYSTEM in 
        mame) ;&
        arcade) ;&
        fba) ;&
        mame-advmame) ;&
        mame-libretro) ;&
        mame-mame4all) ;&
        mame2016) echo "No saves for arcade machines. Skipping." ;;
        retropie) echo "skipping retropie directory" ;;
        *) sync ;;
    esac
}

###############################################################################
# Prints instructions.
###############################################################################
printUsage() {
    echo "Usage: rpie-preservatives.sh <command> <system name> <emulator> <rom path> <full command>"
    echo "  command is required. Must be either 'upload' or 'download'."
    echo "  system name is the name of the system in es_systems.cfg (eg:  nes,atari2600,gba,etc)."
    echo "  emulator: the core name that was launched (eg: lr-stella,lr-fceumm,etc)"
    echo "  rom path: full path to the rom file"
    echo "  full command: the full command line used to launch the emulator."
}

###############################################################################
# prints a warning that all saves will be synced. Displays instructions on
# cancelling the script and provides a 5 second timer to allow cancelling.
###############################################################################
printAllSystemWarning() {
    echo "No system passed in. All saves will be ${COMMAND}ed. (Ctl-C to abort)"
    printf "syncing in 5"
    sleep 1
    printf "\rsyncing in 4"
    sleep 1
    printf "\rsyncing in 3"
    sleep 1
    printf "\rsyncing in 2"
    sleep 1
    printf "\rsyncing in 1"
    sleep 1
    printf "\rsyncing in 0"
    printf "\r*** Syncing ***"
}

getSystemsExtensionExclusions

if [ $# -eq 0 ]; then
    printUsage
elif [ $# -eq 1 ]; then
    if [ "$1" = "upload" ] || [ "$1" = "download" ]; then
        printAllSystemWarning
        for i in "${!SYSTEMS[@]}"; do
            SYSTEM_INDEX="$i"
            SYSTEM="${SYSTEMS[$i]}"
            syncIfValidSystem
        done
    else
        printUsage
    fi
else
    syncIfValidSystem
fi
