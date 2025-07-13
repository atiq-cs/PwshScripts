<#
.SYNOPSIS
Initialize Pwsh Environment

.DESCRIPTION
Provides following for frequent use,
- highly optimized methods
- optimal number of variables (avoid touching Sys Env Vars when possible, be
 aware this breaks compatibility with old cmd scripts back from past)

Actions,
- Set Location to home dir

.EXAMPLE
Simple one: type pwsh on command

.NOTES
Requires following Vars to be defined,
- $ShellHome

Avoid additional function declarations (for example, 'function InitEnvironent()') since all those from $profile file are
 loaded into pwsh env cache
#>

# Init Pwsh/Shell Home Dir
$ShellHome = $(If ($IsLinux) { $HOME } Else { 'D:\Code' } ) + `
  [System.IO.Path]::DirectorySeparatorChar + 'shell' + [System.IO.Path]::`
  DirectorySeparatorChar + 'pwsh'

# Init Program File Vars
If ($IsWindows) {
  # Init Program File Vars
  $PFilesX64Dir = 'C:\PFiles_x64\choco'
  $PFilesX86Dir = 'C:\PFiles_x86\choco'
}

# Deprecated
# If ($Env:COMPUTERNAME -eq '4N391Z2') {
#   $PHOST_TYPE = 'office'
# }

# Deprecated; prefered var $Env:HOSTNAME
# $PHOST_TYPE = 'matrix'


# Method List
# get the last part of path, consumed by method: `prompt`
function Get-DirAlias([string] $path = $(Get-Location)) {
  # check if we are in our home script dir; yes: return home sign, unix retro
  if ($path.Equals($ShellHome)) { return "~" }

  # Win only
  # if it ends with Separator that means we are in root of drive
  # in that case return drive
  if ($IsWindows -And $path.EndsWith([System.IO.Path]::`
    DirectorySeparatorChar.ToString())) {
      return $path.Substring(0, $path.Length-1)
  }

  # Linux only
  if ($path.Equals("/")) {
    return $path
  }

  # Otherwise return only the dir name
  return [System.IO.Path]::GetFileName($path)
}

# Set prompt
function prompt {
  $HostName = if ($IsWindows) { $Env:COMPUTERNAME } Else { $Env:HOSTNAME }
  Write-Host -NoNewline -ForegroundColor Green $($Env:USERNAME + "@" + $HostName + " ")
  Write-Host -NoNewline -ForegroundColor Cyan $("$(Get-DirAlias)")
  return "$ "
}

# Set Current Working Dir
Set-Location $ShellHome


# Win only below:
#  Chocolatey profile
#  Moved it to Init-App.ps1 choco section