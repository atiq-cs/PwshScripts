<#
.SYNOPSIS
  Clean up Street Smart Edge Credentials Cache

.DESCRIPTION
  Automate the clean up

.EXAMPLE
  $ Get-DirStat.ps1 -InputDir D:\theatre\Shows -Type Size


.NOTES
  Probably useless now since Street Smart Edge is deprecated.

tag: windows-only, file-system
#>

# Entry Point Function
function Main() {
  # compare and show difference
  $Config_File_1 = $Env:APPDATA + '\Charles Schwab\StreetSmart Edge\AppData\LocalSettings.config'
  $Config_File_2 = $Env:APPDATA + '\Charles Schwab\StreetSmart Edge\AppData\LocalSettings.config.bak'

  If (Test-Path $Config_File_1) {  Remove-Item $Config_File_1  }
  If (Test-Path $Config_File_2) {  Remove-Item $Config_File_2  }
}

Main
