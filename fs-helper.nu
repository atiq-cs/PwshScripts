#!/usr/bin/env nu
# -----------------------------------------------------------------------------
# Script : File System Helper
# Desc   : Currently helps with workspace file creations
#      Create (or verify) today’s workspace text file at ~/WS/T_MM-DD.txt
#      and set group write permissions on both the directory and the file.
#
# Date   : 08-08-2025
# Deps   : Nushell core commands (date, path, mkdir, touch, chmod)
#
# Usage:
# ./fs-helper.nu
#  - Constructs filename using today’s date (e.g., T_08-08.txt)
#  - Ensures ~/WS exists (creates it if needed) with group write permission
#  - Creates the file if missing
#  - Applies group write permission (g+w) to the file
#
# Notes:
#  - **TODO: pass WS dir via arguments
#  - The date format is MM-DD (e.g., 08-08 for August 8th).
#  - No command-line arguments are required.
#
# -----------------------------------------------------------------------------

# Custom Command: main
# Description: Entry point to create today’s WS text file with proper directory and file permissions
# Parameters: none
# Returns: void
def main [] {
  # TODO: add support for creating scripts under ~/shell dir


  # Compute today's MM-DD and target file path: ~/WS/T_MM-DD.txt
  let today_md = (date now | format date "%m-%d")
  let ws_dir   = ($env.HOME | path join 'ws')
  let ws_file  = ($ws_dir | path join $'T_($today_md).txt')

  # Ensure base directory exists
  if not ($ws_dir | path exists) {
    mkdir $ws_dir
  }

  # Create file if it doesn't exist, then ensure group write permission
  if not ($ws_file | path exists) {
    touch $ws_file
    # TODO: drop chmod after complete transition to Cosmic DE
    chmod g+w $ws_file
    print $"Created file: ($ws_file)"
  }
}
