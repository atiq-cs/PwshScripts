<#
.SYNOPSIS
  Perform complex renames
.DESCRIPTION
  Provides examples for complex renames
  - regex
  - escape sequence

.PARAMETER Dir
  Dir for which to iterate files and apply action

.EXAMPLE
  RenameUtil.ps1 D:\Code\PSolving\cf
  RenameUtil.ps1 D:\theatre\Shows\Robot\*.srt

.NOTES
  Previous examples,
  1. Append 0 in the beginning of the name
    $newFileName = ( $item.BaseName -replace '^(\d\d\d[A-Z]_.+)','0$1' ) + $item.Extension

  2. Short syntax for replace
    Rename-Item $item -NewName { $_.Name -replace '^(\d\d\d[A-Z]_.+)','0$1' }

    # Check full name of the item
    $item.FullName

  *more examples in paper doc*
#>

[CmdletBinding()] Param (
  [Parameter(Mandatory=$true)] [string] $InputDir)

function Main() {
  Push-Location $InputDir

  # "$InputDir\*.srt"
  foreach ($item in Get-ChildItem $InputDir -File) {
    # Init
    $newFileName = $item.BaseName
    # $item.BaseName + $item.Extension

    #  to remove [str] use string: ' \[str\]'

    $newFileName = $newFileName -replace '^S04E(\d\d)','E$1'
    # $newFileName = $newFileName -replace '\.',' '

    $newFileName = $newFileName -replace '\.psarip',''

    # Finalize the name
    $newFileName = $newFileName + $item.Extension

    # Output name, useful to check before running actual operation
    $item.BaseName + $item.Extension + ' ->'
    $newFileName + [System.Environment]::NewLine

    # Actual Op
    if (!$newFileName.Equals($item.Name)) {
      Rename-Item $item -NewName $newFileName
    }
  }

  Pop-Location
}

Main
