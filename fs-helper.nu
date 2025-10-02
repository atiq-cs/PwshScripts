#!/usr/bin/env nu
# -----------------------------------------------------------------------------
# Script : File System Helper
# Desc   : Currently helps with workspace file creations
#      Create (or verify) today’s workspace text file at ~/ws/T_MM-DD.txt
#      and set group write permissions on both the directory and the file.
#
# Date   : 08-08-2025
# Deps   : Nushell core commands (date, path, mkdir, touch, chmod), pwsh on Win
#
# Usage:
# ./fs-helper.nu
#  - Constructs filename using today’s date (e.g., T_08-08.txt)
#  - Ensures ~/ws exists (creates it if needed) with group write permission
#  - Creates the file if missing
#  - Applies group write permission (g+w) to the file
#
# Notes:
#  - **TODO: pass WS dir via arguments
#  - To be consumed by launch-apps.nu
#  - The date format is MM-DD (e.g., 08-08 for August 8th).
#  - No command-line arguments are required.
#
# -----------------------------------------------------------------------------

# Custom Command: main
# Description: Entry point to create today's WS text file with proper directory and file permissions
# Parameters: none
# Returns: void
def main [] {
  # TODO: add support for creating scripts under ~/shell dir

  # Detect operating system and set appropriate workspace directory
  let $os_name = $nu.os-info.name

  # ws_dir hard coded paths
  #  on Windows use ws dir inside Documents special folder location for now
  #  on Linux use ~/ws
  # case sensitive comparison string: windows not Windows!
  if $os_name == "windows" {
    # let ps_path = ($env.SystemRoot | path join 'System32' 'WindowsPowerShell' 'v1.0')
    let ps_path = ($env.PFilesX64Dir | path join "pwsh")
    
    $env.Home = (with-env {Path: ($env.Path | append $ps_path)} {
      pwsh -NoProfile -Command '[Environment]::GetFolderPath("MyDocuments")'
    })
  }

  let ws_dir = ($env.HOME | path join 'ws')

  # Compute today's MM-DD and target file path
  let today_md = (date now | format date "%m-%d")
  let ws_file  = ($ws_dir | path join $'T_($today_md).txt')

  # Ensure base directory exists
  if not ($ws_dir | path exists) {
    mkdir $ws_dir
  }

  # Create file if it doesn't exist, then ensure proper permissions
  if not ($ws_file | path exists) {
    touch $ws_file
    # TODO: drop chmod after complete transition to Cosmic DE
    # chmod g+w $ws_file
    print $"Created file: ($ws_file)"
  }
}
