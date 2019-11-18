#!/usr/bin/env bash
###############################################################################
# This is a script backup all save files when using retropie. It compares the 
# save file names/timestamps when an emulator is launched to when it is closed.
# If there are changes, it compresses the saves and uploads them cloud storage
# using rclone.
#
# Requires rclone to be installed
###############################################################################
GREEN='\033[0;32m'
RED='\033[0;31m'
PLAIN='\033[0m'
ROMSDir="/home/blake/RetroPie/roms"
TMP="/tmp"
CURRENT="current_rom_saves"
PREVIOUS="previous_rom_saves"
SAVES="${TMP}/rom_saves.tar.gz"

cd $ROMSDir && find -L ./ -name "*.srm" -printf "%f\t%T@\n" | sort > $TMP/$PREVIOUS
