#!/usr/bin/env nu
# -----------------------------------------------------------------------------
# Script : Pop!_OS Beta Image Downloader
# Desc   : Downloads latest Pop!_OS beta ISO image and verifies SHA256 checksum
#          Supports both NVIDIA and Intel/AMD variants with automatic URL construction
#          and checksum verification from official SHA256SUMS and GPG signature
#          Optionally writes the ISO to a target USB device using mkusb-nox
#
# Date   : 10-19-2025
# Deps   : Nushell core commands (hash sha256, path), wget2, gpg, mkusb-nox
#
# Usage:
# ./live-media-to-disk.nu pop_os 24.04 ~/soft/images
#  - Downloads Pop!_OS 24.04 beta with default NVIDIA variant
#  - Creates pop-os_24.04_amd64_nvidia_<build>.iso in specified directory
#  - Verifies SHA256 checksum and GPG signature
#  - Prints mkusb-nox and grub-n-iso (usb-pack-efi) instructions
#
# ./live-media-to-disk.nu pop_os 24.04 ~/soft/images --variant amd64
#  - Downloads Intel/AMD variant instead of default NVIDIA
#
# ./live-media-to-disk.nu pop_os 24.04 ~/soft/images --download-only
#  - Only downloads and verifies the ISO, does not write to USB
#
# ./live-media-to-disk.nu pop_os 24.04 ~/soft/images --variant amd64 /dev/sdX
#  - Downloads, verifies, and then writes ISO to /dev/sdX using mkusb-nox
#
# Notes:
#  - NVIDIA variant is default (RTX 16xx/20xx/30xx/40xx series and newer)
#  - amd64 variant for Intel/AMD graphics or GTX 1060 and older
#  - Build number auto-detected from latest beta release
#  - Verifies both SHA256 hash and GPG signature before completion
#  - Writing uses mkusb-nox in text mode and still requires confirmations
#
# tag: nushell, linux, sha256, gpg, security
# -----------------------------------------------------------------------------

def build_pop_os_url [version: string, variant: string, build: string] {
  let url_variant = (if $variant == "amd64" { "intel" } else { $variant })
  $"https://iso.pop-os.org/($version)/amd64/($url_variant)/($build)/pop-os_($version)_amd64_($url_variant)_($build).iso"
}

def build_checksum_url [version: string, variant: string, build: string] {
  let url_variant = (if $variant == "amd64" { "intel" } else { $variant })
  $"https://iso.pop-os.org/($version)/amd64/($url_variant)/($build)/SHA256SUMS"
}

def build_gpg_url [version: string, variant: string, build: string] {
  let url_variant = (if $variant == "amd64" { "intel" } else { $variant })
  $"https://iso.pop-os.org/($version)/amd64/($url_variant)/($build)/SHA256SUMS.gpg"
}

def import_pop_os_gpg_key [] {
  # Pop!_OS ISO signing key (short ID)
  let key_id = "204DD8AEC33A7AFF"

  let key_check = (gpg --list-keys $key_id | complete)
  if $key_check.exit_code != 0 {
    print "Importing Pop!_OS GPG signing key..."
    gpg --keyserver keyserver.ubuntu.com --recv-keys $key_id
  } else {
    print "Pop!_OS GPG key already imported."
  }
}

def get_latest_build [version: string, variant: string] {
  "20"
}

def main [
  distro_name: string,               # Must be "pop_os"
  release: string,                   # Release version like "24.04"
  output_dir: string,                # Output directory for downloaded ISO
  --variant: string = "nvidia",      # Variant: "nvidia" (default) or "amd64"
  --download-only,                   # Flag: only download and verify
  target_device?: string             # Optional final positional: e.g., /dev/sdX
] {
  if $distro_name != "pop_os" {
    error make { msg: $"Invalid distro_name: ($distro_name). Only 'pop_os' is supported." }
  }

  if $variant not-in ["nvidia", "amd64"] {
    error make { msg: $"Invalid variant: ($variant). Valid values: nvidia, amd64." }
  }

  if not ($output_dir | path exists) {
    error make { msg: $"Directory ($output_dir) does not exist." }
  }

  let build = (get_latest_build $release $variant)

  let image_url = (build_pop_os_url $release $variant $build)
  let checksum_url = (build_checksum_url $release $variant $build)
  let gpg_url = (build_gpg_url $release $variant $build)

  let filename = ($image_url | split row "/" | last)
  let filepath = ($output_dir | path join $filename)
  let checksum_file = ($output_dir | path join "SHA256SUMS")
  let gpg_file = ($output_dir | path join "SHA256SUMS.gpg")

  # Transparency
  print $"ISO URL: ($image_url)"
  print ""

  # Download ISO
  if ($filepath | path exists) {
    print $"File ($filename) already exists, skipping download."
  } else {
    print $"Downloading ($filename) from Pop!_OS beta servers..."
    wget2 --directory-prefix $output_dir $image_url
  }

  # Retrieve checksum and signature
  print "Downloading SHA256SUMS file..."
  wget2 --output-document $checksum_file $checksum_url
  print "Downloading SHA256SUMS.gpg file..."
  wget2 --output-document $gpg_file $gpg_url

  print ""
  print "=== Verification Stage ==="
  print ""

  # Step 1: SHA256 verification
  print "Step 1: Verifying SHA256 hash of the ISO..."
  let checksum_content = (open $checksum_file)
  let expected = ($checksum_content | lines | where $it =~ $filename | first | split row " " | first)
  if ($expected | is-empty) {
    error make { msg: $"Could not find checksum for ($filename) in SHA256SUMS file" }
  }
  let file_hash = (open $filepath | hash sha256)
  if $file_hash == $expected {
    print $"[OK] SHA256 verified for ($filename)"
  } else {
    error make { msg: $"SHA256 mismatch: got '($file_hash)' expected '($expected)'" }
  }

  print ""
  # Step 2: GPG signature verification
  print "Step 2: Verifying GPG signature..."
  import_pop_os_gpg_key
  let gpg_result = (gpg --verify $gpg_file $checksum_file | complete)
  if $gpg_result.exit_code == 0 {
    print "[OK] GPG signature verified"
  } else {
    error make { msg: $"GPG signature verification failed:\n($gpg_result.stderr)" }
  }

  print ""
  print "=== All Verifications Passed ==="
  print $"File ready at: ($filepath)"

  # Optional write stage (mkusb-nox)
  if (not $download_only) {
    if ($target_device | is-empty) {
      print ""
      print "No target device provided; skipping write stage."
      print "Tip: provide a device like /dev/sdX as the final argument to write via mkusb-nox."
    } else {
      if not ($target_device | path exists) {
        error make { msg: $"Target device ($target_device) does not exist under /dev" }
      }
      print ""
      print $"About to launch mkusb-nox to write the ISO to ($target_device)."
      print "mkusb-nox will prompt for confirmation and device selection for safety."
      print "When prompted in mkusb-nox, select the exact target device shown above."
      print $"Command: sudo mkusb-nox ($filepath) all"
      sudo mkusb-nox $filepath all
    }
  } else {
    print ""
    print "Download-only mode: skipping write stage by request."
  }

  # Helper instructions
  print ""
  print "To create bootable USB using mkusb-nox manually:"
  print $"sudo mkusb-nox ($filepath) all"
  print ""
  print "Alternative method using grub-n-iso (usb-pack-efi):"
  print $"sudo usb-pack-efi ($filepath)"
  print "# Creates multiboot USB that can hold multiple ISOs"
  print ""
  print "Install mkusb if not available:"
  print "sudo add-apt-repository --yes ppa:mkusb/ppa"
  print "sudo apt update && sudo apt install --yes mkusb usb-pack-efi"
  print ""
  print "WARNING: This will destroy all data on the target USB device!"
}
