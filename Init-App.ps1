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
  [ValidateSet('admin', 'resetEnvPath', 'choco', 'dotnet', 'git', 'fb-tools', 'pwsh', 'python')] [string] $AppName = 'resetEnvPath')

function AddToEnvPath([string] $path = ';') {
  if (! (Test-Path $path)) {
    Write-Host "Not valid path: $path"
    return
  }
  if ($Env:Path.Contains($path) -Eq $False) {
    $Env:Path += ';' + $path
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
      InitVariables 'choco'
      return
    }
    'choco' {
      # choco sources list
      # choco source add -n=chocolatey -s="https://chocolatey.org/api/v2/"
      # choco source remove -n cpe_client
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
      return
    }
    'fb-tools' {  # required to utilize tooling
      InitVariables choco
      # CPE\lib to PSModulePath, firt line is FB only
      $CPEPath = 'C:\WINDOWS\CPE\lib\powershell'
      if ($Env:PSModulePath.Contains($CPEPath) -Eq $False) { $Env:PSModulePath += ';' + $CPEPath }

      # ssh support for VSCode
      AddToEnvPath($Env:ChocolateyToolsLocation + '\fb.gitbash\usr\bin')
      return
    }
    # planned deprecation by 'Git Util' net core app
    'git' {
      AddToEnvPath( $PFilesX64Dir + '\git\cmd' )
      return
    }
    'pwsh' {
      AddToEnvPath $PwshScriptDir
      return
    }
    'python' {
      AddToEnvPath( $PFilesX64Dir + '\python3;' + $PFilesX64Dir + '\python3\Scripts' )
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
