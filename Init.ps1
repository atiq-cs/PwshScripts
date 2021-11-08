<#
.SYNOPSIS
  Minimal Initialization Script for Powershell 7 Environment
.DESCRIPTION
 
.EXAMPLE
  pwsh -NoExit -NoLogo -File D:\pwsh-scripts\Init.ps1

.NOTES
  Verify defined vars in $PROFILE

  Defaulting to old way: change color from property for color initialization, using RGB Color:
    {1, 32, 72}

  Run only for choco init / admin,
  Set $Env:ChocolateyInstall, ChocolateyToolsLocation

  Deps,
  - $PwshScriptDir
  - $PFilesX64Dir
  - $PFilesX86Dir
#>

# Update repository using libgit2sharp
function UpdateRepo() {
  $GitUtilPath = 'D:\git_ws\GitUtility'
  Write-Host -NoNewline "Git Utility: "
  dotnet run --project $GitUtilPath pull
  # git pull origin master
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
- Code
- Vpn connect and disconnect
- fbit-admin
- KeePass
- Notepad++
- pwsh
- Sgdm (DiffMerge)
- WinMerge

-- Deprecated or Unused --
- DevEnv
- CodeFB
- Messenger
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
  dialog box for init won't appear to bother us again! Tools is deprecated by
  ChocolateyToolsLocation

.EXAMPLE
  .\Init
.NOTES
  Refs,
  - https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet
#>

function Main() {
  .\Init-App resetEnvPath
  # Init-App git-cmd
  Init-App dotnet

  'pwsh ' + [string] $PSVersionTable.PSVersion + ' on ' + [string] $PSVersionTable.OS
  Write-Host ' '

  InitConsoleUI
  UpdateRepo

  ShowHelp
}

Main