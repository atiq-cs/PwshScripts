#!/usr/bin/env nu
# -----------------------------------------------------------------------------
# Script : Tax Tool
# Desc   : Download and backup IRS tax forms from irs.gov PDF repository.
# Date   : 09-10-2025
# Depends: Nushell core commands (http get, path, save, cp, mkdir)
#
# Usage:
# ./tax-tool.nu <co_type> <form_name> <output_dir>
#  - co_type: Form type - 'federal' or 'state'
#  - form_name: IRS form number without 'f' prefix (e.g., "1040sd", "8949")
#  - output_dir: Directory to save forms (e.g., ~/Doc/Tax-24)
#  - Creates 'forms/' subdirectory for backup copies
#
# Examples:
#   ./tax-tool.nu federal 1040sd ~/Doc/Tax-24
#   ./tax-tool.nu federal 8949 ~/Documents/Taxes
#   ./tax-tool.nu state 540 ~/Tax/CA-2024
#
# Behavior:
#   - Downloads from https://www.irs.gov/pub/irs-pdf/f<form>.pdf
#   - If backup exists and target exists: exits with message
#   - If backup exists but target missing: copies from backup
#   - Otherwise: downloads from URL and creates backup
#   - Federal forms: f<form>.pdf -> f<form>_orig.pdf backup
#   - State forms: <form>.pdf -> <form>_orig.pdf backup
#
# Notes:
#   - Initial port of PowerShell script: 'pwsh/TaxTool.ps1'
#   - State form logic not fully tested yet
#   - Additional conditional logic to be added later
#   - Uses absolute paths, avoids push/pop directory operations
#
# tag: cross-platform
# -----------------------------------------------------------------------------

def main [
  co_type: string                # e.g. 'federal' or 'state'
  form_name: string              # e.g. '1040sd'
  output_dir: path               # e.g. '~/Doc/Tax-24'
] {
  let forms_backup_dir = 'forms'
  let co_base_url = 'https://www.irs.gov/pub/irs-pdf/'
  let file_name = $"f($form_name).pdf"
  let url = $"($co_base_url)($file_name)"

  let bak_form_name = if $co_type == 'state' {
    $"($form_name)_orig.pdf"
  } else {
    $"f($form_name)_orig.pdf"
  }

  # compute absolute paths without changing directory
  let out_abs = ($output_dir | path expand)

  let forms_backup_path = ($out_abs | path join $forms_backup_dir)
  let file_path = ($out_abs | path join $file_name)
  let bak_file_path = ($forms_backup_path | path join $bak_form_name)

  if ($bak_file_path | path exists) {
    if ($file_path | path exists) {
      print $"($file_name) already exists!"
      return
    } else {
      print $"Local copy of ($bak_form_name) exists! Using that instead.."
      cp -f $bak_file_path $file_path
      return
    }
  } else {
    print $"URL for the input form: ($url)"
    try {
      # download the PDF in binary mode and save to file_path
      http get --raw $url | save -f $file_path
    } catch { |err|
      let msg = $err.msg?

      if ($msg | str contains '404') {
        print "Error: File not found (404). Check the URL."
      } else {
        print $"An error occurred: ($msg)"
      }
      return
    }
  }

  if not ($forms_backup_path | path exists) {
    mkdir $forms_backup_path
  }

  cp -f $file_path $bak_file_path
  print ($"Retrieving and backing up an original copy of form "
      + $"($form_name) completed!")
}
