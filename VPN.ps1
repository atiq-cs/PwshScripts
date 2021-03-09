<#
.SYNOPSIS
VPN Powershell Script to connect and disconnect
.DESCRIPTION
This script provides easier usage of Cisco anyconnect CLI tool, utilizes proven
methods to connect. The script almost never fails.

.PARAMETER Action
VPN Action to perform
.EXAMPLE
Connect example,

  VPN.ps1 connect

Disconnect example,

  VPN.ps1 disconnect

.NOTES
Putty Reg abstraction temporarily allows us to open source it. In future replace that with some
config (containing URLs)
Added support for forced disconnect in case it helps when shell is hang and it won't connect
anymore. This needs to be tested.

Before running this script ensure Service 'VPNAgent' Running. Usually it's
installed by default with CPE deployment of cisco anyconnect on client
machines.

VPN component will fail if corpnet's VM node is down.

vpn tool draft cmd example,

  "connect `"Profile Name`"`r`n `r`nexit" | & "${Env:ProgramFiles(x86)}\Cisco\Cisco`
  	AnyConnect Secure Mobility Client\vpncli.exe" -s

From `COMSPEC`,

  vpncli.exe -s < anyconnect.txt

### Ref
- The redirection case for powershell: [reddit](https://www.reddit.com/r/PowerShell/comments/10kz2v/input_redirection_to_executable)
- old doc, [vpn manual at mik.ua](https://docstore.mik.ua/univercd/cc/td/doc/product/vpn/client/3_6/admin_gd/vcach4.htm)
- [Minimal Shell and Pwsh Scripts](https://github.com/atiq-cs/pwsh-scripts)
#>

[CmdletBinding()] Param (
  [ValidateSet('connect', 'disconnect')]
  [Parameter(Mandatory=$true)] [string] $Action,
  [bool] $Force=$False
)

<#
.SYNOPSIS
VPN function
.DESCRIPTION
Provides methods to connect and disconnect
.PARAMETER Action
Cmdlet param `$Action` is resused.
.EXAMPLE
  VPN
.NOTES
- Please replace $corpNetNode with your own VM hostname. If you have multiple
	dev VMs, use hostname of any of them.
- Powershell 7 or higher recommended for cross-platform.
- connect and disconnect are in same method as they share some variables

For different regions, we need to modify following line in script,

	connect `"Americas West`"`

To specify correct VPN target profile,
- string containing escape sequence requires double quoting

*notes on disconnect*
This hangs when client is already disconnected,
Example,
   & $BinaryPath disconnect
Hence, we do check ICMP reply from a node in CorpNet.

If you have putty config for your devvm/devserver, this can come from registry,

  $ConfigName = 'devvm-fb1'
  $corpNetNode = Get-ItemPropertyValue ('HKCU:Software\SimonTatham\PuTTY\Sessions\' +
      $ConfigName) -Name HostName
#>
function VPN() {
	$VPNService = 'VPNAgent'

	# Please replace with one of your VM host names; it's a placeholder
	# $corpNetNode = 'devvm7738.prn2.facebook.com'
  $ConfigName = 'devvm-fb1'
  $corpNetNode = Get-ItemPropertyValue ('HKCU:Software\SimonTatham\PuTTY\Sessions\' + 
      $ConfigName) -Name HostName
  # default install location
  $BinaryPath = ${Env:ProgramFiles(x86)} + '\Cisco\Cisco AnyConnect Secure Mobility Client\vpncli.exe'
  $BinaryDir = [IO.Path]::GetDirectoryName($BinaryPath);

  switch( $Action ) {
    'connect' {
      if ((Get-Service $VPNService).Status -Eq 'Running') {    
        if (Test-Connection $corpNetNode -Count 1 -ErrorAction SilentlyContinue) {
            Write-Host -ForegroundColor Green 'Already connected to CorpNet through VPN.'
            return
        }
    
        $authToken = Read-Host 'Please enter duo push for VPN Auth'
				# 'Americas West' should be replaced if you are located outside of West Coast
        Push-Location $BinaryDir
        ("connect `"Americas West`"`r`n" + $authToken + "`r`nexit") | & $BinaryPath -s
        Pop-Location
      }
      else {
        Write-Host -ForegroundColor Red 'Service' $VPNService 'is not running!'
      }
      return
    }
    'disconnect' {
      $VPNService = 'VPNAgent'

      if ((Get-Service $VPNService).Status -Eq 'Running') {
        # Is there much use case of this `Force` flag
        if (!$Force -And ! (Test-Connection $corpNetNode -Count 1 -ErrorAction SilentlyContinue)) {
          'VPN client is disconnected.'
          return
        }

        Push-Location $BinaryDir
        ('disconnect' + "`r`nexit") | & $BinaryPath -s
        Pop-Location
        'Feel free to release service ''' + $VPNService + '''!'
      }
      return
    }
  }
}

VPN