<#
.SYNOPSIS
  Perform chocolatey actions
.DESCRIPTION
  Modify Env Path

.PARAMETER WSType
  Workstation Type

.EXAMPLE
 Choco-Util.ps1 Matrix

.NOTES
#>

[CmdletBinding()] Param (
  [ValidateSet('Matrix', 'META')] [string] $WSType = 'Matrix'
)

<#
.SYNOPSIS
  The Main function of this Script
.DESCRIPTION
  Modifies choco configuration

.PARAMETER XX
  N/A

.EXAMPLE
  UpdateChoco

.NOTES
  only 2 workstations are supported as of now
#>
function UpdateChoco() {
  switch( $WSType ) {
    'Matrix' {
      $SourceList = choco sources list

      # Change the condition below to apply when the entry doesn't exist

      # as per our setup first entry should always be chocolatey
      # wfh is the first entry set by `Cleanup-FBIT`
      # used to be at position 1, check after running chef update
      # previous: if ( ! $SourceList[3].Contains('chocolatey') )
      if ($SourceList.Length -Eq 3 -And $SourceList[2].Contains('cpe_client')) {
        choco source add -n=chocolatey -s="https://chocolatey.org/api/v2/"
        choco source disable -n=wfh
        choco source disable -n=cpe_client
      }
      elseif ($SourceList.Length -Eq 4 -And $SourceList[3].Contains('chocolatey [Disabled]')) {
        # choco source add -n=chocolatey -s="https://chocolatey.org/api/v2/"
        choco source enable -n=chocolatey
        # choco source remove -n wfh
        # choco source remove -n cpe_client
        choco source disable -n=wfh
        choco source disable -n=cpe_client
        choco sources list
        return
      }
      return
    }
    'META' {
      $SourceList = choco sources list
      $CC = 2

      # chocolatey in position 3, at present
      if (! $SourceList[$CC].Contains('cpe_client')) {
        Write-Host 'choco second entry is different, have a look!'
        return
      }

      if ($SourceList[$CC].Contains('[Disabled]')) {
        # choco source add -n=wfh -s="C:\chef\solo\confectioner\latest"
        # choco source add -n=cpe_client -s="https://confectioner.thefacebook.com/"
        choco source enable -n=cpe_client
        choco source enable -n=wfh
        if ($SourceList.Length -Eq 3) { choco source disable -n=chocolatey }
        choco sources list
      }
      return
    }
    default {
      'Invalid command line argument: ' + $WSType
      return
    }
  }
}

UpdateChoco
