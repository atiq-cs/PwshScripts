<#
.SYNOPSIS
Initialize Powershell Core Environment
.DESCRIPTION
 
.PARAMETER psConsoleType
Console type: for future use, `Init-App` replaces it for now.

.EXAMPLE
 pwsh -NoExit Init.ps1

.NOTES
Requires $Env: Vars,
- PwshScriptDir
- PHOST_TYPE

Obviates use of following vars,
- NET_STATUS
- netstatfile

These (above) are required mostly in countries where internet is flaky or unstable.

`SingleInstanceRunning` is used to,
- avoid strings are not appended multiple times
- only run gadgets for first instance and git update
#>

param(
    [string]
    $psConsoleType = ''
)

<#
.SYNOPSIS
Set Location to home dir
.EXAMPLE
just method name
#>
function InitializeScript() {
  cd $Env:PwshScriptDir
  # Set up variables for Program Files, ToDo: generalize
  $Env:PFilesX64 = 'D:\PFiles_x64\choco'
  $Env:PFilesX86 = 'D:\PFiles_x86\choco'
}

function ResizeConsole([string] $title, [int] $history_size, [int] $width, [int] $height) {
  # Get console UI
  $cUI = (Get-Host).UI.RawUI

  $cUI.WindowTitle = $title
  # Debug
  # Write-Host "Requested height " $height " width " $width " buffer size " $history_size

  # change buffer size first, because next dim change depends on it
  <#$b = $cUI.BufferSize
  $b.Width = $width
  $b.Height = $history_size
  $cUI.BufferSize = $b #>
  # Sometimes, Window Size and buffer size conflict because window size cannot be bigger than buffer size, swapping the statements help
  # Seems like it also requires fixing the console.lnk shortcut in the system
  (Get-Host).UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size -Property @{Width=$width; Height=$history_size}
  (Get-Host).UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size -Property @{Width=$width; Height=$height}

  # change window height and width
  <# $b = $cUI.WindowSize
  $b.Width = $width
  $b.Height = $height
  $cUI.WindowSize = $b #>
}

<#
.SYNOPSIS
Settings for Home or Work or any other place
.DESCRIPTION
When a new test is added int the test API, create a new test on the portal with the url to execute the test. When a test is removed, disable it on the azure portal.
.PARAMETER IsWorkPlace
Need to be changed if we want to support more workstations.
.EXAMPLE
ApplySettings
ApplySettings $true
#>
function ApplySettings([bool] $IsWorkPlace = $false) {
  # As we are getting "Unable to modify shortcut error", doing this from here; run only in office, I can't change the console properties in Win8 there
  # if ($Env:SESSIONNAME -And $Env:SESSIONNAME.StartsWith('RDP')) { }
  # if ($PSVersionTable.PSEdition -eq 'Core') { }
  $screen_width = 3840
  $screen_height = 2160

  # Get display proportionat size: CurrentHorizontalResolution, CurrentVerticalResolution
  # Since NVidia CUDA installation and driver updates we now have more than one video controller
	# Handle cases that some systems only have one Video Display
  # Only Powershell (Windows Desktop) has GWMI
  if ($PSVersionTable.PSEdition -eq 'Desktop') {
	  $screen_obj = (GWMI win32_videocontroller)[0]
	  if (! $screen_obj) { $screen_obj = (GWMI win32_videocontroller) }
    $screen_width = [convert]::ToInt32([string] ($screen_obj.CurrentHorizontalResolution))
    $screen_height = [convert]::ToInt32([string] ($screen_obj.CurrentVerticalResolution))
  }

  # 10 24 is okay for aspect ratio 16:9
  # 9 22 for 1366x768

  # Resolution: 1920x1080, default aspect ratio, approx result: 198, 33.75
  # This resolution should not be default anymore
  if ($screen_height -eq 1080 -And $screen_width -eq 1920) {
    $console_width = $screen_width/8.27586206896552
    $console_height = $screen_height/32
  }
  # Aspect Ratio: 5:4 - HSL library monitor, approx result 155, 40
  elseif (($screen_height*5) -eq ($screen_width*4)) {
    $console_width = [int] ($screen_width/10)
    $console_height = [int] ($screen_height/21)
  }
  # Current notebook: 3840x2160, aspect ratio (16:9), expected result approx, 294 37
  else {
    $console_width = $screen_width/13
    $console_height = $screen_height/59
  }

  # Write-Host "debug width $screen_width height $screen_height"
  # Write-Host "debug width $console_width height $console_height"
  $WSTitle = $(if ($psConsoleType -eq 'ML' ) { "Machine Learning Workstation" } else { $(if ($IsWorkPlace) { "FB Workstation" } else { "Matrix Workstation" }) })
  ResizeConsole $WSTitle 9999 $console_width $console_height
  Write-Host -NoNewline "Applying settings on "
  Write-Host -NoNewline $WSTitle -foregroundcolor Blue
  # ref https://stackoverflow.com/q/2085744
  Write-Host " for" $Env:UserName "`r`n"
}

# Currently only updates fftsys repository using git
function UpdateCoreRepo() {
  # git pull origin master
  Write-Host "Use Git Util instead."
}

# This should be improved
function StartCustomPrcoesses() {
  # Shame this 64 bit chrome is installed in 32 bit program files
  Start-Process-Single 'Chrome' 'Google Chrome' ''
  Start-Process-Single 'Notepad++' 'Notepad++' ''
  Start-Process-Single 'Outlook' 'MS Outlook' ''
}

# Support for IsRegAppPath = False, not required anymore
function Start-Process-Single([string] $ProcessRunCommand, [string] $ProcessName, [string] $ProcessPath, [bool] $IsRegAppPath = $true, [string[]] $pArgs) {
  if (Get-Process $ProcessRunCommand -ErrorAction SilentlyContinue) {
    Write-Host "$ProcessName is already running"
  }
  elseif ($IsRegAppPath) {
    Write-Host "Starting $ProcessName"
    # this for fb dev-vm
    if ($ProcessRunCommand -eq 'chrome') { Start-Process $ProcessRunCommand --ignore-certificate-errors }
    else { Start-Process $ProcessRunCommand }
    # some time for monster chrome to consume resources
    if ($ProcessRunCommand -eq 'chrome') { Start-Sleep 2 }
  }
  elseif ((Test-Path "$ProcessPath")) {
    Write-Host "Starting $ProcessName"
	if ($pArgs) { Start-Process -FilePath $ProcessPath -ArgumentList $pArgs }
	else {Start-Process $ProcessPath}
  }
  else {
    Write-Host "$ProcessName is not installed."
  }
}

[bool] $isSinglePS=$false
function SingleInstanceRunning([string] $processName)
{
  $isSinglePS = $Global:isSinglePS
  if ($isSinglePS) {
    return $isSinglePS
  }
  if (GetProcessInstanceNumber $processName -lt 2) {
    $isSinglePS = $true
  }
  $Global:isSinglePS = $isSinglePS
  return $isSinglePS
}

# Get number of instances of a process
function GetProcessInstanceNumber([string] $process)
{
  @(Get-Process $process -ErrorAction 0).Count
}

# Brief help
function ShowHelp {
  Write-Host "
SAOS Enterprise users only: pivileged, no 2fac.
Operating System Kernel Build
Net Core Build
PW Shell Version

Supported additional application paths,
- Chrome
- Code
- CVpn-Client
- DevEnv
- KeePass
- notepad++
- sgdm (DiffMerge)
- Skype
- WinRar
- Workchat
"
}

#####################    Function Definition Ends       #####################################
#######################################################################################################

function Main() {
  InitializeScript
  .\Init-App resetEnvPath

  if (SingleInstanceRunning pwsh) {
    # Add pwsh script dir to Path
    .\Init-App pwsh
  }
  else {
    $n = GetProcessInstanceNumber 'pwsh'
    Write-Host -NoNewline "Initializing powershell instance $n.."
  }

  ApplySettings $($Env:PHOST_TYPE -eq 'Office')

  if (SingleInstanceRunning) {
    # Update Repository
    UpdateCoreRepo
    # for some reason it keeps failing if I put it after 'ss help'
    if ($psConsoleType -eq 'ML') {
      # ToDo: remove hardcoded
      .\Init-App python
    }

    # Start other most frequently opened processes
    StartCustomPrcoesses
  }
  else {
    Write-Host  "`t`t`[Ready`]"
  }

  ShowHelp
}

Main
