<#
.SYNOPSIS
Initialize Specified Application
.DESCRIPTION
Modify Env Path
.PARAMETER AppName
name of app for which to init
.EXAMPLE

.NOTES
targetting apps i.e., choco, python (ML)

Required following Env Vars,
 - $Env:PFilesX64
#>

[CmdletBinding()] Param (
  [ValidateSet('resetEnvPath', 'choco', 'dotnet', 'pwsh', 'python', 'git')] [string] $AppName)

function AddToEnvPath([string] $path = ';') {
  if (! (Test-Path $path)) {
    Write-Host "Not valid path: $path"
    return
  }
  if ($Env:Path.Contains($path) -Eq $False) {
    $Env:Path += ';'+$path
  }
}

'Init for app: ' + $AppName

# Start of Main function
function Main() {
  switch( $AppName ) {
    'choco' {
      # choco sources list
      # choco source add -n=chocolatey -s="https://chocolatey.org/api/v2/"
      # choco source remove -n cpe_client
      $Env:ChocolateyInstall = 'D:\PFiles_x64\Chocolatey'
      $Env:ChocolateyToolsLocation = 'D:\PFiles_x64\chocolatey\tools'
      AddToEnvPath $Env:ChocolateyInstall + '\bin'
      return
    }
    # restore path to default
    'resetEnvPath' {
      $Env:Path = 'C:\windows\system32;C:\windows;C:\windows\System32\Wbem;C:\windows\System32\WindowsPowerShell\v1.0;D:\PFiles_x64\PowerShell\6;C:\Users\atiq\AppData\Local\Microsoft\WindowsApps'
      return
    }
    # rest are path updates
    'dotnet' {
      # decoration '$(' is required to not consider space as argument delimeter
      AddToEnvPath $($Env:ProgramFiles + '\dotnet')
      return
    }
    # planned deprecation by 'Git Util' net core app
    'git' {
      AddToEnvPath $($Env:PFilesX64 + '\git\cmd')
      return
    }
    'pwsh' {
      AddToEnvPath $Env:PwshScriptDir
      return
    }
    'python' {
      AddToEnvPath $($Env:PFilesX64 + '\python3;' + $Env:PFilesX64 + '\python3\Scripts')
      return
    }
    'build' {
      return
    }
    default {
      'Invalide command line argument: ' + $AppName
      return
    }
  }
}

Main
