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
    echo "Saving $SYSTEM save files..."
    rclone sync "$ROMSDir/$SYSTEM" "$RCLONE_DRIVE/$SYSTEM" -P --exclude "*.{state*,xml,txt,chd,DS_Store,oops,0*}" --exclude "media/**" --exclude "Mupen64plus/**"  --exclude "$EXCLUDE"
}

uploadSave() {
    local saveFile="$1"
    { #try
        rclone mkdir "$RCLONE_DRIVE" \
        && rclone copy -P "$saveFile" "$RCLONE_DRIVE" \
        && echo -e "\n${GREEN}***** Saves backed up successfuly! *****${PLAIN}\n"
    } || { #catch
        echo -e "${RED}*****  Error saving backups. Try again later. *****${PLAIN}" \
        echo -e "${RED}*****  Error saving backups. Try again later. *****${PLAIN}" >&2 \
        &&  sleep 2
    }
}

saveFolder() {
    local savesDirParent=$1
    local saveFile=$2
    local savesDir=$3
    echo "Uploading ${saveFile}..."
    cd $savesDirParent \
        && tar -czf "${saveFile}" ./ \
    uploadSave "$saveFile"
}

saveGamecube() {
    local savesDirParent="${HOME}/RetroPie/roms/gc/User/"
    local saveFile="${TMP}/gc_saves.tar.gz"
    local savesDir="GC/"

    echo "Saving gamecube..."
    saveFolder "${savesDirParent}" "${saveFile}" "${savesDir}"
}

saveWii() {
    local savesDirParent="${HOME}/RetroPie/roms/wii/User/"
    local saveFile="${TMP}/wii_saves.tar.gz"
    local savesDir="Wii/"
    echo "Saving wii..."
    saveFolder "${savesDirParent}" "${saveFile}" "${savesDir}"
}

savePsp() {
    local savesDirParent="${HOME}/RetroPie/roms/psp/PSP/"
    local saveFile="${TMP}/psp_saves.tar.gz"
    local savesDir="SAVEDATA/"
    echo "Saving psp..."
    saveFolder "${savesDirParent}" "${saveFile}" "${savesDir}"
}

getSystemsExtensionExclusions

case $SYSTEM in 
    "gc")
    saveGamecube
    ;;

    "wii")
    saveWii
    ;;

    "psp")
    savePsp
    ;;

    *)
    normalSync
    ;;
esac
