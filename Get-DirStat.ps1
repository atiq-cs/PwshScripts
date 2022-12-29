<#
.SYNOPSIS
  Get information on directories under this directory.
.DESCRIPTION
  At present, supports following,
  - Count number of files in a dir
  - Get Dir Sizes in Megabytes

.PARAMETER Type
  Kind of information we want to get using this script

.EXAMPLE
  $ Get-DirStat.ps1 -InputDir D:\theatre\Shows -Type Size
  Name                                            Size
  ----                                            ----
  ER.1994.S01.web.HET                          6050.46
  House.2004.S01.HET                           4989.17
  Cosmos Possible Worlds 2020.S01.web          3626.41
  Once.Upon.A.Time.psarip.720p.hdtv.2ch.psarip 3543.44
  Dexter.S01.HET                               3365.31
  Jane.the.Virgin 2014.S01.HD                  3237.94
  The.Haunting.Of.Hill.House.S01.HET           2981.96
  The Witcher 2019.S01.web.NF.HET              2467.35
  Home Before Dark 2020.S01.web                2258.12
  The.Legend.of.Korra.S01.HET                  1489.31
  SV.S06.web                                   1255.44
  Undone.S01.web.HET                            942.97
  Archer.S01.HET                                890.21
  LWT.S07.web                                   653.92
  SouthPark                                     330.23

  $ Get-DirStat.ps1 -InputDir D:\Code\CS -Type Count
  Name                                         Count
  ----                                         -----
  machinelearning-samples                       4339
  MAUI                                          2416
  WinUI                                         1193
  P03_Mvc_old                                    464
  MediaTool                                      316
  P04_Identity                                   219
  P03_ContosoUniversity_netcore                  185
  P03_ContosoUniversity_mvc                      127
  GitUtility                                     125
  P02_WebApp                                     103
  P01_WebApp                                     100
  vNextMT                                         96
  DeepLearning_ImageClassification_TensorFlow2    61
  CS-ConsoleApp-Template                          56
  crypto                                          40
  PSScript                                        13
  blackjack                                        5

.NOTES
Handy for cleaning up large directories from an HDD

**Refs**
- https://devblogs.microsoft.com/scripting/getting-directory-sizes-in-powershell
- Original script from Article above is retained by Konstantin Taranov here,
     https://github.com/ktaranov/powershell-kit/blob/master/Scripts/Get-DirStats.ps1

tag: windows-only, file-system
#>

[CmdletBinding()] Param (
  [Parameter(Mandatory=$true)] [string] $InputDir,
  [ValidateSet('Size', 'Count')] [string] $Type = 'Count'
)

# Entry Point Function
function Main() {
  switch( $Type ) {
  'Size' {
    $dirStat = foreach ($item in Get-ChildItem -Directory -Force $InputDir) {
      $sizeBytes = (Get-ChildItem -Recurse -File -Force $item | Measure-Object -Sum -Property Length).Sum

      New-Object PSObject -Property @{
          Name             = $item.Name
          Size             = $sizeBytes / 1MB
      }
    }

    $dirStat | Sort-Object -Property Size -Descending | Format-Table -Property Name, Size
  }
  'Count' {
    $dirStat = foreach ($item in Get-ChildItem -Directory -Force $InputDir) {
      $count = (Get-ChildItem -Recurse -File -Force $item | Measure-Object).Count

      New-Object PSObject -Property @{
          Name             = $item.Name
          Count             = $count
      }
    }

    $dirStat | Sort-Object -Property Count -Descending | Format-Table -Property Name, Count
  }
  default {
    'Unexpected argument!'
  }
  }
}

Main
