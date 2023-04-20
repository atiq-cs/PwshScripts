<#
.SYNOPSIS
  Clean cpp projects
.DESCRIPTION
  Cleanup cpp project per source file

.PARAMETER Type
  Project Language Type

.EXAMPLE
  dev\clean.ps1 D:\code\cpp\App


.NOTES
Handy for cleaning up large directories from an HDD

Demonstrates
- Array passing to functions

**Refs**
- https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-arrays

tag: windows-only, visual-studio
#>

[CmdletBinding()] Param (
  [Parameter(Mandatory=$true)] [string] $InputDir,
  [ValidateSet('cpp', 'csharp')] [string] $Type = 'cpp'
)

<#
.SYNOPSIS
  Given source file name and file extensions list, perform cleanup
.DESCRIPTION
  Straight forward clean up

.PARAMETER FName
  Source file name

.PARAMETER FExts
  Extension list pertinent to the source files
#>

function CleanSourceObjects([string] $FName, [string[]] $FExts) {
  $sourceObjFullNameWithoutExt = $InputDir + '\x64\Release\' + $FName

  foreach ($ext in $FExts) {
    $sourceObjFullName = $sourceObjFullNameWithoutExt + '.' + $ext

    if (Test-Path $sourceObjFullName) {
      ' ' + $sourceObjFullName
      Remove-item $sourceObjFullName
    }
  }
}

# Entry Point Function
function Main() {
  if ($InputDir.EndsWith('\')) {
    $InputDir = $InputDir.Substring(0, $InputDir.Length-1)
  }

  switch( $Type ) {
  'cpp' {
    'Main source file related objects cleanup:'

    $sourceObjExts = @(
        'exe'
        'ilk'
        'obj'
        'iobj'
        'ipdb'
        'pdb'
      )

    # TODO: take this from params
    CleanSourceObjects 'Main' $sourceObjExts
    "`n"

    $sourceObjExts = @('obj')
    'Source files temp objects cleanup:'
    #  -Include *.cpp doesn't work
    foreach ($item in Get-ChildItem -Force $InputDir\*.cpp) {
      CleanSourceObjects $item.BaseName $sourceObjExts
    }
    "`n"

    'VC objects cleanup:'
    $sourceObjExts = @('pdb')
    CleanSourceObjects 'vc143' $sourceObjExts
  }
  default {
    'Unexpected argument!'
  }
  }
}

Main
