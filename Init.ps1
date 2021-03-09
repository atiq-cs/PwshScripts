<#
.SYNOPSIS
Minimal Initialization Script for Powershell Core Environment
.DESCRIPTION
 
.EXAMPLE
 pwsh -NoExit -NoLogo -File D:\pwsh-scripts\Init.ps1


.NOTES
Verify defined vars in $PROFILE
Add support for arg ' ML' to `Init-App` script

Defaulting to old way: change color from property for color initialization, using RGB Color:
  {1, 32, 72}

Run only first time,
Set $Env:ChocolateyInstall, ChocolateyToolsLocation

Deps,
- $PwshScriptDir
- $PFilesX64Dir
- $PFilesX86Dir
#>

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
  (Get-Host).UI.RawUI.WindowTitle = $(if ($PHOST_TYPE -Eq 'office' ) { "FB Terminal" } else { "Matrix Terminal" })
}

# Brief help
function ShowHelp() {
  Write-Host '
Startx Apps,
- Chrome
- CodeFB
- Code
- CVpn-Connect and Disconnect
- DevEnv
- KeePass
- Messenger
- Notepad++
- Sgdm (DiffMerge)
- WhatsApp
- Workchat
'
}

<#
.SYNOPSIS
The Main Method that calls initialization components
.DESCRIPTION
Modify Env Path

Adding 'C:\Tools' Usually not required: do a cc-certs renewal based on expiration value and the
dialog box for init won't appear to bother us again! Tools is deprecated by ChocolateyToolsLocation

.EXAMPLE
.\Init
.NOTES
Refs,
- https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet
#>

function Main() {
  
  .\Init-App resetEnvPath
  Init-App git-cmd
  Init-App dotnet

  'Powershell Core ' + [string] $PSVersionTable.PSVersion + ' on ' + [string] $PSVersionTable.OS
  Write-Host ' '

  InitConsoleUI
  UpdateCoreRepo
  # StartCustomPrcoesses

  ShowHelp
}

Main