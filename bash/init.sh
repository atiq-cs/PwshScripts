#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script : .bashrc-custom-init
# Desc   : Custom bash shell initialization for terminal behavior, history
#          management, editor configuration, and SDK management.
# Dependencies: bash, vim, sdkman (optional)
#
# Features:
#   - Disables terminal flow control (Ctrl+S/Ctrl+Q)
#   - Configures extended history with timestamps
#   - Sets vim as default editor
#   - Initializes SDKMAN for SDK version management
#
# History Settings:
#   - HISTSIZE: 16384 commands in memory (2^14)
#   - HISTFILESIZE: unlimited on disk
#   - HISTTIMEFORMAT: timestamps in 'YYYY-MM-DD HH:MM:SS' format
#   - HISTCONTROL: erase all duplicate commands, ignore space-prefixed commands
#
# Notes:
#   - Backup .bash_history before modifying history variables
#   - histappend prevents history overwrite in multi-session scenarios
#   - cd command changes default directory on shell start
#   - Perp ref: https://www.perplexity.ai/search/pop-os-bash-shell-init-
#               related-HYFBCpIMTTK6aD_NmtQIXQ#1
#
#   following line is added at the end of .bashrc
#     source ~/shell/bash/init.sh
#
# tag: pop-os, bash
# -----------------------------------------------------------------------------

# Disable XON/XOFF flow control (allows Ctrl+S for forward history search)
stty -ixon

# History configuration: 16K in-memory, unlimited on-disk with timestamps
export HISTSIZE=16384
export HISTFILESIZE=
export HISTTIMEFORMAT='%F %T '
# Remove all previous occurrences of duplicate commands; ignore commands starting
#  with space
export HISTCONTROL=erasedups:ignorespace

# Append to history file instead of overwriting (multi-session safety)
shopt -s histappend


### due to above following lines are removed from .bashrc
# append to the history file, don't overwrite it
# shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
# HISTSIZE=1000
# HISTFILESIZE=2000
### end ##


# Set vim as default editor for terminal applications
export EDITOR=vim
export VISUAL=$EDITOR

# Change to custom shell directory on startup, except when shell did not start in $HOME
# This lets tools like `chezmoi cd` keep their intended working directory.
if [ "$PWD" = "$HOME" ]; then
  pushd "$HOME/shell/bash" || exit
fi

# SDKMAN initialization (must remain at end of file)
export SDKMAN_DIR="$HOME/.local/sdkman"
[[ -s "$HOME/.local/sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.local/sdkman/bin/sdkman-init.sh"

# chezmoi
if [ -d "$HOME/.local/bin" ] ; then
    export PATH="$PATH:$HOME/.local/bin"
fi