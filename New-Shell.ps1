<#
.SYNOPSIS
  Create new Shell
.DESCRIPTION
  Initializes shell/env for application

.PARAMETER Type
  Type of shell we want to create

.EXAMPLE
  New-Shell -Type SSH

.NOTES
  Type Pwsh opens an elevated prompt
  Calling without a type specified opens a regular pwsh
#>

[CmdletBinding()] Param (
  [string] $Type = ''
)

function InvokeNewShell() {
  # For apps that are just short cut commands
  switch( $Type ) {
    'Pwsh' { # elevated
      Push-Location $PwshScriptDir
      Start-Process pwsh -ArgumentList '-NoExit', '-NoLogo', 'Init-App.ps1 admin' -ErrorAction 'Stop' -Verb Runas
      Pop-Location
    }
    'Meta' { # elevated
      Push-Location $PwshScriptDir
      Start-Process pwsh -ArgumentList '-NoExit', '-NoLogo', 'Init-App.ps1 fb-tools' -ErrorAction 'Stop' -Verb Runas
      Pop-Location
    }
    'SSH' {
      Push-Location $PwshScriptDir
      Start-Process pwsh -ArgumentList '-NoExit', '-NoLogo', 'Init-App.ps1 openssh' -ErrorAction 'Stop'
      Pop-Location
    }
    'Node' {
      Push-Location $PwshScriptDir
      Start-Process pwsh -ArgumentList '-NoExit', '-NoLogo', 'Init-App.ps1 node' -ErrorAction 'Stop'
      Pop-Location
    }
    'Powershell' {
      Start-Process Powershell -ErrorAction 'Stop' -ArgumentList '-NoExit', '-NoLogo', '-Command', `
        { (Get-Host).UI.RawUI.WindowTitle = 'META Powershell' }
    }
    default {
      Start-Process pwsh -ErrorAction 'Stop' -ArgumentList '-NoExit', '-NoLogo', '-Command', `
        { (Get-Host).UI.RawUI.WindowTitle = 'META Terminal' }
    }
  }
}

InvokeNewShell
