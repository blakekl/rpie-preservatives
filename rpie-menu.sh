#!/usr/bin/env bash

###############################################################################
# Consider moving certain functions out into seperate script file that will be
# shared between this script and the rpie-preservatives script.
#
# pseudo code overview
# Read in the settings file
# Read in all the available systems from the es-systmes.cfg fil.
# Ask user whether they want to upload files or download files
# Ask user to select which systems they want to sync.
# Call the rpie-preservatives script for each system in the list.
# need to retry if there is a failure, up to three times.
# show a progress bar that updates as each systme is complete.
###############################################################################

## sample of dialog window

# dialog --ok-label "Upload" --extra-button --extra-label " Download " --checklist "Select systems to sync" 0 0 0 'nes' 'Nintendo Entertainment System' '' 'snes' 'Super Nintendo Entertainment System' '' 'megadrive' 'Sega Megadrive' ''
