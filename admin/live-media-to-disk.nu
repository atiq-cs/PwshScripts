#!/usr/bin/env nu
# -----------------------------------------------------------------------------
# Script : Live Media Writer
# Desc   : Download, verify, and write bootable images for OpenIndiana,
#          OmniOS and, Pop!_OS
# Date   : 10-21-2025
# Deps   : nushell, wget2, gpg, dd, mkusb-nox
#
# Usage:
#   ./live-media-to-disk.nu openindiana beta --gui ~/images /dev/sdX
#   ./live-media-to-disk.nu omnios lts      ~/images /dev/sdX
#   ./live-media-to-disk.nu omnios bloody   ~/images /dev/sdX
#   ./live-media-to-disk.nu pop_os stable   ~/images /dev/sdX
#     [--variant nvidia|amd64]
#   ./live-media-to-disk.nu pop_os beta     ~/images /dev/sdX
#     [--variant nvidia|amd64]
#
# Notes:
#   - Channels:OI {stable, beta→test}; OmniOS {lts, stable, bloody};
#     Pop!_OS {stable=22.04, beta=24.04}.
#   - Verifies SHA-256 for all; also verifies GPG for Pop!_OS before write.
#   - Writer defaults: dd for illumos; mkusb for Pop!_OS; exact dd command is
#     printed before execution.
#   - dd block size auto-selects by image size: > 1 GiB → bs=4M, else bs=1M,
#     per GNU dd guidance on block sizes.
# -----------------------------------------------------------------------------

# Channel definitions - single source of truth
const CHANNELS = {
  pop_os: {
    stable: { version: "22.04", build: "58", path: "22.04" }
    beta: { version: "24.04", build: "20", path: "24.04" }
  }
  openindiana: {
    stable: { version: "20250606", path: "20250606" }
    beta: { version: "20251011", path: "test" }
  }
  omnios: {
    lts: { version: "r151054r", path: "stable" }
    stable: { version: "r151054", path: "stable" }
    bloody: { version: "20250902", path: "bloody" }
  }
}

# Build image URL from channel config
def build-url [distro: string, channel_info: record, variant: string, gui: bool] {
  match $distro {
    "pop_os" => {
      let url_var = (if $variant == "amd64" { "intel" } else { $variant })
      let v = $channel_info.version
      let b = $channel_info.build
      $"https://iso.pop-os.org/($v)/amd64/($url_var)/($b)/pop-os_($v)_amd64_($url_var)_($b).iso"
    }
    "openindiana" => {
      let ed = (if $gui { "gui" } else { "text" })
      let v = $channel_info.version
      if $channel_info.path == "test" {
        $"https://dlc.openindiana.org/isos/hipster/test/OI-hipster-($ed)-($v).usb"
      } else {
        $"https://dlc.openindiana.org/isos/hipster/($v)/OI-hipster-($ed)-($v).usb"
      }
    }
    "omnios" => {
      let v = $channel_info.version
      let p = $channel_info.path
      if $p == "bloody" {
        $"https://downloads.omnios.org/media/bloody/omnios-bloody-($v).usb-dd"
      } else {
        $"https://downloads.omnios.org/media/stable/omnios-($v).usb-dd"
      }
    }
  }
}

# Build checksum URL
def build-checksum-url [distro: string, channel_info: record, variant: string, image_url: string] {
  match $distro {
    "pop_os" => {
      let url_var = (if $variant == "amd64" { "intel" } else { $variant })
      let v = $channel_info.version
      let b = $channel_info.build
      $"https://iso.pop-os.org/($v)/amd64/($url_var)/($b)/SHA256SUMS"
    }
    "openindiana" => $"($image_url).sha256sum"
    "omnios" => $"($image_url).sha256"
  }
}

# Download file if not present
def download-file [url: string, output_path: string] {
  let filename = ($url | split row "/" | last)
  if ($output_path | path exists) {
    print $"File ($filename) already exists, skipping download."
  } else {
    print $"Downloading ($filename)..."
    wget2 --directory-prefix ($output_path | path dirname) $url
  }
}

# Verify SHA-256
def verify-checksum [filepath: string, checksum_content: string, distro: string, filename: string] {
  print "Verifying SHA-256 checksum..."
  let file_hash = (open $filepath | hash sha256)
  let expected = (
    if $distro == "pop_os" {
      $checksum_content | lines | where $it =~ $filename | first | split row " " | first
    } else {
      $checksum_content | lines | first | split row " " | first
    }
  )
  
  if ($expected | is-empty) {
    error make { msg: $"Could not find checksum for ($filename)" }
  }
  
  if $file_hash == $expected {
    print $"[OK] SHA-256 verified for ($filename)"
  } else {
    error make { msg: $"SHA-256 mismatch: got '($file_hash)' expected '($expected)'" }
  }
}

# Verify GPG (Pop!_OS only)
def verify-gpg [checksum_file: string, gpg_file: string] {
  print "Verifying GPG signature..."
  let key_id = "204DD8AEC33A7AFF"
  let key_check = (gpg --list-keys $key_id | complete)
  
  if $key_check.exit_code != 0 {
    print "Importing Pop!_OS GPG signing key..."
    gpg --keyserver keyserver.ubuntu.com --recv-keys $key_id
  }
  
  let gpg_result = (gpg --verify $gpg_file $checksum_file | complete)
  if $gpg_result.exit_code != 0 {
    error make { msg: $"GPG verification failed:\n($gpg_result.stderr)" }
  }
  print "[OK] GPG signature verified"
}

# Write image to device
def write-image [filepath: string, device: string, tool: string, distro: string] {
  if not ($device | path exists) {
    error make { msg: $"Device ($device) does not exist" }
  }
  
  print $"\nAbout to write to ($device) using ($tool)..."
  print "This will PERMANENTLY DESTROY all data on the target device!"
  print "\nVerify device with: lsblk\n"
  
  let confirm = (input "Type 'yes' to continue: ")
  if $confirm != "yes" {
    print "\nCancelled."
    return
  }
  
  match $tool {
    "dd" => {
      # Compute a size-aware block size:
      # - Use 4 MiB for images > 1 GiB
      # - Otherwise use 1 MiB
      let file_size = (ls $filepath | first | get size)
      let bs = (if $file_size > 1GiB { "4M" } else { "1M" })

      # Build, show, and execute the exact dd command
      let dd_cmd = $"sudo dd bs=($bs) if=($filepath) of=($device) status=progress conv=fsync"
      print $"\nExecuting: ($dd_cmd)\n"
      bash -c $dd_cmd

      print "\n[OK] Write complete. Syncing filesystem..."
      sync
      print "[OK] Device ready to boot."
    }
    "mkusb" => {
      print "\nLaunching mkusb-nox..."
      sudo mkusb-nox $filepath all
    }
  }
}

# Main
def main [
  distro_name: string          # pop_os, openindiana/oi, omnios
  channel: string              # stable/beta (Pop/OI), lts/stable/bloody (OmniOS)
  output_dir: string           # download directory
  target_device?: string       # optional /dev/sdX
  --variant: string = "nvidia" # Pop!_OS: nvidia or amd64
  --gui                        # OpenIndiana GUI edition
  --download-only              # skip write stage
  --writer-tool: string = ""   # dd or mkusb
] {
  # Normalize distro
  let distro = (
    match ($distro_name | str downcase) {
      "pop_os" => "pop_os"
      "openindiana" | "oi" => "openindiana"
      "omnios" => "omnios"
      _ => { error make { msg: $"Invalid distro: ($distro_name). Use: pop_os, openindiana, oi, omnios" } }
    }
  )
  
  if not ($output_dir | path exists) {
    error make { msg: $"Directory ($output_dir) does not exist" }
  }
  
  # Get channel config
  let channel_lower = ($channel | str downcase)
  let channel_info = ($CHANNELS | get $distro | get --optional $channel_lower)
  
  if ($channel_info | is-empty) {
    let valid = ($CHANNELS | get $distro | columns | str join ", ")
    error make { msg: $"Invalid channel '($channel)' for ($distro). Valid: ($valid)" }
  }
  
  # Default writer: dd for illumos, mkusb for Pop!_OS
  let tool = (if $writer_tool == "" { if $distro == "pop_os" { "mkusb" } else { "dd" } } else { $writer_tool })
  if $tool not-in ["dd", "mkusb"] {
    error make { msg: $"Invalid writer-tool: ($tool). Valid: dd, mkusb" }
  }
  
  if $distro == "pop_os" and $variant not-in ["nvidia", "amd64"] {
    error make { msg: $"Invalid variant: ($variant). Valid: nvidia, amd64" }
  }
  
  # Build URLs
  let image_url = (build-url $distro $channel_info $variant $gui)
  let checksum_url = (build-checksum-url $distro $channel_info $variant $image_url)
  
  let filename = ($image_url | split row "/" | last)
  let filepath = ($output_dir | path join $filename)
  
  print $"Image URL: ($image_url)\n"
  
  # Download
  download-file $image_url $filepath
  
  # Get checksum
  let checksum_content = (
    if $distro in ["openindiana", "omnios"] {
      http get --raw $checksum_url | decode utf-8
    } else {
      let csum_file = ($output_dir | path join "SHA256SUMS")
      download-file $checksum_url $csum_file
      open $csum_file
    }
  )
  
  print "\n=== Verification Stage ===\n"
  verify-checksum $filepath $checksum_content $distro $filename
  
  # GPG for Pop!_OS
  if $distro == "pop_os" {
    let url_var = (if $variant == "amd64" { "intel" } else { $variant })
    let v = $channel_info.version
    let b = $channel_info.build
    let gpg_url = $"https://iso.pop-os.org/($v)/amd64/($url_var)/($b)/SHA256SUMS.gpg"
    let csum_file = ($output_dir | path join "SHA256SUMS")
    let gpg_file = ($output_dir | path join "SHA256SUMS.gpg")
    
    print ""
    download-file $gpg_url $gpg_file
    print ""
    verify-gpg $csum_file $gpg_file
  }
  
  print "\n=== All Verifications Passed ==="
  print $"File ready: ($filepath)"

  # Write stage
  if (not $download_only) and (not ($target_device | is-empty)) {
    write-image $filepath $target_device $tool $distro
  } else if $download_only {
    print "\nDownload-only mode: skipping write stage."
  } else {
    print "\nNo device specified; skipping write stage."
  }
}
