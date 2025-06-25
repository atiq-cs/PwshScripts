<#
.SYNOPSIS
Disk checker for Linux

.DESCRIPTION
Automate `btrfs scrub` running for my Linux FS partitions.
In addition, run system journal files verification

.EXAMPLE
Check-Disk.ps1

.NOTES
I plan to update this script after switching to ZFS filesystem to automatically
retrieve list of partition mount points for scanning! Right now, partition list
is hardcoded!

tag: linux-only
#>


<#
.SYNOPSIS
Poll on scrub status till scrubbing is complete! Supports specifying interval
(seconds) to poll / query.

.PARAMETER waitInterval
Seconds to wait before next poll

.NOTES
When $count reaches $maxWaitLimit gotta check if there's abort or canceled on status!

States to consider: finished, aborted and canceled
#>
function WaitForScrubCompletion([string] $partitionName, [int] $waitInterval = 5) {
  $maxWaitLimit = 10

  $count = 0
  do {
    $result = sudo btrfs scrub status $partitionName
    $status = ($result -Match '^Status:')[0]

    if ($status -And $status.EndsWith("finished") -Or $count -Eq $maxWaitLimit) {
      $result
      break
    }

    Start-Sleep $waitInterval
  } while ($count -Lt $maxWaitLimit)
}


<#
.SYNOPSIS
Initiate scrub start and then poll on status

.PARAMETER partitionName
Partition to Scrub
#>
function RunScrubOnPartition([string] $partitionName = '/') {
  Write-Host "`nChecking partition $partitionName"
  sudo btrfs scrub start $partitionName
  WaitForScrubCompletion $partitionName
}

# Start of Main function
function Main() {
  journalctl --verify

  # hard coded till ZFS migration is complete!
  $partitions = @('/home', '/', `
    '/var/lib/portables', '/var/lib/machines')

  foreach ($partition in $partitions) {
      RunScrubOnPartition $partition
  }
}

Main
