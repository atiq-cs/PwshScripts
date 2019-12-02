<#
.SYNOPSIS
Automate actions for turning on/off bluetooth
.DESCRIPTION
Control bluetooth radio device
.PARAMETER Status
Desired state of Bluetooth
.EXAMPLE
  -Status Off
  -Status On

.NOTES
Turn on/off Bluetooth radio/adapter from cmd/powershell in Windows 10
 https://superuser.com/q/1168551/

Not used right now, but, in trouble, can also look at,
 http://www.thewindowsclub.com/disable-bluetooth-windows-10

tag: windows-only-script
#>
  
[CmdletBinding()] Param (
  [Parameter(Mandatory=$true)] [ValidateSet('Off', 'On')] [string] $Status)

#####################    Function Definition Ends       #####################################
#######################################################################################################

# Start of Main function
function Main() {
  If ($Status -eq 'On' -and (Get-Service bthserv).Status -eq 'Stopped'
    ) {
    # ref for runas: https://stackoverflow.com/questions/7690994/powershell-running-a-command-as-administrator
	  If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::`
      GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] `
        "Administrator")) {
      $arguments = "Start-Service", "bthserv"
      Start-Process powershell -Verb runAs -ArgumentList $arguments
      mdelay.ps1 0 'Please adjust audio level/volume for the headphone.'
      Start-Sleep 1
    }
  }
  Add-Type -AssemblyName System.Runtime.WindowsRuntime
  $asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | ? {
    $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.
    GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]

  Function Await($WinRtTask, $ResultType) {
      $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
      $netTask = $asTask.Invoke($null, @($WinRtTask))
      $netTask.Wait(-1) | Out-Null
      $netTask.Result
  }

  [Windows.Devices.Radios.Radio,Windows.System.Devices,ContentType=WindowsRuntime] | Out-Null
  [Windows.Devices.Radios.RadioAccessStatus,Windows.System.Devices,ContentType=WindowsRuntime] | Out-Null
  Await ([Windows.Devices.Radios.Radio]::RequestAccessAsync()) ([Windows.Devices.Radios.RadioAccessStatus]) | Out-Null
  $radios = Await ([Windows.Devices.Radios.Radio]::GetRadiosAsync()) ([System.Collections.Generic.IReadOnlyList[Windows.Devices.Radios.Radio]])
  $bluetooth = $radios | ? { $_.Kind -eq 'Bluetooth' }
  [Windows.Devices.Radios.RadioState,Windows.System.Devices,ContentType=WindowsRuntime] | Out-Null
  Await ($bluetooth.SetStateAsync($Status)) ([Windows.Devices.Radios.RadioAccessStatus]) | Out-Null

  If ($Status -eq 'Off' -and (Get-Service bthserv).Status -eq 'Running') {
    # ref for runas: https://stackoverflow.com/questions/7690994/powershell-running-a-command-as-administrator
	  If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::`
      GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] `
        "Administrator")) {
      # Debug, add following in the beginning of arguments list to make powershell wait after command
      # '-NoExit', 
      $arguments = 'Stop-Service', '-Force', 'bthserv'
      Start-Process powershell -Verb runAs -ArgumentList $arguments
    }
  }
}

Main
