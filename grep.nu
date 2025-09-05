#!/usr/bin/env nu
# -----------------------------------------------------------------------------
# Script : grep.nu
# Desc   : Find text files recursively in specified directory that contain
#          a specific string pattern. Searches through files matching the
#          given pattern and returns paths of files containing the search term.
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
#  ./grep.nu ~/WS "*.txt" "TODO"
#  ./grep.nu . "*.{md,rst}" "nushell"
#  ./grep.nu /var/log "*.log" "ERROR"
#
# Notes:
#  - not the Unix tool grep, no similarity in syntax at all *
#  - Uses glob patterns for recursive file discovery
#  - Only searches actual files, skips directories and symlinks
#  - Returns relative paths from the search directory for cleaner output
#  - Case-sensitive string matching (use str downcase for case-insensitive)
#
# tag: cross-platform
# -----------------------------------------------------------------------------

def main [
    dir: string          # Directory to search (e.g., ~/WS)
    pattern: string      # File pattern (e.g., "*.txt", "*.{rs,py}")
    search_string: string # String to search for
] {
    # Display search parameters
    print $"haystack: ($dir)/($pattern) needle: ($search_string)"

    # Expand user path and build glob pattern
    let search_path = ($dir | path expand | path join "**" | path join $pattern)
    
    # Find files matching pattern and containing search string
    glob $search_path 
    | where ($it | path type) == "file" 
    | where ($it | open | str contains $search_string)
    | each { |file| 
        # Show relative path for cleaner output
        $file | path relative-to ($dir | path expand)
    }
}
