# Copyright (c) iQubit Inc.

<#
.SYNOPSIS
  Perform specified delay
.DESCRIPTION
  Call Delay Binary to Display timer and perform the delay
  Show a balloon notification on System Tray after specified time elapses
  ToDo: later, may be, update this with a C# implementation along with a binary

.PARAMETER Time
  how long to delay
.EXAMPLE
  mdelay.ps1 2 "task completed"
  mdelay.ps1 5

tag: windows-only
#>

[CmdletBinding()] Param (
  [Parameter(Mandatory=$true)] [int] $Time,
  [string] $Msg,
  [string] $PwshScriptDir = 'D:\pwsh-scripts')


<#
.SYNOPSIS
  Main function
.DESCRIPTION
  Check previous commentary (top)
.NOTES
  References
  - https://technet.microsoft.com/en-us/library/ff730952.aspx
  Icon,
  - https://msdn.microsoft.com/en-us/library/system.windows.forms.tooltipicon.aspx
  NotifyIcon.ShowBalloonTip Method (Int32)
  - https://msdn.microsoft.com/en-us/library/ms160064.aspx
  Dispose
  - http://techibee.com/powershell/system-tray-pop-up-message-notifications-using-powershell/1865
  Component.Dispose Method ()
  - https://msdn.microsoft.com/en-us/library/3cc9y48w.aspx
#>
function Main() {
  # Retrieving $PwshScriptDir from Params
  & ($PwshScriptDir + '\bin\Delay.exe') $Time
  # Start-Sleep $Time

  if ([string]::IsNullOrEmpty($Msg)) {
      $Msg = "DT: $Time seconds time up. Switch context now."
  }
  else {
      $Msg = "$Msg `(elapsed ${Time}s`)."
  }

  [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

  $objNotifyIcon = New-Object System.Windows.Forms.NotifyIcon

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
