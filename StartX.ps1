<#
.SYNOPSIS
Start FB App
.DESCRIPTION
ToDo: utlize split-path

This application can be considered as an extension to Start-Process cmdlet. We perform
initializations for some of the applications.

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

function InitFBEnvironment([string] $authTokenFromVpn = '') {
  # required to set only once across all pwsh instances
  $Env:ChocolateyToolsLocation = 'D:\PFiles_x64\chocolatey\tools'
  # this is required for all FB App Launches
  AddToEnvPath $Env:ChocolateyToolsLocation

  # renew authentication
  $CCCertsExe = $Env:ChocolateyToolsLocation + '\cc-certs.exe'
  if (!(Test-Path $CCCertsExe)) {
    Write-Host 'cc-cert binary is not found!'
    exit
  }
  $authStatus = (& $CCCertsExe -cert_expirations -cert_list ssh-user | ConvertFrom-Json).'ssh-user'
  if ($authStatus -Eq 'expired') {
    Write-Host -ForegroundColor Red ' Authentication token expired!'

    $ConfigName = 'devvm-fb1'
    $hostName = Get-ItemPropertyValue ('HKCU:Software\SimonTatham\PuTTY\Sessions\' + 
        $ConfigName) -Name HostName

    if (! (Test-Connection $hostName -Count 1)) {
        Write-Host -ForegroundColor Red 'We need to be on CorpNet to renew cert.'
        exit
    }

    if ($authTokenFromVpn -Eq '') { $authToken = Read-Host "Please enter duo push" }
    else { $authToken = $authTokenFromVpn }

    & $CCCertsExe -cert_list x509-user,ssh-user,x509-presto,x509-mysql -duo_pass $authToken
  }
  else {
    $ts = [timespan]::fromseconds([int] $authStatus)
    'cc-cert expires in: ' + ("{0:hh\:mm\:ss}" -f $ts)
  }
}

function RunHotCmd([string] $AppName) {
  # For apps that are just short cut commands
  switch( $AppName ) {
    'pwsh' { # elevated
      Start-Process pwsh -ArgumentList '-NoExit', 'Init-App.ps1 admin' -Verb Runas -ErrorAction 'stop'
    }
    default {
      return $False
    }
  }
  return $True
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
Temporary implementation, should be replaced by use of Dictionary
Later, we would need args support just like `Start-Process` cmdlet

can override $AppName to actual name for some apps, right now, we are only doing
this for `Code`

### CVpn-Connect Refs

  .\AppPathReg CVpn (${Env:ProgramFiles(x86)} + '\Cisco\Cisco AnyConnect Secure Mobility Client\vpncli.exe')
vpn tool draft cmd,

  "connect `"Profile Name`"`r`n `r`nexit" | & "${Env:ProgramFiles(x86)}\Cisco\Cisco AnyConnect Secure Mobility Client\vpncli.exe" -s

From `COMSPEC`,
    
  vpncli.exe -s < anyconnect.txt

The redirection case for powershell
- [reddit](https://www.reddit.com/r/PowerShell/comments/10kz2v/input_redirection_to_executable)

sound a beep after connection is verified

Beep() ref,
https://devblogs.microsoft.com/scripting/powertip-use-powershell-to-send-beep-to-console
https://docs.microsoft.com/en-us/dotnet/api/system.console.beep?view=netframework-4.8

old doc, vpn manual,
https://docstore.mik.ua/univercd/cc/td/doc/product/vpn/client/3_6/admin_gd/vcach4.htm
#>
function StartProcess([string] $AppName) {
  $VPNAppName = 'CVpn'

  if ($AppName.StartsWith($VPNAppName)) {
    $prevAppName = $AppName
    $AppName = $VPNAppName
  }

  $pathKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe"
  # default to HKLM
  if (! (Test-Path "$pathKey")) {
    $pathKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$AppName.exe"

    if (! (Test-Path $pathKey)) {
      Write-Host -ForegroundColor Red "Cannot find app:" $AppName "in registry!"
      return
    }
  }

  if ($AppName.StartsWith($VPNAppName)) { $AppName = $prevAppName }

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
      Init-App git
      AddToEnvPath($PFilesX64Dir + '\VSCode\bin')
      # Being in home dir location is not required
      $RedirectStandardOutVal = $PwshScriptDir + '\log\' + $AppName + '_out.log'
    }
    'CodeFB' {    # verbose, fb, follows VS Code
      # may require a duo push as well for VSCode and some other apps
      InitFBEnvironment

      # VSCode for FB only, add VS Paths for Insider; not sure if it's important though
      # see if this is really required
      AddToEnvPath($Env:ProgramData + '\nuclide\FB-VSCode-Insiders\bin')

      # Add ssh when vscode requires fallback, it might access other binaries in that dir too
      AddToEnvPath($Env:ChocolateyToolsLocation + '\fb.gitbash\usr\bin')

      # Actually, the dev version: 'FB VSCode Insiders'
      # Being in home dir location is not required
      $RedirectStandardOutVal = $PwshScriptDir + '\log\' + $AppName + '_out.log'

      $argList = @($Env:ProgramData + '\nuclide\FB-VSCode-Insiders\resources\app\out\cli.js')
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
    'WhatsApp' {    # non-verbose, fb
      InitFBEnvironment
      # $BinaryPath = $Env:LOCALAPPDATA + '\WhatsApp\WhatsApp.exe'
    }
    'CVpn-Connect' {    # returns after restore path, no Start-Process
      $VPNService = 'VPNAgent'

      if ((Get-Service $VPNService).Status -Eq 'Running') {
        # Gives double new lines [System.Environment]::NewLine
        Write-Host
        $authToken = Read-Host 'Please enter duo push for VPN Auth'

        Push-Location $BinaryDir
        # string containing escape sequence requires double quoting
        ("connect `"Americas West`"`r`n" + $authToken + "`r`nexit") | & $BinaryPath -s
        Pop-Location

        InitFBEnvironment

        SetEnvPath($oldEnvPath)
        Remove-Item Env:ChocolateyToolsLocation
        [Console]::Beep(1024, 128)
      }
      else {
        Write-Host -ForegroundColor Red 'Service' $VPNService 'is not running!'
      }
      return
    }
    'CVpn-Disconnect' {    # returns after restore path, no Start-Process
      $VPNService = 'VPNAgent'

      if ((Get-Service $VPNService).Status -Eq 'Running') {
        Push-Location $BinaryDir
        & $BinaryPath disconnect
        Pop-Location
        [Console]::Beep(2048, 64)
        'Feel free to release service ''' + $VPNService + '''!'
      }
      return
    }
    default {
      'Invalid command line argument: ' + $AppName
      return
    }
  }

  SetEnvPath($oldEnvPath)
  if (Test-Path Env:ChocolateyToolsLocation) { Remove-Item Env:ChocolateyToolsLocation }
  
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
      # Start-Process -FilePath "$BinaryPath" -WorkingDirectory "$BinaryDir" 
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

if ((RunHotCmd $AppName) -Eq $False) {
  StartProcess $AppName
}
