<#
.SYNOPSIS
Start FB App
.DESCRIPTION
To Launch a new shell utilize `New-Shell` script.

ToDo: Utilize split-path
ToDo: replace InitFBEnvironment with a lite-weight demon or app which sleeps most of the time..

This application can be considered as an extension to `Start-Process` cmdlet. We perform
initializations for some of the applications right before calling `Start-Process`.

Attributes of processes to consider,
- fb process (requires fb related initialization)
- verbosity of the app

types,
1: non-verbose, non-fb
2: verbose, non-fb i.e, VSCode
3: verbose, fb i.e, FBCode

ToDo: support argument list

.PARAMETER AppName
name of app for which to init
.EXAMPLE

.NOTES
targetting apps i.e., WorkChat, WhatsApp, 

If Verbose is specified open a debug Window and redirect out

Later, retrieve these values from a dictionary
 - try this later

Required following Env Vars,
 - $PFilesX64Dir

* Sometimes the `pwsh` shell can malfunction when all Start-Process calls might be dangled!

ref,
- https://stackoverflow.com/questions/49375418/start-process-redirect-output-to-null
- https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/start-process
- [Parameter Splatting](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_splatting)
- [Split-Path](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/split-path)

Reference on how to use these path vars,
 https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_environment_variables
#>

[CmdletBinding()] Param (
  # [ValidateSet('app name')] - list is large
  [Parameter(Mandatory=$true)] [string] $AppName,
  [bool] $SkipCCCert = $False
)

# copied from Init-App
function AddToEnvPath([string] $path = ';') {
  if (! (Test-Path $path)) {
    Write-Host "Not valid path: $path"
    return
  }
  if ($Env:Path.Contains($path) -Eq $False) {
    $Env:Path += ';' + $path
  }
}

function InitFBEnvironment([string] $authToken = '') {
  # required to set only once across all pwsh instances
  $Env:ChocolateyToolsLocation = 'D:\PFiles_x64\chocolatey\tools'
  # this is required for all FB App Launches
  AddToEnvPath $Env:ChocolateyToolsLocation

  <#
  # renew authentication
  $CCCertsExe = $Env:ChocolateyToolsLocation + '\cc-certs.exe'
  if (!(Test-Path $CCCertsExe)) {
    Write-Host 'cc-cert binary is not found!'
    return
  }

  Write-Host -NoNewline 'Waiting for status from cc-certs..'
  $authStatus = 'expired'
  $elapsedTimeMS = (Measure-Command { $authStatus = (& $CCCertsExe -cert_expirations -cert_list `
    ssh-user | ConvertFrom-Json).'ssh-user' }).TotalMilliseconds

  if ($authStatus -Eq 'expired') {
    Write-Host -ForegroundColor Red ' Authentication token expired!'

    $ConfigName = 'devvm-fb1'
    $hostName = Get-ItemPropertyValue ('HKCU:Software\SimonTatham\PuTTY\Sessions\' + 
        $ConfigName) -Name HostName

    if (! (Test-Connection $hostName -Count 1 -ErrorAction SilentlyContinue)) {
        Write-Host -ForegroundColor Red 'We need to be on CorpNet to renew cert.'
        return 
    }

    if ($authToken -Eq '') { $authToken = Read-Host "Please enter duo push" }
    else { $authToken = $authToken }

    & $CCCertsExe -cert_list x509-user,ssh-user,x509-presto,x509-mysql -duo_pass $authToken
  }
  else {
    $ts = [timespan]::fromseconds([int] $authStatus)
    # Measure-command requires 
    Write-Host ("`rcc-cert expires in: " + ("{0:hh\:mm\:ss}" -f $ts) + ' elapsed ' + $elapsedTimeMS + 'ms')
  }
  #>

  'cc-certs is deprecated. Use Sks Agent instead.'
}


<#
.SYNOPSIS
Facilitates restoring Env Path Variable
.DESCRIPTION
Modify Env Path

Worflow should be,
based on 
.PARAMETER NewPath
Value for the Env Var
.EXAMPLE
SetEnvPath $oldPathValue
.NOTES
#>
function SetEnvPath([string] $NewPath) {
  if ($Env:Path -Ne $NewPath) {
    $Env:Path = $NewPath
  }
}

<#
.SYNOPSIS
Second Method of this Script
.DESCRIPTION
Start Microsoft Store App

The cmdlet does not support arguments for Store App URI yet. Hence, we invoke them in a new Window
.PARAMETER AppName
Store App URI
.EXAMPLE
LaunchAppEx Messenger:
.NOTES
TODO: deprecate this use Start-Process directly instead
However, for debugging purpose we might need to do a small script to launch
process with redirect standard out / err set.

ToDo: don't InitFB Environment here instead build a lite weight tool
Temporary implementation, should be replaced by use of Dictionary
Later, we would need args support just like `Start-Process` cmdlet

For debug, utilize,
 '-NoExit', 
#>
function LaunchAppEx([string] $AppName) {
  if (! $AppName.EndsWith(':')) { return $False }

  Start-Process pwsh -ArgumentList '-NoLogo', '-Command', ( 'Start ' + "$AppName" ) -ErrorAction 'Stop'

  return $True
}


<#
.SYNOPSIS
Most important function of this Script
.DESCRIPTION
Modify Env Path

Worflow should be,
based on 
.PARAMETER AppName
Customized init for Apps
.EXAMPLE
StartProcess Code
.NOTES
 - Modifies Env Path
Temporary implementation: should be replaced by use of Dictionary
Later, we would need args support just like `Start-Process` cmdlet

TODO: override $AppName to actual name for some apps.
Right now, we are keeping this generic in Code
#>
function StartProcess([string] $AppName) {
  $pathKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe"
  # default to HKLM
  if (! (Test-Path "$pathKey")) {
    $pathKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe"

    if (! (Test-Path $pathKey)) {
      Write-Host -ForegroundColor Red "Cannot find app:" $AppName "in registry!"
      return
    }
  }

  $BinaryPath = Get-ItemPropertyValue $pathKey -Name `(default`)
  if (! (Test-Path $BinaryPath)) {
    Write-Host -ForegroundColor Red 'Binary not found:' $BinaryPath
    return 
  }

  $BinaryDir = Get-ItemPropertyValue $pathKey -Name Path

  # For Apps that modify Env
  $oldEnvPath = $Env:Path
  switch( $AppName ) {
    'Code' {    # verbose, non-fb, stdout only
      # Later, retrieve these values from a dictionary
      $AppName = 'VSCode'
      # not required: set in json settings file instead
      # Init-App git
      Init-App dotnet
      Init-App git-cmd
      AddToEnvPath($PFilesX64Dir + '\VSCode\bin')
      # Being in home dir location is not required
      $RedirectStandardOutVal = $PwshScriptDir + '\log\' + $AppName + '_out.log'
    }
    'CodeFB' {    # verbose, fb, follows VS Code
      # may require a duo push as well for VSCode and some other apps
      InitFBEnvironment

      # VSCode for FB only, add VS Paths for Insider; not sure if it's important though
      # see if this is really required
      # Managed through AppPathReg
      # previous: $Env:ProgramData + '\nuclide\FB-VSCode-Insiders\bin'
      # current: $Env:LOCALAPPDATA + '\Programs\FB VSCode - Insiders'
      AddToEnvPath($BinaryDir)
      $Env:ChocolateyInstall = 'D:\PFiles_x64\Chocolatey'

      Init-App.ps1 fb-tools $True
      # Init-App.ps1 node $False

      # Add ssh when vscode requires fallback, it might access other binaries in that dir too
      AddToEnvPath($Env:ChocolateyToolsLocation + '\fb.gitbash\usr\bin')

      # Actually, the dev version: 'FB VSCode Insiders'
      # Being in home dir location is not required
      $RedirectStandardOutVal = $PwshScriptDir + '\log\' + $AppName + '_out.log'

      $argList = @('"' + $BinaryDir + '\resources\app\out\cli.js' + '"')
    }
    'Messenger' {    # verbose, fb = Workchat, stdout only
      InitFBEnvironment
      $RedirectStandardOutVal = $PwshScriptDir + '\log\' + $AppName + '_out.log'
    }    
    'WorkChat' {    # verbose, fb, stdout only (stderr 1KB)
      InitFBEnvironment

      # Being in home dir location is not required
      $RedirectStandardOutVal = $PwshScriptDir + '\log\' + $AppName + '_out.log'
    }
    'Signal' {    # non-verbose, non-fb
      $RedirectStandardOutVal = $PwshScriptDir + '\log\' + $AppName + '_out.log'
    }
    'WhatsApp' {    # non-verbose, fb
      InitFBEnvironment
      # $BinaryPath = $Env:LOCALAPPDATA + '\WhatsApp\WhatsApp.exe'
    }
    default {
      'Application from registry: ' + $AppName
    }
  }

  # SetEnvPath($oldEnvPath)
  # if (Test-Path Env:ChocolateyToolsLocation) { Remove-Item Env:ChocolateyToolsLocation }
  
  if ([string]::IsNullOrEmpty($RedirectStandardOutVal) -And [string]::IsNullOrEmpty(
      $RedirectStandardErrVal)) {
    Start-Process -FilePath $BinaryPath -WorkingDirectory $BinaryDir
  }
  elseif ([string]::IsNullOrEmpty($RedirectStandardErrVal)) { # vscode, CodeFB
  if ($argList) { # this argList support for code-fb does not seem to be useful, get rid of later
      if ($AppName.Equals('CodeFB')) {
        $Env:ELECTRON_RUN_AS_NODE='1'
        Start-Process -FilePath $BinaryPath -WorkingDirectory $BinaryDir -RedirectStandardOutput `
          $RedirectStandardOutVal -ArgumentList $argList
        # Unset the variable now
        [Environment]::SetEnvironmentVariable("ELECTRON_RUN_AS_NODE", $null, "User")
      }
    }
    else {
      # not required to surround with spaces even if there is space in path string
      Start-Process -FilePath $BinaryPath -WorkingDirectory $BinaryDir -RedirectStandardOutput `
        $RedirectStandardOutVal
    }
  }
  elseif ([string]::IsNullOrEmpty($RedirectStandardOutVal)) {
    Start-Process -FilePath $BinaryPath -WorkingDirectory $BinaryDir -RedirectStandardError `
      $RedirectStandardErrVal    
  }
  else {
    Start-Process -FilePath $BinaryPath -WorkingDirectory $BinaryDir -RedirectStandardError `
      $RedirectStandardErrVal -RedirectStandardOutput $RedirectStandardOutVal
  }

  SetEnvPath($oldEnvPath)
}

if (LaunchAppEx $AppName) { return }
else                      { StartProcess $AppName }
