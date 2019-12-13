<#
.SYNOPSIS
Add new Application to registry
.DESCRIPTION
This adds `Start-Process` support for an app
.PARAMETER AppName
name of app to register
.PARAMETER Path
actual binary path
.EXAMPLE
.\RegisterApp Skype D:\PFiles_x86\choco\Skype\Skype.exe

.NOTES
By default it creates `-PropertyType MultiString` if not specified.

Required following Env Vars,
 N/A

`New-ItemProperty` supports LiteralPath where `New-Item` does not.
`-LiteralPath` won't work because registry path contains space i.e., the middle part: `..\CurrentVersion\App Paths\*`

## References
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/new-itemproperty

tag: windows-only-script
#>

Param (
  [string] $AppName, [string] $Path)

# Start of Main function
function Main() {
  if (! (Test-Path $Path)) {
    Write-Host "Not valid path: $Path"
    return 
  }

  # Remove before, if entry already exists
  # Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe"
  # return
  if ((Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe") -Or 
      (Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe")) {
    "App is already registered!"
    return
  }

  "Registering..  "
  New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe"

  $lastindex = [int] $Path.lastindexof('\')
  $PPath = $Path.Substring(0, $lastindex)
  New-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe" -Name '(Default)' -Value $Path
  New-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe" -Name 'Path' -Value $PPath
}

Main
