#!/usr/bin/env nu
# -----------------------------------------------------------------------------
# Script : clean-artifacts.nu
# Desc   : Clean build artifacts in a Node/NestJS project.
# Date   : 10-01-2025
# Depends: Nushell core commands (open, glob, rm, path, str)
#
# Usage:
# ./clean-artifacts.nu <project_dir> [--dry-run]
#  - project_dir: Path to project root (e.g., ~/node/my-service)
#  - --dry-run  : Show what would be removed without deleting
#
# Examples:
#   ./clean-artifacts.nu .
#   ./clean-artifacts.nu ~/ws/nest-app
#   ./clean-artifacts.nu ./service-a --dry-run
#
# Notes:
#  - Removes dist or tsconfig outDir, node_modules, coverage, and *.tsbuildinfo
#  - Detects outDir and tsBuildInfoFile via tsconfig.json/tsconfig.build.json
#  - Uses --optional (-o) instead of deprecated --ignore-errors (-i)
#  - Safe to re-run; missing targets are skipped
#
# tag: node nest typescript cleanup
# -----------------------------------------------------------------------------

def try-outdir [conf_path: path] {
  if ($conf_path | path exists) {
    let cfg = (open $conf_path)
    let has_comp = ($cfg | columns | any {|c| $c == "compilerOptions"})
    if $has_comp {
      let co = ($cfg | get compilerOptions)
      let has_outdir = ($co | columns | any {|c| $c == "outDir"})
      if $has_outdir { $co | get outDir } else { null }
    } else { null }
  } else { null }
}

def try-tsbuildinfo [conf_path: path] {
  if ($conf_path | path exists) {
    let cfg = (open $conf_path)
    let has_comp = ($cfg | columns | any {|c| $c == "compilerOptions"})
    if $has_comp {
      let co = ($cfg | get compilerOptions)
      let has_tsbi = ($co | columns | any {|c| $c == "tsBuildInfoFile"})
      if $has_tsbi { $co | get tsBuildInfoFile } else { null }
    } else { null }
  } else { null }
}

def within-root [root: path, p: path] {
  let abs = ($p | path expand)
  let root_abs = ($root | path expand)
  let rel = (echo $abs | path relative-to $root_abs | default null)
  if ($rel == null) { false } else { (not ($rel | str starts-with "..")) }
}

def remove-path [target: path, --dry-run] {
  if (not ($target | path exists)) { return }
  let ttype = (echo $target | path type | default "file")
  if $dry_run {
    print $"[dry-run] would remove: ($target)"
  } else {
    if ($ttype == "dir") { rm -r -f $target } else { rm -f $target }
    print $"removed: ($target)"
  }
}

def main [
  project_dir: path,  # target project root
  --dry-run           # list planned deletions only
] {
  let root = ($project_dir | path expand)
  if (not ($root | path exists)) {
    error make { msg: $"project dir not found: ($root)" }
  }

  # Baseline directories/files
  mut dirs = [
    # ($root | path join "dist"),  # commented: rely on tsconfig outDir discovery
    ($root | path join "node_modules"),
    ($root | path join "coverage"),
  ]

  # Discover outDir from common tsconfig files
  let tsconfigs = [
    ($root | path join "tsconfig.json"),
    ($root | path join "tsconfig.build.json"),
  ]

  let discovered_outdirs = ($tsconfigs
    | each {|f| try-outdir $f }
    | where {|x| $x != null}
    | uniq
    | each {|od|
        let p = (if (not ($od | path exists)) { $root | path join $od } else { $od })
        $p | path expand  # ← Normalize to remove ./ and canonicalize
      })

  # Add discovered outDirs (avoid dupes)
  for od in $discovered_outdirs {
    let od_norm = ($od | path expand)
    let has_match = ($dirs | any {|d| ($d | path expand) == $od_norm })
    if (not $has_match) {
      $dirs ++= [$od_norm]  # ← Store the normalized path
    }
  }

  # Collect tsbuildinfo files:
  mut tsbuildinfo = ($tsconfigs
    | each {|f| try-tsbuildinfo $f }
    | where {|x| $x != null})

  let here = $env.PWD
  cd $root
  let globbed = (glob "**/*.tsbuildinfo" | each {|g| $root | path join $g })
  cd $here

  let combined = ($tsbuildinfo | append $globbed | uniq)
  $tsbuildinfo = $combined

  # Guard: only remove paths inside project root
  let safe_dirs = ($dirs | where {|d| within-root $root $d } | uniq)
  let safe_tsbi = ($tsbuildinfo | where {|f| within-root $root $f } | uniq)

  print $"Cleaning project: ($root)"
  print "Targets:"
  for d in $safe_dirs { print $"- dir : ($d)" }
  for f in $safe_tsbi { print $"- file: ($f)" }

  # Remove
  for d in $safe_dirs { remove-path $d --dry-run=$dry_run }
  for f in $safe_tsbi { remove-path $f --dry-run=$dry_run }
}
