#!/usr/bin/env nu
# -----------------------------------------------------------------------------
# Script : init.nu
# Desc   : Nushell configuration initialization script that sets up custom
#          prompt with path abbreviation, editor preferences, and workspace
#          navigation. Provides cross-platform shell home directory handling.
# Date   : 09-05-2025
# Dependencies: Nushell core commands, codium (text editor), std/dirs module
#
# Usage:
#   Source'd from config.nu during instantiation of NuShell
#
# Notes:
#   - Detects OS and sets appropriate base paths (Windows: D:\Code, Unix: $HOME)
#   - Custom prompt shows ~* for shell directory, ~ for home directory
#   - Disables default banner and shows custom Matrix-themed welcome
#   - Requires codium editor to be installed and in PATH
#  on Windows
#   - powershell is removed from env.PATH
#
# tag: cross-platform
# -----------------------------------------------------------------------------

# Detect OS and set $ShellHome accordingly
let $ShellHome = (if ($nu.os-info.name == "windows") { "D:\\Code" } else { $env.Home }) | path join "shell"

# Custom prompt with path abbreviation
$env.PROMPT_COMMAND = {
  let user = (whoami)
  let host = (hostname)
  let pwd = (pwd)
  
  # Path abbreviation logic: shell dir gets ~*, home dir gets ~
  # `homeDir` is declared here so that it is not exposed for the whole session
  #  since we are in config.nu
  let homeDir = if ($nu.os-info.name == "windows") { "D:\\Code" } else { $env.Home }
  let path = if ($pwd | str starts-with $ShellHome) { # gotta be first line
    $pwd | str replace $ShellHome "~*"     # since $home will always match
  } else if ($pwd | str starts-with $homeDir) {   # otherwise
    $pwd | str replace $homeDir "~"    # As a result, the other match will get skipped
  } else {
    $pwd
  }

  $"($user)@($host) (ansi cyan)($path)(ansi reset)"
}

$env.PROMPT_INDICATOR = "$ "

# Set editor to VS Codium
$env.config.buffer_editor = "codium"
# Remove welcome msg / banner
$env.config.show_banner = false

# Load additional modules
use std/dirs

# Navigate to shell home
cd $ShellHome

# Show welcome
print $"Welcome to (ansi green)Matrix Terminal(ansi reset)"
print $"NuShell ($env.NU_VERSION) on ($nu.os-info.name) ($nu.os-info.kernel_version)"

# Seems to have some sort support of persistent env.Path inside custom commands
source ./init-app.nu

# Porting tasks TODO
# - InitConsoleUI, and probably

if ($nu.os-info.name == "windows") {
  source ./win/init.nu
} else {
  # ssh initialization
  source ./ssh-init.nu
}

fs-helper.nu

print ""