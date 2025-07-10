<#
.SYNOPSIS
  Tax forms helper for Federal, State forms

.DESCRIPTION
  Download IRS/FTB Forms given form number
   Open online instructions URL (TODO)
  Download the form and make a copy under ./forms directory (set via FormsBackupDir variable)

  State default is California: Franchise Tax Board, for now

.PARAMETER COType
  Organization / company type: Federal (IRS), FTB (California)

.PARAMETER FormName
  IRS / FTB Form#

.PARAMETER OutputDir
  Where to save forms and to create back up dir inside

.EXAMPLE
  TaxTool.ps1 federal 1040sd ~/Doc/Tax-24
  TaxTool.ps1 state 540 ~/Doc/Tax-24/ftb

.NOTES
  
Federal Instruction URLs
- IRS EP    : https://www.irs.gov/instructions
- 1040 Main : https://www.irs.gov/instructions/i1040gi (includes instructions for Sched 1, Sched 2
    and Sched 3)
- 1040 Sch A: https://www.irs.gov/instructions/i1040sca
- 1040 Sch D: https://www.irs.gov/instructions/i1040sd
- 843       : https://www.irs.gov/instructions/i843

FTB Instruction URLs
Forms under Misc: https://www.ftb.ca.gov/forms/misc/XXXX.pdf

- 540     : https://www.ftb.ca.gov/forms/2024/2024-540-booklet.html
- 540-CA  : https://www.ftb.ca.gov/forms/2024/2024-540-ca-instructions.html
ISR
- 3853    : https://www.ftb.ca.gov/forms/2024/2024-3853-instructions.pdf
Misc forms: 2917, 3701


Demonstrates Invoke-WebRequest error handling
#>

[CmdletBinding()] Param (
  [Parameter(Mandatory)] [ValidateSet('federal', 'state')]
    [string] $COType,

  [Parameter(Mandatory=$true)]
  #  [ValidateSet('1040sa', '1040sd', '1040s1', '1040s2', '1040s3', '6781', '8949', '843')]
  #   [string] $FormName,
  [ValidateScript({
    $federalForms = '1040sa', '1040sd', '1040s1', '1040s2', '1040s3', '6781', `
     '8949', '4952', '843'
    $stateForms = '540', '540-ca', '3853', '2917', '3701'

    If ($COType -Eq 'federal' -And $federalForms -contains $_) { return $true }
    Elseif ($COType -Eq 'state' -And $stateForms -contains $_) { return $true }
    Else {
      throw "Invalid FormName `$_` for Type `$COType`. Valid values are: " +
        ($COType -Eq 'federal' ? $federalForms -join ', ' : $stateForms -join ', ')
    }
  })]
  [string] $FormName,

  [Parameter(Mandatory=$true)]
    [string] $OutputDir
)


function Main() {
  $FormsBackupDir = 'forms'
  $CoBaseURL = 'https://www.irs.gov/pub/irs-pdf/'

  $fileName = 'f' + $FormName + '.pdf'
  if ($COType.Equals('state')) {
    # `CoBaseURL` Initialization stuff
    $CoBaseURL = 'https://www.ftb.ca.gov/forms/'

    $IsMiscForm = [Boolean] $False
    if ($FormName.Equals('2917') -Or $FormName.Equals('3701')) {
      $IsMiscForm = $True
    }

    $TaxYear = [string] (Get-Date).AddYears(-1).Year
    
    if (-Not $IsMiscForm) {
      $fileName = $TaxYear + '/' + $TaxYear + '-' + $FormName + '.pdf'
    }
    else {
      $CoBaseURL = 'https://www.ftb.ca.gov/forms/misc/'
      $fileName = $FormName + '.pdf'
    }

    $Url = $CoBaseURL + $fileName
    $fileName = $FormName + '.pdf'
  }
  else {
    $Url = $CoBaseURL + $fileName
  }

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
  $bakFormName = 'f' + $FormName + '_orig.pdf'
  if ($COType.Equals('state')) {
    $bakFormName = $FormName + '_orig.pdf'
  }

  Push-Location $OutputDir
  if (Test-Path $FormsBackupDir/$bakFormName) {
    if (Test-Path $fileName) {
      "$fileName already exists!"
      Pop-Location
      break
    } Else {
      "Local copy of $bakFormName exists! Using that instead.."
      Copy-Item $FormsBackupDir/$bakFormName $fileName
      Pop-Location
      break
    }
  } Else {
    "URL for the input form: $Url"

    try {
      # saving return value on $response is useless, for downloading file we don't use response!
      #  Errors are usually discovered via Exceptions not responses!
      # $response = Invoke-WebRequest ...

      Invoke-WebRequest $Url -OutFile $fileName -ErrorAction Stop
    }
    catch {
      # Handle errors, such as 404 (file not found)
      if ($_.Exception.Response.StatusCode -Eq 404) {
          Write-Host "Error: File not found (404). Check the URL."
      }
      else {
          Write-Host "An error occurred: $($_.Exception.Message)"
      }

      Pop-Location
      break
    }
  }

  # $item = (Get-Item $fileName)
  # $bakFormName = $item.BaseName + '_orig' + $item.Extension
  If (-Not (Test-Path $FormsBackupDir)) { New-Item -Type Directory $FormsBackupDir }
  Copy-Item $fileName $FormsBackupDir/$bakFormName
  "Retrieving and backing up an original copy of form $FormName completed!"

  Pop-Location
}

Main
