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
Putty.ps1 -l devvm-fb1
Putty.ps1 -V $True
Putty.ps1 -s 192.168.20.38 -u UserName
Putty.ps1 -l sun-x4600m2-s12_x86

.NOTES
Initial write: 01/26/2012

it creates `-PropertyType MultiString` if not specified.

Required following Env Vars,
- $Env:PFilesX64

for debug print,
    Write-Host "$PUTTYEXE -ssh $serverIP -l $username -pw $pass"

## References
- http://the.earth.li/~sgtatham/putty/0.58/htmldoc/Chapter3.html#using-general-opts
- [Example parameter passing](http://blog.mischel.com/2012/02/03/powershell-parameter-parsing)

tag: cross-platform
#>

Param(
    [alias("s")]
    [string] $ServerIP,
    [alias("u")]
    [string] $UserName,
    [alias("p")]
    [long] $Port,
    [alias("l")]
    [string] $ConfigName,
    [alias("V")]
    [bool] $ShowVersion)

# Start of Main function
function Main() {
    $PUTTYEXE = "$Env:PFilesX64\Putty\putty.exe"

    if (! (Test-Path -Type Leaf -path $PUTTYEXE)) {
        Write-Host "Please correct putty path and then run the script again.`n"
        exit
    }



    # initialize for commandline

    # Allow to login without config
    # Use [string]::IsEmptyOrNull instead
    if (! $ConfigName.Equals("")) {
        Write-Host "Starting putty with default config for $ConfigName."
        # Additionally could utilize
        #  [bool] $(Test-Connection -Count 1 google.com)
        # retrieving servername from registry
        if ($UserName.Equals("")) {
            & $PUTTYEXE -load $ConfigName
        }
        else {
            & $PUTTYEXE -load $ConfigName -l $UserName
        }
        exit
    }

    if (! $ShowVersion.Equals("")) {
        Write-Host "Version info uses pLink"
        $PLINKEXE = "$Env:PFilesX64\Putty\plink.exe"
        & $PLINKEXE -V
        exit
    }

    # server defaults to 192.168.20.38
    if ($ServerIP.Equals("")) {
        $ServerIP="server.company.com"
        Write-Host "Default server IP $ServerIP."
    }

    # User name to root
    if ($UserName.Equals("")) {
        if ($HOST_TYPE.Equals("Office")) { $UserName=$Env:UserName }
        else { $UserName="root" }
        Write-Host "Default user name: $UserName."
    }

    # Default port is 22
    if ($Port -eq 0) {
        $Port="22"
    }

    Write-Host "Opening ssh session with putty: $PUTTYEXE"
    & $PUTTYEXE -ssh -2 $ServerIP -l $UserName -P $Port
}

Main
