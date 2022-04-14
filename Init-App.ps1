<#
.SYNOPSIS
  Initialize Specified Application
.DESCRIPTION
  Initializes shell/env for application

.PARAMETER AppName
  name of app for which to init
  Should also replace functionalities provided by PARAM psConsoleType
  Console type: for future use, `Init-App` replaces it for now.

.PARAMETER IsCodeFB
  For StartX CodeFB don't run certain stuffs
.EXAMPLE
  Init-App
  is equivalent to,
  Init-App resetEnvPath

.NOTES
  targetting apps i.e., choco, python (ML)

  Required following Env Vars,
  - $PFilesX64Dir
#>

[CmdletBinding()] Param (
  [string] $AppName = 'resetEnvPath',
  [bool] $IsCodeFB = $False
)

function AddToEnvPath([string] $path = ';') {
  if (! (Test-Path $path)) {
    Write-Host "Not valid path: $path"
    return
  }
  if ($Env:Path.Contains($path) -Eq $False) {
    $Env:Path += ';' + $path
  }
}

function RemoveFromEnvPath([string] $path = '') {
  if (-not [string]::IsNullOrEmpty($path)) {
    Write-Host "Empty string: $path"
    return
  }

  if (! (Test-Path $path)) {
    Write-Host "Not valid path: $path"
    return
  }

  if ($Env:Path.Contains($path)) {
    $Env:Path = $Env:Path.Replace("$path;", "")
  }
}

<#
.SYNOPSIS
The Main function of this Script
.DESCRIPTION
Modify Env Path

Adding 'C:\Tools' Usually not required: do a cc-certs renewal based on expiration value and the
dialog box for init won't appear to bother us again! Tools is deprecated by ChocolateyToolsLocation

.PARAMETER InitType
Customized init based on type
.EXAMPLE
InitVariables choco
.NOTES
To facilitate calling it nested
#>
function InitVariables([string] $InitType = 'resetEnvPath') {
  'Init for app: ' + $InitType

  switch( $InitType ) {
    'admin' {
      (Get-Host).UI.RawUI.WindowTitle = "root @ Matrix Terminal"
      # choco
      InitVariables 'choco'
      .\Choco-Util

      return
    }
    'choco' {
      $Env:ChocolateyInstall = 'D:\PFiles_x64\Chocolatey'
      $Env:ChocolateyToolsLocation = $Env:ChocolateyInstall +'\tools'
      AddToEnvPath( $Env:ChocolateyInstall + '\bin' )

      # Chocolatey profile
      $ChocolateyProfile = "$Env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
      if (Test-Path($ChocolateyProfile)) {
        Import-Module "$ChocolateyProfile"
      }
      return
    }
    # restore path to default
    # ** this should be taken care of using post chef run script
    # however, this one should run a validation check whether is PATH is clean!
    # ToDo: if choco can support custom install dir for Pwsh 7
    'resetEnvPath' {
      $Env:Path = 'C:\windows\system32;C:\windows;C:\windows\System32\Wbem;' + $Env:LOCALAPPDATA +
        '\Microsoft\WindowsApps;C:\windows\System32\WindowsPowerShell\v1.0;' + $PSHOME + ';' +
        $PwshScriptDir

      # TODO: iterate over a list instead
      if (Test-Path Env:DOTNET_ROOT) { Remove-Item Env:DOTNET_ROOT }
      if (Test-Path Env:ChocolateyInstall) { Remove-Item Env:ChocolateyInstall }
      if (Test-Path Env:ChocolateyToolsLocation) { Remove-Item Env:ChocolateyToolsLocation }

      return
    }
    # rest are path updates
    'dotnet' {
      # decoration '$(' is required to not consider space as argument delimeter
      $Env:DOTNET_ROOT = $PFilesX64Dir + '\dotnet'
      if (! (Test-Path $Env:DOTNET_ROOT)) {
        'Please install net core'
        New-Item -ItemType Directory $Env:DOTNET_ROOT
      }
      AddToEnvPath( $Env:DOTNET_ROOT )
      # print net core version
      $index = (dotnet --list-sdks).Count -1
      $netCoreVersion = (dotnet --list-sdks)[$index]
      # split to remove install location from output
      'net core sdk: ' + ($netCoreVersion -split '\[')[0]

      # add .net core global location for current user
      $DOTNET_USER_GLOBAL = $Env:USERPROFILE + '\.dotnet\tools'
      if (Test-Path $DOTNET_USER_GLOBAL) {
        AddToEnvPath( $DOTNET_USER_GLOBAL )
      } else {
        'net core user global path not found'
      }

      return
    }
    'meta' {  # required to utilize tooling
      InitVariables 'choco'

      # IsCodeFB is used to indicate that location push is not required;
      # also check usage example in 'StartX.ps1'
      #   Init-App.ps1 fb-tools $False
      if (! $IsCodeFB) {
        (Get-Host).UI.RawUI.WindowTitle = "root @ FB Terminal with fb-tools"
        # choco fbit
        Choco-Util.ps1 'META'
      }

      # CPE\lib to PSModulePath, firt line is FB only
      $CPEPath = 'C:\WINDOWS\CPE\lib\powershell'
      if ($Env:PSModulePath.Contains($CPEPath) -Eq $False) { $Env:PSModulePath += ';' + $CPEPath }

      # ruby
      AddToEnvPath('C:\opscode\chef\embedded\bin')
      # ssh support for VSCode
      AddToEnvPath($Env:ChocolateyToolsLocation + '\fb.gitbash\usr\bin')
      return
    }
    'git-cmd' {
      AddToEnvPath( $PFilesX64Dir + '\git\cmd' )
      return
    }
    # planned deprecation by 'Git Util' net core app
    'git' {
      # remove git-cmd from path
      RemoveFromEnvPath( $PFilesX64Dir + '\git\cmd' )
      AddToEnvPath( $PFilesX64Dir + '\git\bin' )
      return
    }
    'node' {
      AddToEnvPath( $PFilesX64Dir + '\Node' )
      AddToEnvPath( $Env:APPDATA + '\npm' )

      if (! $IsCodeFB) {
        (Get-Host).UI.RawUI.WindowTitle = "TypeScript/Node Terminal"
        # temporarily using IsCodeFB to prevent location push
        Push-Location D:\Code\TS
      }
      return
    }
    'openssh' {
      (Get-Host).UI.RawUI.WindowTitle = "SSH Terminal"
      AddToEnvPath( $PFilesX64Dir + '\ssh' )
      return
    }
    'python' {
      (Get-Host).UI.RawUI.WindowTitle = "ML Workstation"
      AddToEnvPath( $PFilesX64Dir + '\python3' )
      AddToEnvPath( $PFilesX64Dir + '\python3\Scripts' )

      Push-Location D:\Code\ML
      python -m venv env
      env\Scripts\Activate.ps1
      return
    }
    'build' {
      return
    }
    default {
      'Invalid command line argument: ' + $InitType
      return
    }
  }
}

InitVariables $AppName
# Actually we do not want to reset every time we add an app on path, use empty string for
# explicit reset of Env Path
# InitVariables 'resetEnvPath'
