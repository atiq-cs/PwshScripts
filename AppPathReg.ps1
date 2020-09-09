<#
.SYNOPSIS
Add new app or update existing app in registry
.DESCRIPTION
This adds `Start-Process` support for an app or to invoke the app from Run
(Win + R) Dialog Box for a new app.
For an existing app in registry, it update the location and binary path.
.PARAMETER AppName
name of app to register
.PARAMETER Path
actual binary path
.EXAMPLE
AppPathReg Skype D:\PFiles_x86\choco\Skype\Skype.exe

.NOTES
There are three places to look for registry app paths,
1. HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths
2. same location in HKCU
3. HKCR:\Applications requires a custom mapping
  $ New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT

By default it creates `-PropertyType MultiString` if not specified.

Required following Env Vars,
 N/A

`New-ItemProperty` supports LiteralPath where `New-Item` does not.
`-LiteralPath` won't work because registry path contains space i.e., the middle part: `..\CurrentVersion\App Paths\*`

Before implementing update, I used to manually remove the entry before adding
the entry again to perform the action `update`,

  # Remove before, if entry already exists
  Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe"

### References
- [app-registration](https://docs.microsoft.com/en-us/windows/win32/shell/app-registration)
- [new-itemproperty](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/new-itemproperty)

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

  $PPath = [IO.Path]::GetDirectoryName($Path)

  # Accessing HKCR requires admin privilege
  # if app already is registered update its binary path (key: Default)
  #  and update its starting in path (key: Path)
  if ((Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe") -Or 
      (Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe")) {
    $CurrentRegPathVal = Get-ItemPropertyValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Skype.exe" -Name `(default`)
    if (([string]::IsNullOrEmpty($CurrentRegPathVal) -Eq $True) -Or [string]::Equals($CurrentRegPathVal, $Path) -Eq $False) {
      Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe" -Name '(Default)' -Value "$Path"
      Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe" -Name 'Path' -Value "$PPath"
    }
  }
  # else app doesn't exist: it's new app; register it
  else {
    "Registering path: " + "`"$Path`""
    New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe"

    New-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe" -Name '(Default)' -Value $Path
    New-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe" -Name 'Path' -Value $PPath
  }
}

Main


<#
  Some previous approach for update,
  # Remove before, if entry already exists
  # Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe"
  # return
#>