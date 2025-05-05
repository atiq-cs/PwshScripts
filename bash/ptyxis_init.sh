#!/usr/bin/env bash
# ptyxis init script

# Launch shell with required tabs and init powershell tab

# Misc Settings
# Custom Command on profile:
#  bash /home/atiq/shell/bash/ptyxis_init.sh
#
# Color Palette:
#  Solarized (2nd one) // there are two of them with same name!
#
# Notes:
# Don't use OOP on this script so it's simple enough: literally exitable after
#  last command
#
# ptyxis custom command requires this script to be executable similar to usual
# shell scripts
#  $ chmod u+x ~/shell/ptyxis.sh
#
# Current cmd for run dialog
#  ptyxis --tab-with-profile=e44e646c61be8260ad9df9a568185305

# Refs
# project link: https://gitlab.gnome.org/chergert/ptyxis


ptyxis --tab --title "bash"
ptyxis --tab --title "Sync Scheduler"
ptyxis --tab --title "App Launcher"
pwsh -NoExit -File ~/shell/Init.ps1
