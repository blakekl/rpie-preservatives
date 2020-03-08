#!/usr/bin/env bash
###############################################################################
# This is a script backup all save files when using retropie. It compares the 
# save file names/timestamps when an emulator is launched to when it is closed.
# If there are changes, it compresses the saves and uploads them cloud storage
# using rclone.
#
# Requires rclone to be installed
###############################################################################
SYSTEM=$1
EMULATOR=$2
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
    
    *)
    saveSRMs
    ;;
esac
