#!/usr/bin/env nu

# bluetooth device manager script

def connect_device [device_name: string] {
  let connected_device_lines = get-bluetooth-devices "Connected"
  if ($connected_device_lines | any {|line| $line | str ends-with $device_name}) {
    print $"Device '($device_name)' is already connected."
    return
  }

  let paired_device_lines = get-bluetooth-devices "Paired"
  let matched_device_line = ($paired_device_lines | where {|line| $line | 
    str ends-with $device_name})

  if ($matched_device_line | is-empty) {
    print $"Probaly wrong device name: ($device_name)!\n"
    return
  }

  let device_mac = ($matched_device_line | split row ' ' | get 1)
  bluetoothctl connect $device_mac
}

def disconnect_device [device_name: string] {
  let paired_device_lines = get-bluetooth-devices "Connected"
  let matched_device_line = ($paired_device_lines | where {|line| $line | 
    str ends-with $device_name})

  if ($matched_device_line | is-empty) {
    print $"($device_name) is already disconnected!\n"
    return
  }

  let device_mac = ($matched_device_line | split row ' ' | get 1)
  bluetoothctl disconnect $device_mac
  print $"($device_name) is successfully disconnected.\n"
}

def get-bluetooth-devices [deviceStatus: string] {
  return (bluetoothctl devices $deviceStatus | lines | take while {|line| 
    $line | str starts-with "Device "
  })
}

# main custom comand
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
