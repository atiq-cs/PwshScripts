<#
.SYNOPSIS
  Compute Subresource Integrity SHA-384 of web source files
.DESCRIPTION
  Date: 05/28/2017
  Utilize Get-FileHash Module to generate SHA-384

.PARAMETER InputFile
  The Input File

.EXAMPLE
  Generate-SRI.ps1 D:\main_site\common\js\bootstrap.min.js
  Generate-SRI.ps1 D:\main_site\common\css\bootstrap.min.css

.NOTES
  Member Methods/Properties of the object [Microsoft.Powershell.Utility.FileHash],
    Hash
    GetHashCode()

  **Refs**
  SO - Converting string to byte array in C#
    https://stackoverflow.com/questions/16072709/converting-string-to-byte-array-in-c-sharp
  PowerTip: Encode String and Execute with PowerShell
    https://blogs.technet.microsoft.com/heyscriptingguy/2015/10/27/powertip-encode-string-and-execute-with-powershell/
  Powershell Get-FileHash Module
    https://msdn.microsoft.com/en-us/powershell/reference/5.1/microsoft.powershell.utility/Get-FileHash?f=255&MSPPError=-2147217396
  ms social technet - base64 encode a hex string (this solution is based on that)
    https://social.technet.microsoft.com/Forums/office/en-US/2c47769a-a76e-40b7-bf4c-b399e83366e4/how-do-i-base64-encode-a-hex-string-from-a-csvde-export-file-so-i-can-build-an-ldif-file-to-modify?forum=winserverpowershell
  SRI (Subresource Integrity)
    https://developer.mozilla.org/en-US/docs/Web/Security/Subresource_Integrity
  When we do not have PowerShell we have FCIV to generate SHA/md5
    ( Windows 10 - How to compute the MD5 or SHA-1 cryptographic hash values for a file )
    https://support.microsoft.com/en-us/help/841290/availability-and-description-of-the-file-checksum-integrity-verifier-utility

  tags: cryptography, base64, encryption
#>

Param(
    [Parameter(Mandatory=$true)] [alias("f")]
        [string] $InputFile
)

function Convert-HexStringToBase64String
{
    [OutputType([string])]
    [CmdletBinding()]
    param (
        [string] $HexStr
    )

    if ($HexStr -notmatch "([\dA-F]+)$")
    {
        throw "'$HexStr' is not a valid Hex string.  Expected format: X*'  (where 'X' may be any character 0-9 or A-F)"
    }

    $hexDigits = $matches[1]
    
    if ($hexDigits.Length % 2 -ne 0)
    {
        $hexDigits = "0$hexDigits"
    }

    $bytes =
    for ($i = 0; $i -lt $hexDigits.Length - 1; $i += 2)
    {
        [System.Convert]::ToByte($hexDigits.Substring($i, 2), 16)
    }

    return [System.Convert]::ToBase64String($bytes)
}

# Purpose of this function is to verify arguments
function VERIFY_PARAMETERS() {
    # verify input file exists and it's a file/leaf
    if (!(Test-Path $InputFile) -Or !(Test-Path -path $InputFile -pathtype leaf)) {
        Write-Host -ForegroundColor Red "Please provide correct input file path!`n"
        return -1
    }
    return 0
}

# Start of Main Function
function Main() {
    if (VERIFY_PARAMETERS -le 0) {
        break
    }
    $HashHex = [string] (Get-FileHash -Algorithm SHA384 $InputFile).Hash;
    $base64_SRI = Convert-HexStringToBase64String $HashHex
    Write-Host -NoNewline "Base64 SHA-384 Integrity String:`n "
    Write-Host -ForegroundColor Green "$base64_SRI`n"
}

Main