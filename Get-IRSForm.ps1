<#
.SYNOPSIS
  Download IRS Form given form number
.DESCRIPTION
  Download the form and make a copy under ./forms directory (set via FormsBackupDir variable)

.PARAMETER FormName
  IRS Form#

.PARAMETER OutputDir
  Where to save

.EXAMPLE
  Get-IRSForm.ps1 1040sd ~/Doc/Tax-24

.NOTES
  
Instruction URLs
- 1040 Main: https://www.irs.gov/instructions/i1040gi (includes instructions for Sched 1, Sched 2
    and Sched 3)
- 1040 Sch A: https://www.irs.gov/instructions/i1040sca
- 1040 Sch D: https://www.irs.gov/instructions/i1040sd


Demonstrates Invoke-WebRequest error handling
#>

[CmdletBinding()] Param (
  [Parameter(Mandatory=$true)]
   [ValidateSet('1040sa', '1040sd', '1040s1', '1040s2', '1040s3')]
     [string] $FormName,
  [Parameter(Mandatory=$true)] [string] $OutputDir)


function Main() {
  $FormsBackupDir = 'forms'
  $IRSBaseURL = 'https://www.irs.gov/pub/irs-pdf/'
  $fileName = 'f' + $FormName + '.pdf'
  $Url = $IRSBaseURL + $fileName
  "URL for the input form: $Url"

  # Following Validation since addition of ValidateSet
  # if (-Not ($Url.EndsWith(".pdf"))) {
  #   Write-Host "Wrong input URL!"
  #   exit 1
  # }

  # Old Code
  # Parse the file name from the URL
  # $uri = [System.Uri] $Url
  # $fileName = [System.IO.Path]::GetFileName($uri.AbsolutePath)
  # if ([string]::IsNullOrWhiteSpace($fileName)) {
  #   Write-Host "Unable to determine file name from URL!"
  #   break
  # }


  Push-Location $OutputDir

  try {
    # following version is useless, for downloading file we don't use response!
    #  Errors are usually discovered via Exceptions not responses!
    # $response = Invoke-WebRequest ...
    Invoke-WebRequest $Url -OutFile $fileName -ErrorAction Stop
  }
  catch {
    # Handle errors, such as 404 (file not found)
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host "Error: File not found (404). Check the URL."
    }
    else {
        Write-Host "An error occurred: $($_.Exception.Message)"
    }

    Pop-Location
    break
  }

  $item = (Get-Item $fileName)
  $bakFormName = $item.BaseName + '_orig' + $item.Extension
  If (-Not (Test-Path $FormsBackupDir)) { New-Item -Type Directory $FormsBackupDir }
  Copy-Item $fileName forms/$bakFormName
  "Retrieving and backing up an original copy of form $FormName completed!"

  Pop-Location
}

Main
