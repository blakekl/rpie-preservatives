#!/usr/bin/env bash
###############################################################################
# Scans the es_systems_path file to find the extensions of  rom files. This 
# data is then used to build an exclusion list, so we don't end up syncing 
# large rom files by mistake.
###############################################################################
getSystemsExtensionExclusions() {
    mapfile -t < <( xmlstarlet sel -t -m "/systemList/system"  -v "name" -n ${es_systems_path} )
    SYSTEMS=("${MAPFILE[@]}")

    mapfile -t < <( xmlstarlet sel -t -m "/systemList/system"  -v "extension" -n ${es_systems_path} | sed "s/.//" | sed "s/ ./,/g" | sed "s/^/*.{/" | sed "s/$/}/" )
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
syncDirectory() {
    local system_path="${roms_path}/${SYSTEM}"
    local exclude="${GAME_EXTENSIONS[$SYSTEM_INDEX]}"
    local source=""
    local dest=""
    local states="state*,"

    if [ "$COMMAND" = "download" ]; then
        source="${rclone_drive}/${SYSTEM}"
        dest="${system_path}"
    else
        source="${system_path}"
        dest="${rclone_drive}/${SYSTEM}"
    fi

    if [ "$sync_save_states" = "true" ]; then
        states=""
    fi

    echo ""
    echo "  Syncing $SYSTEM save files..."
    rclone sync "${source}" "${dest}" -P \
        --exclude "*.{${states}xml,txt,chd,ips,ups,bps,DS_Store,oops,0*}" \
        --exclude "media/**" \
        --exclude "mame*/**" \
        --exclude "**sd.raw" \
        --exclude "Mupen64plus/**" \
        --exclude "User/Cache**" \
        --exclude "User/Config**" \
        --exclude "User/Logs**" \
        --exclude "PSP/SYSTEM/**" \
        --exclude "$exclude"
}

###############################################################################
# Checks whether a system is valid to sync or not. If valid, syncs the system.
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
        *) syncDirectory ;;
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
    printCountdown
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

###############################################################################
# prints a list of the current settings before performing the sync.
###############################################################################
printConfig() {
    echo "executing with current settings: "
    echo "  rclone_drive: $rclone_drive"
    echo "  roms_path: $roms_path"
    echo "  sync_save_states: $sync_save_states"
    echo ""
}

###############################################################################
# prints a countdown before proceeding.
###############################################################################
printCountdown() {
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

###############################################################################
# Verifies the values in the settings file to ensure the values are valid.
# Prints out any errors it finds.
###############################################################################
verifySettings() {
    echo "verifying settings."
}


###############################################################################
# prints the missing config file message.
###############################################################################
printMissingConfig() {
    local workingDir=`pwd`
    echo "rpie-settings.cfg could not be found. Ensure rpie-settings.cfg exist in ${workingDir}"
    exit 1
}

COMMAND=$1
SYSTEM=$2
EMULATOR=$3
ROM_PATH=$4
RUN_COMMAND=$5

GREEN="\e[92m"
RED="\e[91m"
PLAIN="\e[39m"

if test -f "./rpie-settings.cfg"; then
    . ./rpie-settings.cfg
else
    printMissingConfig
fi

printConfig
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


