<#
.SYNOPSIS
  Dotnet CLI Helper Utility
.DESCRIPTION
  Update nuget packages
  Supports pre-release (alpha/beta) versions

.PARAMETER UpdatePackages
  update nuget packages

.EXAMPLE
  Dotnet-Util.ps1 Update-Packages
  Dotnet-Util.ps1 Update-Packages -PreRelease

.NOTES
demos following,
- regex expression match
- new switch syntax

tag: cross-platform, dotnet
#>

[CmdletBinding()] Param (
  [Parameter(Mandatory=$true)] [ValidateSet('Update-Packages', 'Clean')] [string] $Action,
  [string] $Path = '.',
  [switch] $PreRelease)


function UpdatePackages() {
  # one liner if else example
  'Updating packages to ' + $( if ($PreRelease) {'pre-release'} else {'stable'} )

  $regex = 'PackageReference Include="([^"]*)" Version="([^"]*)"'

  ForEach ($file in Get-ChildItem $Path -Recurse | Where-Object {$_.extension -like "*proj"}) {
      $packages = Get-Content $file.FullName |
          Select-String -pattern $regex -AllMatches | 
          ForEach-Object {$_.Matches} | 
          ForEach-Object {$_.Groups[1].Value.ToString()} |
          Sort-Object -Unique

      ForEach ($package in $packages) {
          Write-Host "Update $file package :$package" -foreground 'magenta'
          $fullName = $file.FullName
          Invoke-Expression ("dotnet add $fullName package $package" + $( if ($PreRelease) {' --prerelease'} ))
      }
  }
}


<#
.SYNOPSIS
  Clean dotnet projects, recurse

.NOTES
  Ref Cmd online in a numbr of sources,
  Get-ChildItem -Include bin,obj -Recurse | Remove-Item -Recurse -Force
#>

function CleanProjects() {
  foreach ($item in Get-ChildItem -Recurse $Path -Include bin,obj) {
    Remove-Item -Recurse -Force $item
  }
}

# Start of Main function
function Main() {
  'Current Path: ' + $Path

  switch ($Action) {
      "Update-Packages" { UpdatePackages }
      "Clean" { CleanProjects }
  }
}

Main
