<#
.SYNOPSIS
Export scheduled task list
.DESCRIPTION
ToDo
.PARAMETER OutDir

.EXAMPLE


.NOTES
## References
https://devblogs.microsoft.com/scripting/weekend-scripter-use-powershell-to-document-scheduled-tasks

tag: windows-only-script
#>

Param ([string] $OutDir)

# Generate CSV from task list
function GenerateCSVFromTasks([string] $taskPath, [string] $outCSVPath) {
  Write-Host "Writing for scheduled task path $taskPath"
  Get-ScheduledTask -TaskPath $taskPath |
    ForEach-Object { [pscustomobject]@{
    Name = $_.TaskName
    Path = $_.TaskPath
    LastResult = $(($_ | Get-ScheduledTaskInfo).LastTaskResult)
    NextRun = $(($_ | Get-ScheduledTaskInfo).NextRunTime)
    Status = $_.State
    Command = $_.Actions.execute
    Arguments = $_.Actions.Arguments }} | Format-Table

  Get-ScheduledTask -TaskPath $taskPath |
    ForEach-Object { [pscustomobject]@{
    Name = $_.TaskName
    Path = $_.TaskPath
    LastResult = $(($_ | Get-ScheduledTaskInfo).LastTaskResult)
    NextRun = $(($_ | Get-ScheduledTaskInfo).NextRunTime)
    Status = $_.State
    Command = $_.Actions.execute
    Arguments = $_.Actions.Arguments }} |
      Export-Csv -Append -Path $outCSVPath -NoTypeInformation
}


# Start of Main function
function Main() {
  $csvFileName = $OutDir + '\SchTasks-' + $(Get-Date -Format "yyyy-MM-dd") + '.csv'
  if (Test-Path $csvFileName) {
    Clear-Content $csvFileName
  }
  GenerateCSVFromTasks '\' $csvFileName
  GenerateCSVFromTasks '\fbit\' $csvFileName
}

Main
