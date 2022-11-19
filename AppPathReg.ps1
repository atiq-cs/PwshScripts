<#
.SYNOPSIS
  Add new app or update existing app in registry
.DESCRIPTION
  This adds `Start-Process` support for an app or to invoke the app from Run
  (Win + R) Dialog Box for a new app.
  For an existing app in registry, it update the location and binary path.
  When duplicate entry exists in HKLM it supports removing it.
  Remove (an action on HKLM) requires admin privilege. Hence, that user role is checked.

  Consumer: StartX script

.PARAMETER Action
  update: add or update
  remove: remove

.PARAMETER AppName
  name of app to register
.PARAMETER Path
  actual binary path

.EXAMPLE
  AppPathReg Update Signal "$PFilesX64Dir\Signal\Signal.exe"
  AppPathReg Chrome "$Env:ProgramFiles\Google\Chrome\Application\Chrome.exe"
  AppPathReg Skype "$PFilesX64Dir\Skype\Skype.exe"

Elevated,
  AppPathReg Remove Signal

.NOTES
TODO: add an arg that specifies whether app is 32 bit or 64 bit and prepend dir path

The ternary operator is introduced in Pwsh 7, ref:
- https://docs.microsoft.com/en-us/powershell/scripting/whats-new/what-s-new-in-powershell-70
- https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_operators

Should not be used with applications which properly installs and remove these
entries.

There are three places to look for registry app paths,
1. HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths
2. same location in HKCU
3. HKCR:\Applications requires a custom mapping
  $ New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT

By default it creates `-PropertyType MultiString` if not specified.

Required following Env Vars,
 N/A

`New-ItemProperty` supports LiteralPath where `New-Item` does not.
`-LiteralPath` won't work because registry path contains space i.e., the middle
part: `..\CurrentVersion\App Paths\*`

### References
- [app-registration](https://docs.microsoft.com/en-us/windows/win32/shell/app-registration)
- [new-itemproperty](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/new-itemproperty)

tag: windows-only
#>

[CmdletBinding()] Param (
  [Parameter(Mandatory=$true)] [ValidateSet('Update', 'Remove')] [string] $Action,
  [Parameter(Mandatory=$true)] [string] $AppName,
  [string] $Path)

# Start of Main function
function Main() {
  if ($Action.Equals('Update') -And !(Test-Path $Path)) {
    Write-Host "Not valid path: $Path"
    return 
  }

  if ($Action.Equals('Remove') -And ![string]::IsNullOrEmpty($Path)) {
    Write-Host "Unexpected path argument: $Path"
    return
  }

  $PPath = [IO.Path]::GetDirectoryName($Path)


  if (-Not $Action.Equals('Remove') -And (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe") -And 
  (Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe")) {
    "Double entries (HKLM and HKCU)!!"
  }
  elseif ((Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe")) {
    if ($Action.Equals('Update')) {
      Write-Host "Update for HKLM not supported yet!"
      return
    }

    If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::`
    GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] `
      "Administrator")) {
      "HKLM: please run in elevated shell with remove argument!"
    }
    elseif ($Action.Equals('Remove')) {
      Remove-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe"
    }
  }
  # Accessing HKCR requires admin privilege
  # if app already is registered update its binary path (key: Default)
  #  and update its starting in path (key: Path)
  elseif (Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe") {
    If (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::`
    GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] `
      "Administrator")) {
      "Please run this from an un-elevated shell."
      return
    }

      $CurrentRegPathVal = Get-ItemPropertyValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe" -Name `(default`)
    if (([string]::IsNullOrEmpty($CurrentRegPathVal) -Eq $True) -Or [string]::Equals($CurrentRegPathVal, $Path) -Eq $False) {
      Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe" -Name '(Default)' -Value "$Path"
      Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe" -Name 'Path' -Value "$PPath"
    }
  }
  # else app doesn't exist: it's new app; register it
  else {
    If (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::`
    GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] `
      "Administrator")) {
      "Please run this from an un-elevated shell."
      return
    }

    "Registering path: " + "`"$Path`""
    New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe"

    New-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe" -Name '(Default)' -Value $Path
    New-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe" -Name 'Path' -Value $PPath
  }
}

Main
