#!/usr/bin/env bash
###############################################################################
# Scans the es_systems_path file to find the extensions of  rom files. This
# data is then used to build an exclusion list, so we don't end up syncing
# large rom files by mistake.
###############################################################################
getSystemsExtensionExclusions() {
    mapfile -t < <( \
        grep -P "<name>[^<]*<" ${es_systems_path} \
            | sed 's/[ ]*<[\/]*name>//g' )
    SYSTEMS=("${MAPFILE[@]}")

    mapfile -t < <( \
        grep -P "<extension>[^<]*<" ${es_systems_path} \
            | sed 's/[ ]*<[\/]*extension>//g' \
            | sed "s/[ ]*\./,/g" \
            | sed "s/^,/*.{/" \
            | sed "s/$/}/" )
    local extensions=("${MAPFILE[@]}")

    for i in "${!SYSTEMS[@]}"; do
	local system="${SYSTEMS[$i]}"
        EXTENSIONS_BY_SYSTEM[$system]="${extensions[$i]}"
    done
}

###############################################################################
# takes an array of systems to sync. 
###############################################################################
syncSystems() {
    for system in "$@"; do
        syncIfValidSystem "${system}"
    done
}

###############################################################################
# uses rclone to sync the remote directory with the local file system for the
# system we are running. 
###############################################################################
syncSystem() {
    local system=$1
    local system_path="${roms_path}/${system}"
    local exclude="${EXTENSIONS_BY_SYSTEM[$system]}"
    local source=""
    local dest=""
    local dryrun=""
    local states="state*,oops,0*,"
    local patch_files="ips,ups,bps,"

    if [ "$COMMAND" = "download" ]; then
        source="${rclone_drive}/${system}"
        dest="${system_path}"
    else
        source="${system_path}"
        dest="${rclone_drive}/${system}"
    fi

    if [ "$sync_save_states" = "$TRUE" ]; then
        states=""
    fi

    if [ "$sync_patch_files" = "$TRUE" ]; then
        patch_files=""
    fi

    if [ "$DEBUG" = "$TRUE" ]; then
        dryrun="--dry-run"
    fi

    echo ""
    echo "Syncing $system save files..."
    echo ""
    rclone \
	sync -v -L "${source}" "${dest}" -P \
        $dryrun \
        --filter "- *.{${states}${patch_files}xml,txt,chd,DS_Store}" \
        --filter "- media/**" \
        --filter "- images/" \
        --filter "- videos/" \
	--filter "+ mame*/nvram/*.nv" \
	--filter "+ mame*/nvram/*/nvram" \
	--filter "+ mame*/hi/**" \
        --filter "- mame*/**" \
	--filter "- fbneo*/**" \
        --filter "- duckstation_cache/**"
        --filter "- **sd.raw" \
        --filter "- **.m3u" \
        --filter "- Mupen64plus/**" \
        --filter "- User/Cache**" \
        --filter "- User/Config**" \
        --filter "- User/Logs**" \
        --filter "- PSP/SYSTEM/**" \
        --filter "- $exclude" 
}

###############################################################################
# Returns with "true" if the system is valid for syncing. Returns with "false" 
# otherwise.
###############################################################################
isValidSystem() {
    local exit_code="true"
    case $1 in
        retropie) exit_code="false";;
        kodi) exit_code="false";;
        pc) exit_code="false";;
        ports) exit_code="false";;
    esac
    echo "$exit_code"
}

###############################################################################
# Checks whether a system is valid to sync or not. If valid, syncs the system.
# Skips syncing on systems that don't support it (mostly mame). This function
# is not complete, as I don't have roms for all the possible systems in ES vs 
# retroarch, and I don't plan on emulating them all either.
###############################################################################
syncIfValidSystem() {
    local system=$1
    local isValid=$(isValidSystem "${system}")
    if [ $isValid = "true" ]; then
        syncSystem ${system}
    else
        echo "skipping ${system} directory"
    fi
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
# cancelling the script and provides a dela to allow cancelling.
###############################################################################
printAllSystemWarning() {
    echo ""
    echo "!!!!!    WARNING   !!!!!"
    echo ""
    echo "No system passed in. All saves will be ${COMMAND}ed. (Ctl-C to abort)"
    echo ""
    printCountdown
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
    local delay=10
    while [ $delay -ge 0 ]
    do
        printf "\rsyncing in $delay "
        sleep 1
        ((delay--))
    done
    printf "\r*** Syncing ***"
}


###############################################################################
# prints an error messages for missing files/folders from config file.
###############################################################################
printSettingNotFoundError(){
    echo "   ${1} not found. Ensure the value for ${1} in rpie-settings.cfg is correct."
}

###############################################################################
# prints an error message for bad boolean values from config file.
###############################################################################
printSettingBooleanError() {
    echo "   ${1} has a bad value. Valid values are '${TRUE}' and '${FALSE}'. Ensure ${1} in rpie-settings.cfg is correct."
}

###############################################################################
# Verifies the values in the settings file to ensure the values are valid.
# Prints out any errors it finds.
###############################################################################
verifySettings() {
    echo "verifying settings."
    local result=0

    if ! [ -d "${roms_path}" ]; then 
        printSettingNotFoundError "roms_path"
        result=1
    fi

    if ! [ -f "${es_systems_path}" ]; then
        printSettingNotFoundError "es_systems_path"
        result=1
    fi

    sync_save_states=`echo "$sync_save_states" | awk '{print tolower($0)}'`
    if [[ "$sync_save_states" != "$TRUE" ]] && [[ "$sync_save_states" != "$FALSE" ]]; then
        printSettingBooleanError "sync_save_states"
        result=1
    fi

    sync_patch_files=`echo "$sync_patch_files" | awk '{print tolower($0)}'`
    if [[ "$sync_patch_files" != "$TRUE" ]] && [[ "$sync_patch_files" != "$FALSE" ]]; then
        printSettingBooleanError "sync_patch_files"
        result=1
    fi

    if ! [[ "$rclone_drive" =~ ^.+:.+$ ]]; then
        echo "   rclone_drive does not appear to be valid. Must be in the format remote:DESTINATION. Correct value in rpie-settings.cfg"
        result=1
    fi

    return $result
}


###############################################################################
# prints the missing config file message.
###############################################################################
printMissingConfig() {
    local workingDir=`pwd`
    echo "rpie-settings.cfg could not be found. Ensure rpie-settings.cfg exist in ${workingDir}"
    exit 1
}

###############################################################################
# Shows a menu to select systems to sync and whether to upload or download.
###############################################################################
showDialog() {
    local upload="0"
    local download="3"

    local dialog_options=""
    for i in "${!SYSTEMS[@]}"; do
        local system="${SYSTEMS[$i]}"
        local isValid=$(isValidSystem ${system})
        if [ $isValid = "true" ]; then
            dialog_options="${dialog_options} $system $i off"
        fi
    done
    exec 3>&1;
    selections=$( dialog \
        --keep-tite \
        --backtitle "Rpie-Preservatives" \
        --ok-label "Upload" \
        --extra-button --extra-label " Download " \
        --checklist "Select systems to sync" 0 0 0 \
        ${dialog_options} \
        2>&1 1>&3);
    exit_code=$?
    2>&1 1>&-;
    if [ $exit_code -eq $upload ]; then
        COMMAND="upload"
    elif [ $exit_code -eq $download ]; then
        COMMAND="download"
    else
        exit 0
    fi

    local systems=( $selections )
    syncSystems ${systems[@]}
}

COMMAND=$1
SYSTEM=$2
EMULATOR=$3
ROM_PATH=$4
RUN_COMMAND=$5

UPLOAD="upload"
DOWNLAD="download"

GREEN="\e[92m"
RED="\e[91m"
PLAIN="\e[39m"
TRUE="true"
FALSE="false"

DEBUG="$FALSE"

declare -A EXTENSIONS_BY_SYSTEM

if test -a "/opt/retropie/configs/all/rpie-settings.cfg"; then
    . /opt/retropie/configs/all/rpie-settings.cfg
    verifySettings
    if [ $? -eq 0 ]; then
        echo "Settings valid!"
        getSystemsExtensionExclusions

        if [ $# -eq 0 ]; then
            showDialog
        elif [ $# -eq 1 ]; then
            if [ "$COMMAND" = "$UPLOAD" ] || [ "$COMMAND" = "$DOWNLOAD" ]; then
                printAllSystemWarning
                syncSystems "${SYSTEMS[@]}"
            else
                printUsage
            fi
        else
            syncIfValidSystem "$SYSTEM"
        fi
    else
        exit 1
    fi
else
    printMissingConfig
fi

