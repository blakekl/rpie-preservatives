#!/usr/bin/env bash
###############################################################################
# This is a script backup all save files when using retropie. It compares the 
# save file names/timestamps when an emulator is launched to when it is closed.
# If there are changes, it compresses the saves and uploads them cloud storage
# using rclone.
#
# Requires rclone to be installed
# 
# In the future, I plan on moving to single file syncing. This is a sync 
# command that will sync the entire directory, excluding metadata, scraped
# files, and save states.
#
# `rclone sync ./ retropie-backup:retropie-backup/saturn --dry-run --exclude '*.{chd,m3u,xml,state}' --exclude 'media/**'`
# I could smartly build the exclusion filelist using the es_system.cfg file.
#
# `xmlstarlet sel -t -m "/systemList/system" -v "name" -o ", " -v "extension" -n /etc/emulationstation/es_systems.cfg`
#
# This will print each system on a line followed by a line of space separated 
# extensions the system uses. Then I just need to add '.state' and '.xml' to it
# to exclude save states and gamelist.xml files.
# 
# `xmlstarlet sel -t -m "/systemList/system"  -v "extension" -n /etc/emulationstation/es_systems.cfg | sed "s/.//" | sed "s/ ./,/g" | sed "s/^/.{/" | sed "s/$/}/"`
# prints a list string of the exclusion string for all the identified
# extensions for a system from the es_systems.cfg file.
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

saveSRMs() {
    local ROMSDir="${HOME}/RetroPie/roms"
    local CURRENT="current_rom_saves"
    local PREVIOUS="previous_rom_saves"
    local SAVES="${TMP}/srm_saves.tar.gz"

    echo "Saving srms..."
    cd $ROMSDir && find -L ./ -name "*.srm" -printf "%f\t%T@\n" | sort > $TMP/$CURRENT
    diff -q $TMP/$PREVIOUS $TMP/$CURRENT &> /dev/null
    isChanged=$?

    if [[ $isChanged == 0 ]]
    then
        echo -e "${GREEN}No differences. Skipping backup.${PLAIN}"
    else
        echo -e "${RED}Save files are different. Backing up...\n${PLAIN}"
        find -L ./ -name '*.srm' -exec tar -c {} + | gzip -n > $SAVES
        uploadSave "$SAVES"
        echo "cleaning up..." && rm $SAVES $TMP/$CURRENT $TMP/$PREVIOUS &> /dev/null
        echo "Done!"
    fi
}

saveFilesMatching() {
    local savesDirParent=$1
    local saveFile="$TMP/$2"
    local savePattern=$3
    echo "Uploading $2..."
    cd "$savesDirParent" \
    && find -L . -regextype 'posix-extended' -regex "$savePattern" -exec tar -czf "$saveFile" {} +
    uploadSave "$saveFile"
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

saveDreamcast() {
    local savesDirParent="${HOME}/RetroPie/roms/dreamcast/";
    local saveFile="flycast_saves.tar.gz";
    saveFilesMatching "$savesDirParent" "$saveFile" ".*\.(A|B|C|D)(1|2)\.bin"
}

saveNds() {
    local savesDirParent="${HOME}/RetroPie/roms/nds/";
    local saveFile="nds_saves.tar.gz";
    saveFilesMatching "$savesDirParent" "$saveFile" ".*\.dsv"
}

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

    "dreamcast")
    saveDreamcast
    ;;

    "nds")
    saveNds
    ;;

    *)
    saveSRMs
    ;;
esac
