<#
.SYNOPSIS
  Dotnet CLI helper utility
.DESCRIPTION
  Update nuget packages
  Supports pre-release (alpha/beta) versions

.PARAMETER UpdatePackages
  update nuget packages

.EXAMPLE
  Dotnet-Util.ps1 Update-Packages
  Dotnet-Util.ps1 Update-Packages -PreRelease

.NOTES

tag: cross-platform
#>

[CmdletBinding()] Param (
  [Parameter(Mandatory=$true)] [ValidateSet('Update-Packages')] [string] $Action,
  [switch] $PreRelease)

# Start of Main function
function Main() {
  # debug
  # ('Value of action ' + $Action)

  # one liner if else example
  'Updating packages to ' + (&{ if ($PreRelease) {'stable'} else {'pre-release'} })


  $regex = 'PackageReference Include="([^"]*)" Version="([^"]*)"'

  ForEach ($file in get-childitem . -recurse | Where-Object {$_.extension -like "*proj"}) {
      $packages = Get-Content $file.FullName |
          select-string -pattern $regex -AllMatches | 
          ForEach-Object {$_.Matches} | 
          ForEach-Object {$_.Groups[1].Value.ToString()}| 
          Sort-Object -Unique

      ForEach ($package in $packages) {
          write-host "Update $file package :$package"  -foreground 'magenta'
          $fullName = $file.FullName
          Invoke-Expression ("dotnet add $fullName package $package" + (&{ if ($PreRelease) {' --prerelease'} }))
      }
  }
}

Main
