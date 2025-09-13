#!/usr/bin/env nu
# -----------------------------------------------------------------------------
# Script : Kernel log collector
# Desc   : Create per-kernel dir and capture boot/kernel logs for current boot.
# Date   : 09-12-2025
# Deps   : Nushell core + journalctl (systemd)
#
# Usage:
#   ./bug-tool.nu <category> <slug>
#   ex: ./bug-tool.nu amdgpu memory_error
#
# Notes:
# - linux-only; requires systemd-journald
#     TODO: illumos/solaris for dmesg or /var/adm/**log
# - Creates: ~/bugs/kernel/<X.Y.Z>/<category>/
# - Files:   MM-DD_<slug>_b.log (boot), MM-DD_<slug>.log (kernel)
# - TODO: use numbering on file name when creating logs starting 01_ since there
#     can be multiple logs per day
# -----------------------------------------------------------------------------

def main [
  category: string
  slug: string
] {
  # Validate args (disallow path separators).
  if ($category | str contains '/') or ($slug | str contains '/') {
    print "error: category/slug must not contain '/'"
    exit 2
  }

  # Base dir for kernel bugs.
  let bugs_base = ($env.HOME | path join "bugs" | path join "kernel")

  # Kernel version X.Y.Z from uname kernel-release.
  let kr = (uname | get kernel-release)
  let kv = ($kr | split row '-' | first)

  # Target dir for this kernel/category.
  let kdir = ($bugs_base | path join $kv)
  let cdir = ($kdir | path join $category)

  # Create dir if missing; print tilde-style path.
  if not ($cdir | path exists) {
    mkdir $cdir
    let cdir_disp = ("~/" + ($cdir | path relative-to $env.HOME))
    print $"Initialized: ($cdir_disp)"
  }

  # Today (MM-DD).
  let date_str = (date now | format date "%m-%d")

  # Sanitize slug (spaces -> underscores).
  let safe_slug = ($slug | str replace -a ' ' '_')

  # Output file paths.
  let base = $"($date_str)_($safe_slug)"
  let boot_fp = ($cdir | path join $"($base)_b.log")
  let kern_fp = ($cdir | path join $"($base).log")

  # Boot log (current boot). Color on; no pager.
  let _ = (try {
    with-env {SYSTEMD_COLORS: "1"} {
      journalctl --no-hostname --boot --no-pager
    } | save --force --raw $boot_fp
  } catch { print "error: journalctl boot log failed" })

  # Kernel log (dmesg from current boot). Color on; no pager.
  let _ = (try {
    with-env {SYSTEMD_COLORS: "1"} {
      journalctl --no-hostname --boot --dmesg --no-pager
    } | save --force --raw $kern_fp
  } catch { print "error: journalctl kernel log failed" })

  # Summary.
  print "Logs collected:"
  print $"1. ("~/" + ($boot_fp | path relative-to $env.HOME))"
  print $"2. ("~/" + ($kern_fp | path relative-to $env.HOME))"

  print ""
  ls $cdir
}
