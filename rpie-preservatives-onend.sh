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
SYSTEM=$1
EMULATOR=$2
ROM_PATH=$3
FULL_COMMAND=$4
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
    echo ""
    echo "  Syncing $SYSTEM save files..."
    rclone sync "$ROMS_DIR" "$RCLONE_DRIVE/$SYSTEM" -P \
        --exclude "*.{state*,xml,txt,chd,ips,ups,bps,DS_Store,oops,0*}" \
        --exclude "media/**" \
        --exclude "mame*/**" \
        --exclude "**sd.raw" \
        --exclude "Mupen64plus/**" \
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
            echo "No saves for arcade machines. Skipping."
            sleep 2
            ;;
        retropie)
            echo "skipping retropie directory"
            sleep 2
            ;;
        *)
            sync
            ;;
    esac
}

getSystemsExtensionExclusions

if [ $# -eq 0 ]; then
    # no system input. Sync all systems.
    echo "No system passed in. Uploading all saves. (Ctl-C to abort)"
    echo "5"
    sleep 1
    echo "4"
    sleep 1
    echo "3"
    sleep 1
    echo "2"
    sleep 1
    echo "1"
    sleep 1
    echo "0"
    echo "*** Executing ***"
    for i in "${!SYSTEMS[@]}"; do
        SYSTEM_INDEX="$i"
        SYSTEM="${SYSTEMS[$i]}"
        syncIfValidSystem
    done
else
    syncIfValidSystem
fi

