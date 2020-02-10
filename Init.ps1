<#
.SYNOPSIS
Minimal Initialization Script for Powershell Core Environment
.DESCRIPTION
 
.EXAMPLE
 pwsh -NoExit Init.ps1

.NOTES
Verify defined vars in $PROFILE
Add support for arg ' ML' to `Init-App` script

Defaulting to old ways for color initialization, using RGB Color: {1, 32, 72}

Run only first time,
Set $Env:ChocolateyInstall, ChocolateyToolsLocation

Deps,
- $PwshScriptDir
- $PFilesX64Dir
- $PFilesX86Dir
#>

##########################  Function Definition Starts  ##########################
################################################################################
# Currently only updates fftsys repository using git
function UpdateCoreRepo() {
  bin\GitUtil --repo-path $PWD.Path --action pullMaster
  # git pull origin master
  Write-Host "GitUtil: Code updated silently, otherwise expect exception from core framework"
}

<#
.SYNOPSIS
Settings for Home or Work or any other place to personalize the console UI
.DESCRIPTION
Minimal init for Console UI
.EXAMPLE
InitConsoleUI
#>
function InitConsoleUI() {
  (Get-Host).UI.RawUI.WindowTitle = $(if ($PHOST_TYPE -Eq 'office' ) { "FB Workstation" } else { "Matrix Workstation" })
}

# Brief help
function ShowHelp() {
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
- Notepad++
- Sgdm (DiffMerge)
- Skype
- WinRar
- Workchat
"
}

##########################  Function Definition Ends  ##########################
################################################################################


function Main() {
  .\Init-App resetEnvPath
  InitConsoleUI
  # UpdateCoreRepo
  # StartCustomPrcoesses

  ShowHelp
}

Main