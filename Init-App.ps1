<#
.SYNOPSIS
Initialize Specified Application
.DESCRIPTION
Modify Env Path

ToDo: set dim: 152x18

.PARAMETER AppName
name of app for which to init
Should also replace functionalities provided by PARAM psConsoleType
Console type: for future use, `Init-App` replaces it for now.

ToDo: except array of strings instead of a string
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
  [ValidateSet('admin', 'resetEnvPath', 'choco', 'dotnet', 'git-cmd', 'git', 'fb-tools', 'node',
  'pwsh', 'openssh', 'python')] [string] $AppName = 'resetEnvPath')

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
      (Get-Host).UI.RawUI.WindowTitle = "root @ FB Terminal"
      # choco
      InitVariables 'choco'
      $SourceList = choco sources list
      # previous, see if we still need this after running `Cleanup-FBIT`
      # if (! $SourceList[1].Contains('chocolatey')) {
      #   Write-Host 'choco first entry is different, have a look!'
      #   return
      # }

      if ($SourceList.Length -lt 4 -Or ! $SourceList[1].Contains('chocolatey')) {
        Write-Host 'choco first entry is different, have a look! auto fixing..'
        choco source add -n=chocolatey -s="https://chocolatey.org/api/v2/"
      }
      if ($SourceList[1].Contains('[Disabled]')) {
        # choco source add -n=chocolatey -s="https://chocolatey.org/api/v2/"
        choco source enable -n=chocolatey
        # choco source remove -n cpe_client
        # choco source remove -n wfh
        choco source disable -n=cpe_client
        choco source disable -n=wfh
        choco sources list
        return
      }
      return
    }
    'choco' {
      $Env:ChocolateyInstall = 'D:\PFiles_x64\Chocolatey'
      $Env:ChocolateyToolsLocation = $Env:ChocolateyInstall +'\tools'
      AddToEnvPath( $Env:ChocolateyInstall + '\bin' )
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

      if (Test-Path Env:DOTNET_ROOT) { Remove-Item Env:DOTNET_ROOT }

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
    'fb-tools' {  # required to utilize tooling
      (Get-Host).UI.RawUI.WindowTitle = "root @ FB Terminal with fb-tools"

      # choco fbit
      InitVariables 'choco'

      # CPE\lib to PSModulePath, firt line is FB only
      $CPEPath = 'C:\WINDOWS\CPE\lib\powershell'
      if ($Env:PSModulePath.Contains($CPEPath) -Eq $False) { $Env:PSModulePath += ';' + $CPEPath }

      # ruby
      AddToEnvPath('C:\opscode\chef\embedded\bin')
      # ssh support for VSCode
      AddToEnvPath($Env:ChocolateyToolsLocation + '\fb.gitbash\usr\bin')

      $SourceList = choco sources list

      if (! $SourceList[3].Contains('cpe_client')) {
        Write-Host 'choco first entry is different, have a look!'
        return
      }

      if ($SourceList[3].Contains('[Disabled]')) {
        # choco source add -n=wfh -s="C:\chef\solo\confectioner\latest"
        # choco source add -n=cpe_client -s="https://confectioner.thefacebook.com/"
        choco source enable -n=cpe_client
        choco source enable -n=wfh
        # choco source remove -n chocolatey
        choco source disable -n=chocolatey
        choco sources list
        return
      }
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

      Push-Location D:\Code\TS
      return
    }
    'pwsh' {
      AddToEnvPath $PwshScriptDir
      return
    }
    'openssh' {
      (Get-Host).UI.RawUI.WindowTitle = "SSH Terminal"
      AddToEnvPath( $PFilesX64Dir + '\ssh' )
      return
    }
    'python' {
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
