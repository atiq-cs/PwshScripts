<#
.SYNOPSIS
  Renames files and dirs required for wordpress export project
.DESCRIPTION

.PARAMETER SourceDir
  TODO: Implement
.EXAMPLE
  WP-Export-FixFS.ps1

.NOTES
  Implements `isNumeric`
#>

function isNumeric ($x) {
  $x2 = 0
  $isNum = [System.Int32]::TryParse($x, [ref]$x2)
  return $isNum
}

function Main() {
  $InputDir = 'D:\git_ws\mm\enblog\input\posts'
  Push-Location $InputDir

  foreach ($item in Get-ChildItem . -Attributes !Directory) {
    $year = $item.BaseName.Substring(0,4)

    if (isNumeric $year) {
      if (! (Test-Path $year)) {
        New-Item -ItemType Directory $year
      }

      $OutFilePath = ($InputDir + '\' + $year + '\' + $item.BaseName.Substring(5) + $item.Extension)
      if (Test-Path $OutFilePath) {
        $OutFilePath + ' already exists!'
      }
      else {
        'Moved ' + $OutFilePath
        Move-Item $item $OutFilePath
      }
    }
  }

  Pop-Location
}

Main
