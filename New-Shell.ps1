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
  With Type specified as Pwsh it opens an elevated prompt
  Calling without a type specified opens a regular pwsh

  * Once in a while, Pwsh shell's cannot invoke Start-Process
    (feels like cmdlet call is dangled,  stderr/stdout probably is the reason)
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
    'dotnet' {
      Push-Location $PwshScriptDir
      Start-Process pwsh -ErrorAction 'Stop' -ArgumentList '-NoExit', '-NoLogo', '-Command', `
      { `
        (Get-Host).UI.RawUI.WindowTitle = 'dotnet Shell' ; `
        Init-App.ps1 dotnet `
      }
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
        { (Get-Host).UI.RawUI.WindowTitle = 'Qubit Powershell' }
    }
    'Cmd' { # elevated
      Push-Location $PwshScriptDir
      'FYI: Utilize Run Dialog for a regular cmd process (not elevated)'
      Start-Process cmd -ArgumentList '-NoExit', '-NoLogo', 'Init-App.ps1 admin' -ErrorAction 'Stop' -Verb Runas
      Pop-Location
    }
    'Meta' { # elevated
      Push-Location $PwshScriptDir
      Start-Process pwsh -ArgumentList '-NoExit', '-NoLogo', 'Init-App.ps1 meta' -ErrorAction 'Stop' -Verb Runas
      Pop-Location
    }
    default {
      Start-Process pwsh -ErrorAction 'Stop' -ArgumentList '-NoExit', '-NoLogo', '-Command', `
        { (Get-Host).UI.RawUI.WindowTitle = 'Qubit Terminal' }
    }
  }
}

InvokeNewShell
