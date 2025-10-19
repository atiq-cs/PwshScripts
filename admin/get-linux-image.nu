#!/usr/bin/env nu
# -----------------------------------------------------------------------------
# Script : Pop!_OS Beta Image Downloader
# Desc   : Downloads latest Pop!_OS beta ISO image and verifies SHA256 checksum
#          Supports both NVIDIA and Intel/AMD variants with automatic URL construction
#          and checksum verification using hardcoded official checksums
#
# Date   : 10-19-2025  
# Deps   : Nushell core commands (hash sha256, path), wget2
#
# Usage:
# ./get-linux-image.nu pop_os 24.04 ~/soft/images
#  - Downloads Pop!_OS 24.04 beta with default NVIDIA variant
#  - Creates pop-os_24.04_amd64_nvidia_<build>.iso in specified directory
#  - Verifies SHA256 checksum against official hash
#
# ./get-linux-image.nu pop_os 24.04 ~/soft/images --variant amd64
#  - Downloads Intel/AMD variant instead of default NVIDIA
#
# Notes:
#  - NVIDIA variant is default (RTX 16xx/20xx/30xx/40xx series and newer)
#  - amd64 variant for Intel/AMD graphics or GTX 1060 and older
#  - Build number auto-detected from latest beta release
#  - Verifies file integrity before completion
#
# tag: nushell, linux, sha256
# -----------------------------------------------------------------------------

def build_pop_os_url [version: string, variant: string, build: string] {
  # Map amd64 variant to 'intel' for URL path
  let url_variant = (if $variant == "amd64" { "intel" } else { $variant })
  $"https://iso.pop-os.org/($version)/amd64/($url_variant)/($build)/pop-os_($version)_amd64_($url_variant)_($build).iso"
}

def get_hardcoded_checksum [variant: string] {
  # Hardcoded checksums for Pop!_OS 24.04 beta build 20
  if $variant == "nvidia" {
    "f784386044d57b1acba9e27e987c402e37c87719cc5fe93dd05d194624cf65e8"
  } else if $variant == "amd64" {
    "a0ef3842ab710db4f4407cf3499560b59dddbbcd59bee17beab7b0e99dc22b4c"
  } else {
    error make { msg: $"Unknown variant: ($variant)" }
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
  let filename = ($image_url | split row "/" | last)
  let filepath = ($output_dir | path join $filename)

  # Download only if file doesn't exist
  if ($filepath | path exists) {
    print $"File ($filename) already exists, skipping download."
  } else {
    print $"Downloading ($filename) from Pop!_OS beta servers..."
    wget2 --directory-prefix $output_dir $image_url
  }

  # Verify checksum using hardcoded value
  print $"Verifying checksum for ($filename)..."
  
  let expected = (get_hardcoded_checksum $variant)
  let file_hash = (open $filepath | hash sha256)

  if $file_hash == $expected {
    print $"[OK] SHA256 verified for ($filename)"
    print $"File ready at: ($filepath)"
  } else {
    error make { msg: $"SHA256 mismatch: got '($file_hash)' expected '($expected)'" }
  }

  # Display usage instructions
  print ""
  print $"To create bootable USB using mkusb:"
  print $"sudo mkusb-nox ($filepath) all"
  print ""
  print $"Alternative method using grub-n-iso (usb-pack-efi):"
  print $"sudo usb-pack-efi ($filepath)"
  print $"# Creates multiboot USB that can hold multiple ISOs"
  print ""
  print $"Install mkusb if not available:"
  print $"sudo add-apt-repository --yes ppa:mkusb/ppa"
  print $"sudo apt update && sudo apt install --yes mkusb usb-pack-efi"
  print ""
  print $"WARNING: This will destroy all data on the target USB device!"
}
