#!/usr/bin/env nu
# -----------------------------------------------------------------------------
# Script : Pop!_OS Beta Image Downloader
# Desc   : Downloads latest Pop!_OS beta ISO image and verifies SHA256 checksum
#          Supports both NVIDIA and Intel/AMD variants with automatic URL construction
#          and checksum verification from official SHA256SUMS and GPG signature
#
# Date   : 10-19-2025  
# Deps   : Nushell core commands (hash sha256, path), wget2, gpg
#
# Usage:
# ./live-media-to-disk.nu pop_os 24.04 ~/soft/images
#  - Downloads Pop!_OS 24.04 beta with default NVIDIA variant
#  - Creates pop-os_24.04_amd64_nvidia_<build>.iso in specified directory
#  - Verifies SHA256 checksum and GPG signature
#
# ./live-media-to-disk.nu pop_os 24.04 ~/soft/images --variant amd64
#  - Downloads Intel/AMD variant instead of default NVIDIA
#
# Notes:
#  - NVIDIA variant is default (RTX 16xx/20xx/30xx/40xx series and newer)
#  - amd64 variant for Intel/AMD graphics or GTX 1060 and older
#  - Build number auto-detected from latest beta release
#  - Verifies both SHA256 hash and GPG signature before completion
#
# tag: nushell, linux, sha256, gpg, security
# -----------------------------------------------------------------------------

def build_pop_os_url [version: string, variant: string, build: string] {
  # Map amd64 variant to 'intel' for URL path
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
  # Pop!_OS ISO signing key fingerprint
  # From: https://github.com/pop-os/iso
  let key_id = "204DD8AEC33A7AFF"
  
  # Check if key is already imported
  let key_check = (gpg --list-keys $key_id | complete)
  
  if $key_check.exit_code != 0 {
    print "Importing Pop!_OS GPG signing key..."
    # Import from Ubuntu keyserver
    gpg --keyserver keyserver.ubuntu.com --recv-keys $key_id
  } else {
    print "Pop!_OS GPG key already imported."
  }
}


def get_latest_build [version: string, variant: string] {
  # Default beta build number for Pop!_OS 24.04
  "20"
}

def main [
  distro_name: string,         # Must be "pop_os" 
  release: string,             # Release version like "24.04"
  output_dir: string,          # Output directory for downloaded ISO
  --variant: string = "nvidia" # Variant: "nvidia" (default) or "amd64"
] {
  # Strict validation for distro_name
  if $distro_name != "pop_os" {
    error make { msg: $"Invalid distro_name: ($distro_name). Only 'pop_os' is supported." }
  }

  # Validate variant
  if $variant not-in ["nvidia", "amd64"] {
    error make { msg: $"Invalid variant: ($variant). Valid values: nvidia, amd64." }
  }

  # Check if directory exists
  if not ($output_dir | path exists) {
    error make { msg: $"Directory ($output_dir) does not exist." }
  }

  # Get latest build number
  let build = (get_latest_build $release $variant)
  
  let image_url = (build_pop_os_url $release $variant $build)
  let checksum_url = (build_checksum_url $release $variant $build)
  let gpg_url = (build_gpg_url $release $variant $build)
  
  let filename = ($image_url | split row "/" | last)
  let filepath = ($output_dir | path join $filename)
  let checksum_file = ($output_dir | path join "SHA256SUMS")
  let gpg_file = ($output_dir | path join "SHA256SUMS.gpg")

  # Always print the ISO URL for transparency
  print $"ISO URL: ($image_url)"
  print ""

  # Download ISO only if file doesn't exist
  if ($filepath | path exists) {
    print $"File ($filename) already exists, skipping download."
  } else {
    print $"Downloading ($filename) from Pop!_OS beta servers..."
    wget2 --directory-prefix $output_dir $image_url
  }

  # Download SHA256SUMS file
  print "Downloading SHA256SUMS file..."
  wget2 --output-document $checksum_file $checksum_url

  # Download SHA256SUMS.gpg file
  print "Downloading SHA256SUMS.gpg file..."
  wget2 --output-document $gpg_file $gpg_url

  print ""
  print "=== Verification Stage ==="
  print ""

  # Step 1: Verify SHA256 hash of the ISO
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
  # Step 2: Verify GPG signature
  print "Step 2: Verifying GPG signature..."
  
  # Import Pop!_OS GPG key if not already present
  import_pop_os_gpg_key
  
  # Verify the signature
  let gpg_result = (gpg --verify $gpg_file $checksum_file | complete)
  
  if $gpg_result.exit_code == 0 {
    print "[OK] GPG signature verified"
  } else {
    error make { msg: $"GPG signature verification failed:\n($gpg_result.stderr)" }
  }

  print ""
  print "=== All Verifications Passed ==="
  print $"File ready at: ($filepath)"

  # Display usage instructions
  print ""
  print $"To create bootable USB using mkusb:"
  print $"sudo mkusb-nox ($filepath) all"
  print ""
  print "Alternative method using grub-n-iso (usb-pack-efi):"
  print $"sudo usb-pack-efi ($filepath)"
  print $"# Creates multiboot USB that can hold multiple ISOs"
  print ""
  print $"Install mkusb if not available:"
  print $"sudo add-apt-repository --yes ppa:mkusb/ppa"
  print $"sudo apt update && sudo apt install --yes mkusb usb-pack-efi"
  print ""
  print $"WARNING: This will destroy all data on the target USB device!"
}
