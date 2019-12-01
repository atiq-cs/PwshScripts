<#
.SYNOPSIS
Initialize pwsh environment
.DESCRIPTION
Provide highly optimized methods.

Requires following Env Vars to be defined,
- `$Env:PwshScriptDir`

.EXAMPLE
N/A
.NOTES
Eliminiates following vars,
- PHOST
- SC_DIR
#>

# get the last part of path, consumed by method: `prompt`
function get-diralias([string] $location) {
  # check if we are in our home script dir; yes: return home sign, unix retro
  if ($location.Equals($Env:PwshScriptDir)) { return "~" }
    
  # if it ends with \ that means we are in root of drive
  # in that case return drive
  if ($location.EndsWith("\")) { return $location.Substring(0, $location.Length-1) }

  # Otherwise return only the dir name
  $lastindex = [int] $location.lastindexof('\') + 1
  return $location.Substring($lastindex)
}

# Set prompt
function prompt {
    return "[atiq@" + $(If ($Env:IsWorkMachine -eq 'True') { 'fb' } Else { 'matrix' }) + " $(get-diralias($(get-location))]$ "
}
