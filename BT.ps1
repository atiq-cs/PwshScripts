<#
.SYNOPSIS
Wireless device connection helper

.DESCRIPTION
bluetooth only for now, to control connections to headset and keyboard

.PARAMETER Action
connect or disconnect
.PARAMETER DeviceType
which device is the target?

.EXAMPLE
BT.ps1 disconnect headset
BT.ps1 connect keyboard

.NOTES
Device names are hard coded in first block of main method..
Linux only since `bluetoothctl` is required.

Arrayfi, dup code could be moved to a method utilizing 'Invoke-Expression'

$btclCmd = "bluetoothctl devices Paired"
Invoke-Expression $btclCmd

linux command i.e, 'bluetoothctl devices Paired' ideally returns an array of
  strings. However, when it returns a single line it is just a string instead
  of array of strings.
Hence, -Match returns
  - System.Boolean when input is string
  - returns MatchInfo when input is array of strings
  one device is paired, next if statement will throw an exception

tag: linux-only
#>

[CmdletBinding()] Param (
  [Parameter(Mandatory=$true)] [ValidateSet('connect', 'disconnect', 'list')] [string] $Action,
  [ValidateSet('headset', 'keyboard')] [string] $DeviceType = 'keyboard')


# Start of Main function
function Main() {
  # Set the headset as default since it is used most frequently these days
  $DeviceName = "TREBLAB Z7-Pro"

  if ($DeviceType.Equals("keyboard")) {
    $DeviceName = "Keychron K8"
  }
  elseif (-Not $DeviceType.Equals("headset")) {
    Write-Host "Default device set to $DeviceName"
  }

  switch ($Action) {
      "connect" {
        if ((bluetoothctl devices Connected) -Match $DeviceName) {
          Write-Host "Device is already connected."
        } else {
          # Arrayfi comments above
          $linesArray = bluetoothctl devices Paired
          if ($linesArray.Count -Eq 1) {
            $linesArray = @($linesArray)
          }
          $matchedRowStr = $linesArray -Match $DeviceName
          if ($matchedRowStr.Length -Eq 1) {
            # Need to run this in a loop for the keyboard
            bluetoothctl connect $matchedRowStr[0].Split(' ')[1]
          } else {
            "Device: $DeviceName needs to be paired first!"
          }
        }
       }
      "disconnect" {
        # Arrayfi bluetoothctl output so -Match behavior is consistent
        $linesArray = bluetoothctl devices Connected
        if ($linesArray.Count -Eq 1) {
          $linesArray = @($linesArray)
        }
        $matchedRowStr = $linesArray -Match $DeviceName

        if ($matchedRowStr.Length -Eq 1) {
          bluetoothctl disconnect $matchedRowStr[0].Split(' ')[1]
        } else {
          Write-Host "Device is already disconnected."
        }
      }
      "list" {
        $bCtlOutput = bluetoothctl devices Connected

        if (-Not $bCtlOutput) {
          'No bluetooth device is connected.'
          return 
        }

        if ($bCtlOutput.Contains("Invalid") -Or $bCtlOutput.Contains("No default controller")) {
          Write-Host -ForegroundColor Red "bluetoothctl error: $bCtlOutput!"
          return
        }
        
        'Connected Devices List'
        '----------------------'
        $count = 1
        ForEach ($line in $bCtlOutput) {
          # Handle verbose output:
          #   bluez prints UUIDs and Endpoint after listing Devices
          if (-Not $line.StartsWith("Device")) {
            break
          }

          # second argument to limit number of tokens
          $deviceName = $line.Split(' ', 3)[2]
          if ($deviceName) {
            "$count. $deviceName"
            $count++
          }
          else {
            Write-Host -ForegroundColor Red "Error: $deviceName is empty!"
          }
        }
      }
      default {
        'Invalid command line argument: ' + $Action
        return
      }
  }
}

Main
