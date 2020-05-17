<#
.SYNOPSIS
Connect to ssh server using putty
.DESCRIPTION
This adds `Start-Process` support for an app
.PARAMETER AppName
name of app to register
.PARAMETER Path
actual binary path
.EXAMPLE
Putty.ps1 -configName devvm-fb1
Putty.ps1 -version $true
Putty.ps1 -serverIP atiq.vm.azure.com -userName atiq
Putty.ps1 -serverIP 192.168.20.38 -u UserName
Putty.ps1 -configName sun-x4600m2-s12_x86
 
.NOTES
it creates `-PropertyType MultiString` if not specified.

Required following Vars,
- $PFilesX64Dir

for debug print,
    Write-Host "$PUTTYEXE -ssh $serverIP -l $userName -pw $pass"

## References
- http://the.earth.li/~sgtatham/putty/0.58/htmldoc/Chapter3.html#using-general-opts
- [Example parameter passing](http://blog.mischel.com/2012/02/03/powershell-parameter-parsing)

tag: cross-platform
#>

Param(
    [string] $configName,
    [string] $serverIP,
    [string] $userName,
    [string] $password,
      [long] $port,
      [bool] $version)

# Start of Main function
function Main() {
    $PUTTYEXE = $PFilesX64Dir + '\Putty\putty.exe'

    if (! (Test-Path -Type Leaf -path $PUTTYEXE)) {
        Write-Host "Please correct putty path and then run the script again.`n"
        exit
    }

    if ([string]::IsNullOrEmpty($configName) -Or ! $configName.Contains('vm-fb')) {
        $hostName = 'google.com'
        if (! (Test-Connection $hostName -Count 1)) {
            Write-Host -ForegroundColor Red 'Cannot connect to ' + $hostName + '!'
            exit
        }
        'Connected to ' + $hostName + '.'
    }


    # Initialize for commandline

    # Allow to login without config
    # Use [string]::IsEmptyOrNull instead
    if (! [string]::IsNullOrEmpty($configName)) {
        if ($configName.Contains('vm-fb')) {
            $hostName = Get-ItemPropertyValue ('HKCU:Software\SimonTatham\PuTTY\Sessions\' + $configName) -Name HostName
            if (! (Test-Connection $hostName -Count 1)) {
                Write-Host -ForegroundColor Red 'Cannot connect to ' + $hostName + '!'
                exit
            }
            'Connected to ' + $hostName + '.'
        }

        Write-Host "Starting putty with default config for $configName."
        # Additionally could utilize
        #  [bool] $(Test-Connection -Count 1 google.com)
        # retrieving servername from registry
        if ($userName.Equals("")) {
            $args =  '-load', $configName
            # $args =  '-ssh', '-2', $serverIP, '-l', $userName, '-pw', $password
            #$args = $serverIP, '-l', $userName, '-pw', $password, '-i', 'D:\Doc\putty.ppk'
            # $args = '-ssh', '-2', $serverIP, '-l', $userName, '-i', 'D:\Doc\putty.ppk'
            
            #  debug print
            # [string]::Join(',', $args)
            Start-Process $PUTTYEXE -ArgumentList $args
        }
        else {
            & $PUTTYEXE -load $configName -l $userName
        }
        exit
    }

    if (! $version.Equals("")) {
        Write-Host "Version info uses pLink"
        $PLINKEXE = "$PFilesX64Dir\Putty\plink.exe"
        & $PLINKEXE -V
        exit
    }

    # server defaults to 192.168.20.38
    if ($serverIP.Equals("")) {
        $serverIP="server.company.com"
        Write-Host "Default server IP $serverIP."
    }

    # User name to root
    if ($userName.Equals("")) {
        if ($HOST_TYPE.Equals("Office")) { $userName=$Env:UserName }
        else { $userName="root" }
        Write-Host "Default user name: $userName."
    }

    # Default port is 22
    if ($port -eq 0) {
        $port="22"
    }

    Write-Host "Opening ssh session with putty: $PUTTYEXE"
    & $PUTTYEXE -ssh -2 $serverIP -l $userName -P $port
}

Main
