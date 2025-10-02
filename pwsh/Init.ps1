<#
.SYNOPSIS
  Minimal Initialization Script for Powershell 7 Environment
.DESCRIPTION
 
.EXAMPLE
  pwsh -NoExit -NoLogo -File D:\pwsh-scripts\Init.ps1

.NOTES
  Verify defined vars in $PROFILE

  Defaulting to old way: change bg color from property for color initialization, using RGB Color:
    {1, 28, 64}

  Run only for choco init / admin,
  Set $Env:ChocolateyInstall, ChocolateyToolsLocation

  Deps,
  - $ShellHome
  - $PFilesX64Dir
  - $PFilesX86Dir
#>

# Update repository using libgit2sharp
function UpdateRepo() {
  $GitUtilPath = 'D:\Code\CS\GitUtility'
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
  # $(if ($PHOST_TYPE -Eq 'office' ) { "Qubit Terminal" } else { "Matrix Terminal" })
  # doesn't work on Linux, TODO later
  (Get-Host).UI.RawUI.WindowTitle = 'Legacy Terminal'
}

# Brief help
function ShowHelp() {
  if ($IsWindows) {
    Write-Host '
Startx Apps,
- Code
- Signal

Available Shells,
- kotlin
- Pwsh
- SSH
- dotnet

Reg Apps,
- Chrome
- Notepad++
- WinMerge # Code Built In Diff Tool
- KeePass

-- Deprecated or Unused --
- CodeFB
- Vpn connect and disconnect
- Sgdm (DiffMerge)
- DevEnv   # Code
- Messenger
- WhatsApp
- Workchat
'
  }
}

<#
.SYNOPSIS
  The Main Method that calls initialization components
.DESCRIPTION
  Some shell initializations
  Reset Env Path to clean one

.EXAMPLE
  ./Init

.NOTES
  // Deprecated stuff
  Adding 'C:\Tools' is usually not required: do a cc-certs renewal based on expiration value and the
  dialog box for init won't appear to bother us again! Tools is deprecated by
  ChocolateyToolsLocation

  Refs,
  - https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet
#>

function Main() {
  if ($IsLinux) {
    # Bump up cmd history
    (Get-PSReadlineOption).MaximumHistoryCount = 16384

    ./Init-App resetEnvPath
    # TODO: for Linux
    # Init-App kotlin
    # Init-App dotnet
    # not required for Linux, git exec on /usr/bin takes care of that
    # Init-App git-cmd
  } Else {
    .\Init-App resetEnvPath
    # dotnet parts deprecated in favor of kotlin
    # Init-App kotlin
    # Init-App dotnet
    # VS Code requires git. Hence, default now
    Init-App git-cmd
  }

  'pwsh ' + [string] $PSVersionTable.PSVersion + ' on ' + [string] $PSVersionTable.OS
  Write-Host ' '

  InitConsoleUI
  # TODO: migrate this to kotlin
  # UpdateRepo

  ShowHelp
}

Main