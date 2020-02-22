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
        { # try
            find -L ./ -name '*.srm' -exec tar -c {} + | gzip -n > $SAVES \
            && rclone mkdir $RCLONE_DRIVE \
            && rclone copy -P $SAVES $RCLONE_DRIVE \
            && echo -e "\n${GREEN}***** Saves backed up successfully!! *****${PLAIN}\n"
        } || { # catch
            echo -e "${RED}*****  Error saving backups. Try again later. *****${PLAIN}" \
            echo -e "${RED}*****  Error saving backups. Try again later. *****${PLAIN}" >&2 \
            &&  sleep 2
        }
        echo "cleaning up..." && rm $SAVES $TMP/$CURRENT $TMP/$PREVIOUS &> /dev/null
        echo "Done!"
    fi
}
``
saveGeneric() {
    local savesDirParent=$1
    local saveFile=$2
    local savesDir=$3
    echo "Uploading ${saveFile}..."
    { # try
        cd $savesDirParent \
        && tar -czf "${saveFile}" ./ \
        && rclone mkdir $RCLONE_DRIVE \
        && rclone copy -P "${saveFile}" "${RCLONE_DRIVE}" \
        && echo -e "\n${GREEN}***** Saves backed up successfully! *****${PLAIN}\n"
    } || { # catch 
            echo -e "${RED}*****  Error saving backups. Try again later. *****${PLAIN}" \
            echo -e "${RED}*****  Error saving backups. Try again later. *****${PLAIN}" >&2 \
            &&  sleep 2
    }
}

saveGamecube() {
    local savesDirParent="${HOME}/RetroPie/roms/gc/User/"
    local saveFile="${TMP}/gc_saves.tar.gz"
    local savesDir="GC/"

    echo "Saving gamecube..."
    saveGeneric "${savesDirParent}" "${saveFile}" "${savesDir}"
}

saveWii() {
    local savesDirParent="${HOME}/RetroPie/roms/wii/User/"
    local saveFile="${TMP}/wii_saves.tar.gz"
    local savesDir="Wii/"
    echo "Saving wii..."
    saveGeneric "${savesDirParent}" "${saveFile}" "${savesDir}"
}

savePsp() {
    local savesDirParent="${HOME}/RetroPie/roms/psp/PSP/"
    local saveFile="${TMP}/psp_saves.tar.gz"
    local savesDir="SAVEDATA/"
    echo "Saving psp..."
    saveGeneric "${savesDirParent}" "${saveFile}" "${savesDir}"
}

saveDreamcast() {
    local savesDirParent="${HOME}/RetroPie/.reicast/";
    local saveFile="${TMP}/reicast_saves.tar.gz";
    if [ "$EMULATOR" = "lr-flycast" ] ; then
        savesDirParent="${HOME}/RetroPie/BIOS/dc/";
        saveFile="${TMP}/flycast_saves.tar.gz";
    fi
    local savesDir="./";
    saveGeneric "${savesDirParent}" "${saveFile}" "${savesDir}"
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
