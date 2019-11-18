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
    local ROMSDir="RetroPie/roms"
    local CURRENT="current_rom_saves"
    local PREVIOUS="previous_rom_saves"
    local SAVES="${TMP}/srm_saves.tar.gz"

    cd $HOME/$ROMSDir && find -L ./ -name "*.srm" -printf "%f\t%T@\n" | sort > $TMP/$CURRENT
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

saveSRMs
