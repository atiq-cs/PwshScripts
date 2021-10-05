<#
.SYNOPSIS
Perform specified delay
.DESCRIPTION
ToDo: later, may be, update this with a C# implementation along with a binary

.PARAMETER Time
how long to delay and show a message
.EXAMPLE
 $ mdelay.ps1 2 "hello world"
 $ mdelay.ps1 5

.NOTES
Author: Atiq Rahman
Date: 2011-11-15
#>

[CmdletBinding()] Param (
  [Parameter(Mandatory=$true)] [int] $Time,
  [string] $Msg)


<# Main function
Refs,
  https://technet.microsoft.com/en-us/library/ff730952.aspx
 Icon,
  https://msdn.microsoft.com/en-us/library/system.windows.forms.tooltipicon.aspx
 NotifyIcon.ShowBalloonTip Method (Int32)
  https://msdn.microsoft.com/en-us/library/ms160064.aspx
 Dispose
  http://techibee.com/powershell/system-tray-pop-up-message-notifications-using-powershell/1865
Component.Dispose Method ()
  https://msdn.microsoft.com/en-us/library/3cc9y48w.aspx
#>
function Main() {
  # Assuming location of delay binary is in Env Path Var 
  bin\Delay.exe $Time
  # Start-Sleep $Time

  if ([string]::IsNullOrEmpty($Msg)) {
      $Msg = "DT: $Time seconds time up. Switch context now."
  }
  else {
      $Msg = "$Msg `(elapsed ${Time}s`)."
  }

  [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

  $objNotifyIcon = New-Object System.Windows.Forms.NotifyIcon

  # temp hack: variables are not inherited
  If ([string]::IsNullOrEmpty($PwshScriptDir)) {
    $PwshScriptDir = 'D:\pwsh-scripts'
  }

  $objNotifyIcon.Icon = $PwshScriptDir + "\bin\mdelay_ps_icon.ico"
  $objNotifyIcon.BalloonTipIcon = "Info"
  $objNotifyIcon.BalloonTipText = $Msg
  $objNotifyIcon.BalloonTipTitle = "Delay Timer"
  
  $objNotifyIcon.Visible = $True 
  $objNotifyIcon.ShowBalloonTip(2000)
  Start-Sleep -Milliseconds 2001
  $objNotifyIcon.Dispose()
}

Main
