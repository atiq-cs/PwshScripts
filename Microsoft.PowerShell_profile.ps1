<#
.SYNOPSIS
Initialize pwsh environment
.DESCRIPTION
Provide highly optimized methods.

.EXAMPLE

.NOTES

#>

# get the last part of path, consumed by method: `prompt`
function get-diralias ([string] $loc) {
  # check if we are in our home script dir; yes: return grave sign
  if ($loc.Equals($Env:PS_SC_DIR)) { return "~" }
    
  # if it ends with \ that means we are in root of drive
  # in that case return drive
  if ($loc.EndsWith("\")) { return $loc.Substring(0, $loc.Length-1) }
  # for ref
  #if (($lastindex = [int] $loc.lastindexof('\')) -ne -1) { return $loc.Substring(0, $lastindex) }
    
  # Otherwise return only the dir name
  $lastindex = [int] $loc.lastindexof('\') + 1
  return $loc.Substring($lastindex)
}

# Set prompt
function prompt {
    return "[atiq@" + $(If ($Env:IsWorkMachine -eq 'True') { 'fb' } Else { 'matrix' }) + " $(get-diralias($(get-location)))]$ "
}

$Env:PS_SC_DIR = 'D:\pwsh-scripts'
