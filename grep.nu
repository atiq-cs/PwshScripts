#!/usr/bin/env nu
# -----------------------------------------------------------------------------
# Script : grep.nu
# Desc   : Recursively find text files under a directory that contain a string.
# Date   : 10-30-2025
# Depends: Nushell core commands (glob, path, open, str)
#
# Usage:
# ./grep.nu <directory> <file_pattern> <search_string> [--max-count <num>]
#  - directory: Path to search (e.g., ~/project_name)
#  - file_pattern: File matching pattern (e.g., "*.txt", "*.{rs,py,js}")
#  - search_string: Text string to search for within files
#  - --max-count: Maximum number of matches to show per file (default: 1)
#  - Displays search parameters before showing results
#  - Shows matching line with 1 line before and 1 line after (3 lines total)
#
# Examples:
#   ./grep.nu ~/WS "*.txt" "TODO"
#   ./grep.nu . "*.{md,rst}" "nushell" --max-count 3
#   ./grep.nu /var/log "*.log" "ERROR" --max-count 5
#
# Notes:
#   - Not GNU grep; syntax differs.
#   - Uses glob recursion ("**") for discovery.
#   - Skips directories and symlinks during globbing.
#   - Shows context: 1 line before and 1 line after each match.
#   - Native to Linux but tested on Windows 11 as well
#
# tag: cross-platform
# -----------------------------------------------------------------------------


def main [
  dir: path
  pattern: string
  needle: string
  --max-count: int = 1  # Maximum number of matches to show per file
  # TODO: add case sensitivity option
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
  print $"haystack: ($dir)/($pattern) needle: ($needle) max-count: ($max_count)"
  print ""


  # Build recursive glob pattern
  mut search_glob = ($root | path join "**" | path join $pattern)


  # Win
  if ($nu.os-info.name == "windows") {
    $search_glob = ($search_glob | str replace -a '\' '/')
  }
  
  # Discover only regular files (no dirs, no symlinks) and search
  let files = (glob $search_glob --no-dir --no-symlink)
  
  $files | each {|p|
    # Read as raw bytes and decode to UTF-8; skip unreadable files
    let content = (try { open --raw $p | decode utf-8 } catch { "" })
    
    if ($content | str length) > 0 {
      # Split content into lines and add line numbers
      let lines_list = ($content | lines | enumerate)
      
      # Find all matching lines
      let matches = ($lines_list | where {|line| $line.item | str contains $needle})
      
      # If there are matches, display them with context (limited by max-count)
      if ($matches | length) > 0 {
        let rel_path = ($p | path relative-to $root)
        print $"(ansi green_bold)($rel_path)(ansi reset)"
        
        # Limit matches to max-count
        $matches | first $max_count | each {|match|
          let line_num = $match.index
          let total_lines = ($lines_list | length)
          
          # Calculate context range (1 before, current, 1 after)
          let start_idx = if $line_num > 0 { $line_num - 1 } else { 0 }
          let end_idx = if $line_num < ($total_lines - 1) { $line_num + 1 } else { $total_lines - 1 }
          
          # Display context lines
          $lines_list 
          | where {|l| $l.index >= $start_idx and $l.index <= $end_idx}
          | each {|l|
              # Mark matching line differently from context lines
              if $l.index == $line_num {
                print $"  (ansi red_bold)($l.index + 1):(ansi reset) ($l.item)"
              } else {
                print $"  (ansi cyan)($l.index + 1)-(ansi reset) ($l.item)"
              }
            }
            | ignore
          
          print ""
        } | ignore
      }
    }
  } | ignore
}
