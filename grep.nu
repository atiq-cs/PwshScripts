#!/usr/bin/env nu
# -----------------------------------------------------------------------------
# Script : grep.nu
# Desc   : Recursively find text files under a directory that contain a string.
# Date   : 09-05-2025
# Depends: Nushell core commands (glob, path, open, str)
#
# Usage:
# ./grep.nu <directory> <file_pattern> <search_string>
#  - directory: Path to search (e.g., ~/project_name)
#  - file_pattern: File matching pattern (e.g., "*.txt", "*.{rs,py,js}")
#  - search_string: Text string to search for within files
#  - Displays search parameters before showing results
#
# Examples:
#   ./grep.nu ~/WS "*.txt" "TODO"
#   ./grep.nu . "*.{md,rst}" "nushell" -i
#   ./grep.nu /var/log "*.log" "ERROR"
#
# Notes:
#   - Not GNU grep; syntax differs.
#   - Uses glob recursion ("**") for discovery.
#   - Skips directories and symlinks during globbing.
#   - Returns relative paths from the search directory.
#   - Native to Linux but tested on Windows 11 as well
#
# tag: cross-platform
# -----------------------------------------------------------------------------

def main [
  dir: path
  pattern: string
  needle: string
  # TODO: add case sensitivity option, ref, GPT-5 thinking model
] {
  # Validate directory exists before proceeding
  let root = ($dir | path expand)
  if not ($root | path exists) {
    print $"Error: Directory does not exist: ($dir)"
    exit 1
  }
  
  if ($root | path type) != "dir" {
    print $"Error: Path is not a directory: ($dir)"
    exit 1
  }

  # Display search parameters
  print $"haystack: ($dir)/($pattern) needle: ($needle)"

  # Build recursive glob pattern
  mut search_glob = ($root | path join "**" | path join $pattern)

  # Win
  if ($nu.os-info.name == "windows") {
    $search_glob = ($search_glob | str replace -a '\' '/')
  }
  # to debug on Windows
  # print $"DEBUG: Using glob pattern: ($search_glob)"
  
  # Discover only regular files (no dirs, no symlinks) and search
  glob $search_glob --no-dir --no-symlink
  | where {|p|
      # Read as raw bytes and decode to UTF-8; skip unreadable files
      let content = (try { open --raw $p | decode utf-8 } catch { "" })
      $content | str contains $needle
    }
  | each {|p| $p | path relative-to $root }
}
