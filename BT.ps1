<#
.SYNOPSIS
  Wireless device connection helper
.DESCRIPTION
  Only via bluetooth for now to control connections to
   headset and keyboard

.PARAMETER Action
  connect or disconnect
.PARAMETER DeviceType
  which device is the target?

.EXAMPLE
  BT.ps1 Disconnect Headset
  BT.ps1 Connect Keyboard

.NOTES
 Device names are hard coded in first block of main method..
 Linux only since `bluetoothctl` is required.

tag: linux-only
#>

[CmdletBinding()] Param (
  [Parameter(Mandatory=$true)] [ValidateSet('Connect', 'Disconnect', 'List')] [string] $Action,
  [ValidateSet('Headset', 'Keyboard')] [string] $DeviceType = 'Keyboard')


# Start of Main function
function Main() {
  # Set the headset as default since it is used most frequently these days
  $DeviceName = "TREBLAB Z7-Pro"

  if ($DeviceType.Equals("Keyboard")) {
    $DeviceName = "Keychron K8"
  }
  elseif (-Not $DeviceType.Equals("Headset")) {
    Write-Host "Default device set to $DeviceName"
  }

  switch ($Action) {
      "Connect" {
        if ((bluetoothctl devices Connected) -Match $DeviceName) {
          Write-Host "Device already connected."
        } else {
          # Need to run this in a loop for the keyboard
          $matchedRowStr = (bluetoothctl devices Paired) -Match $DeviceName
          if ($matchedRowStr) {
            bluetoothctl connect $matchedRowStr.Split(' ')[1]
          } else {
            "Device: $DeviceName needs to be paired first!"
          }
        }
       }
      "Disconnect" {
        $matchedRowStr = (bluetoothctl devices Connected) -Match $DeviceName
        if ($matchedRowStr) {
          bluetoothctl disconnect $matchedRowStr.Split(' ')[1]
        } else {
          Write-Host "Device already disconnected."
        }
      }
      "List" {
        'Connected Devices'
        '-----------------'
        bluetoothctl devices Connected | ForEach-Object {
          # second argument to limit number of tokens
          $_.Split(' ', 3)[2]
        }
      }
      default {
        'Invalid command line argument: ' + $Action
        return
      }  
  }
}

Main
