#!/usr/bin/env nu
# -----------------------------------------------------------------------------
# Script : bluetooth device manager script
# Desc   : Bluetooth device manager for connecting, disconnecting, and listing devices
# Date   : 07-10-2025
# Dependencies: bluetoothctl (Linux Bluetooth utility)
#
# Usage: ./bt.nu <action> [device_type]
#
# Actions:
#   connect    - Connect to a Bluetooth device
#   disconnect - Disconnect from a Bluetooth device  
#   list       - List all connected Bluetooth devices with numbered output
#
# Device Types:
#   keyboard   - Keychron K8 (default)
#   headset    - TREBLAB Z7-Pro
#
# Examples:
#   ./bt.nu connect keyboard
#   ./bt.nu disconnect headset
#   ./bt.nu list
#
# tag: linux-only
# -----------------------------------------------------------------------------


# Custom Command: connect_device
# Description: Connects to a Bluetooth device by name with duplicate connection
#   prevention
# Parameters:
#   device_name (string) - The exact name of the device to connect to
def connect_device [device_name: string] {
  # Check if device is already connected to prevent attempting duplicate connection
  let connected_device_lines = get-bluetooth-devices "Connected"
  if ($connected_device_lines | any {|line| $line | str ends-with $device_name}) {
    print $"Device '($device_name)' is already connected."
    return
  }

  # Search for the device in the paired devices list
  let paired_device_lines = get-bluetooth-devices "Paired"
  let matched_device_line = ($paired_device_lines | where {|line| $line | 
    str ends-with $device_name})

  # Validate that the device exists in paired devices before attempting connection
  if ($matched_device_line | is-empty) {
    print $"Probaly wrong device name: ($device_name)!\n"
    return
  }

  # Extract MAC address from device line (format: "Device MAC_ADDRESS Device_Name")
  let device_mac = ($matched_device_line | split row ' ' | get 1)
  bluetoothctl connect $device_mac
}


# Custom Command: disconnect_device
# Description: Disconnects a Bluetooth device by name with connection state validation
# Parameters:
#   device_name (string) - The exact name of the device to disconnect
def disconnect_device [device_name: string] {
  # Get currently connected devices to locate the target device
  let paired_device_lines = get-bluetooth-devices "Connected"
  let matched_device_line = ($paired_device_lines | where {|line| $line | 
    str ends-with $device_name})

  # Verify device is actually connected before attempting disconnection
  if ($matched_device_line | is-empty) {
    print $"($device_name) is already disconnected!\n"
    return
  }

  # Extract MAC address from device line (format: "Device MAC_ADDRESS Device_Name")
  let device_mac = ($matched_device_line | split row ' ' | get 1)
  # Execute bluetoothctl disconnect command and provide success confirmation
  bluetoothctl disconnect $device_mac
}

# Function: get-bluetooth-devices
# Description: Retrieves filtered Bluetooth device list, removing non-device entries
# Parameters:
#  deviceStatus (string) - Status filter ("Connected", "Paired", or empty string)
# Returns:
#  List<string> - List of device lines that start with "Device " prefix
# Notes:
#  Uses 'take while' to stop processing at first non-device line (UUIDs, endpoints, etc.)
def get-bluetooth-devices [deviceStatus: string] {
  # TODO: error handling, validation of input args cases like "Invalid" or "No default controller"
  return (bluetoothctl devices $deviceStatus | lines | take while {|line| 
    $line | str starts-with "Device "
  })
}


# Custom Command: main
# Description: Entry point with command-line argument parsing and action routing
# Parameters:
#   action (string) - Required action to perform (connect, disconnect, list)
#   device_type (string, optional) - Device type selection (keyboard, headset)
# Returns: void
def main [
  action: string,       # 1. action to perform
  device_type?: string
] {
  # Args validation
  let device_name = if $device_type == null or $device_type == "keyboard" {
    "Keychron K8"
  } else if $device_type == "headset" {
    "TREBLAB Z7-Pro"
  } else {
    print $"Error: Unknown device type '($device_type)'"
    print "Supported types: keyboard, headset"
    print ""
    return
  }

  # switch statement on Action
  match $action {
    "connect" => {
      connect_device $device_name
    }
    "disconnect" => {
      disconnect_device $device_name
    }
    "list" => {
      print "Connected Devices List"
      print "----------------------"
      
      mut count = 1
      for line in (get-bluetooth-devices "Connected") {
        print $"($count). ($line | split row ' ' | skip 2 | str join ' ')"
        $count = $count + 1
      }

      print ""
    }
    _ => {
      print $"Invalid command line argument: ($action)"
      print "Usage: bt.nu <connect|disconnect|list> [keyboard|headset]"
      print "Examples:"
      print "  ./bt.nu connect keyboard"
      print "  ./bt.nu disconnect headset"
      print "  ./bt.nu list"
    }
  }
}
