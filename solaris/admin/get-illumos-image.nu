#!/usr/bin/env nu
# Illumos media writer

# Downloads an OpenIndiana (OI) or OmniOS image, verifies SHA-256, and prints
# the filename.
# Defaults: os=OpenIndiana, release=stable, has_gui=false. Uses wget2 for large
# downloads.
# TODO: enable tilda expansion

def build_url [os_name: string, channel: string, version: string, has_gui: bool] {
  let os = ($os_name | str downcase)
  if $os in ["openindiana", "oi"] {
    let edition = (if $has_gui { "gui" } else { "text" })
    if $channel == "stable" {
      $"https://dlc.openindiana.org/isos/hipster/($version)/OI-hipster-($edition)-($version).usb"
    } else {
      $"https://dlc.openindiana.org/isos/hipster/test/OI-hipster-($edition)-($version).usb"
    }
  } else if $os == "omnios" {
    if $channel == "stable" {
      $"https://downloads.omnios.org/media/stable/omnios-($version).usb-dd"
    } else {
      $"https://downloads.omnios.org/media/bloody/omnios-bloody-($version).usb-dd"
    }
  } else {
    error make { msg: $"Unknown os_name: ($os_name). Use OI/OpenIndiana or OmniOS." }
  }
}

def sha_url [image_url: string, os_name: string] {
  let os = ($os_name | str downcase)
  if $os in ["openindiana", "oi"] {
    $"($image_url).sha256sum"
  } else {
    $"($image_url).sha256"
  }
}

def main [
  output_dir: string,          # mandatory
  os_name: string,             # strictly: "OI", "OpenIndiana", "openindiana", 
                               #  "OmniOS", or "omnios"
  release: string,             # "stable" or "beta"  
  --version: string = "",      # flag with default: --version "20250914"
  --gui                        # flag: --has-gui
] {
  # Strict validation for os_name
  let os_type = (if $os_name == "OI" {
    "OpenIndiana"
  } else if $os_name in ["OpenIndiana", "openindiana"] {
    "OpenIndiana"
  } else if $os_name in ["OmniOS", "omnios"] {
    "OmniOS"
  } else {
    error make { msg: $"Invalid os_name: ($os_name). Use OI, OpenIndiana, openindiana, OmniOS, or omnios." }
  })

  # Validate release using 'in' operator
  if $release not-in ["stable", "beta"] {
    error make { msg: $"Invalid release: ($release). Valid values: stable, beta." }
  }

  # Set default version if blank
  let latest = "20251011"
  let version_default = (if $release == "stable" {
      if $os_type == "OpenIndiana" {
        "20250606"
      } else {
        "r151054r"
      }
    } else {
      $latest
    })
  let version = (if $version == "" { $version_default } else { $version })

  # Check if directory exists, exit with error if it doesn't
  if not ($output_dir | path exists) {
    error make { msg: $"Directory ($output_dir) does not exist." }
  }

  # GUI only applies to OpenIndiana, use $gui flag directly
  let request_gui = (if $os_type == "OpenIndiana" { $gui } else { false })

  # Convert to lowercase for URL building
  let os_for_url = (if $os_type == "OpenIndiana" { "openindiana" } else { "omnios" })

  let image_url = (build_url $os_for_url $release $version $request_gui)
  let checksum_url = sha_url $image_url $os_for_url

  let filename = ($image_url | split row "/" | last)
  let filepath = ($output_dir | path join $filename)

  # Download only if file doesn't exist
  if ($filepath | path exists) {
    print $"File ($filename) already exists, skipping download."
    # resume download if previous one was interrupted
    # wget2 --continue --directory-prefix $output_dir $image_url
  } else {
    print $"Downloading ($filename).."
    # gotta add parenthesis if this syntax is used: `--directory-prefix=$output_dir`
    wget2 --directory-prefix $output_dir $image_url
  }

  # Fetch checksum text without saving a file
  let checksum_text = (http get --raw $checksum_url) | decode utf-8

  # Compute sha256 of downloaded file and compare to first token in checksum
  # file
  let file_hash = (open $filepath | hash sha256)
  let expected = ($checksum_text | lines | first | split row " " | first)

  if $file_hash == $expected {
    print $"[OK] sha256 verified for ($filename)"
  } else {
    error make { msg: ("sha256 mismatch: " + "\'" + $file_hash + "\' vs \'" + $expected + "\'") }
  }

  # write image
  # for Omni change bs to 1M
  # OI example:
  # sudo dd bs=4M if=$filepath of=[TODO]/dev/sda status=progress conv=fsync
  # actual cmd example
  # sudo dd bs=4M if=($env.Home)/soft/images/OI/OI-hipster-text-20250914.usb of=/dev/sda status=progress conv=fsync

  # warning all data will be destroyed..
  # 
}