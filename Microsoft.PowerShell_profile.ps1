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
N/A
.NOTES
Requires following Vars to be defined,
- `$PwshScriptDir`

Eliminiates following vars,
- PHOST
- SC_DIR

Avoid function declaration such as following, since it is loaded into pwsh env cache

  function InitEnvironent()
#>

# Set up variables for Pwsh Home Dir and Program Files
$PwshScriptDir = 'D:\pwsh-scripts'
$PFilesX64Dir = 'D:\PFiles_x64\choco'
$PFilesX86Dir = 'D:\PFiles_x86\choco'
If ($Env:COMPUTERNAME -eq '4N391Z2') {
  $PHOST_TYPE = 'office'
} Else {
  $PHOST_TYPE = 'matrix'
}

# Method List
# get the last part of path, consumed by method: `prompt`
function Get-DirAlias([string] $location = $(Get-Location)) {
  # check if we are in our home script dir; yes: return home sign, unix retro
  if ($location.Equals($PwshScriptDir)) { return "~" }
    
  # if it ends with \ that means we are in root of drive
  # in that case return drive
  if ($location.EndsWith("\")) { return $location.Substring(0, $location.Length-1) }

  # Otherwise return only the dir name
  $lastIndex = [int] $location.lastIndexOf('\') + 1
  return $location.Substring($lastIndex)
}

# Set prompt
function prompt {
  return "[$($Home.SubString($Home.LastIndexOf('\')+1))@" + $(If ($PHOST_TYPE `
    -eq 'office') { 'fb' } Else { $PHOST_TYPE }) + " $(Get-DirAlias)]$ "
}

# Commands to set up new shell
Push-Location $PwshScriptDir