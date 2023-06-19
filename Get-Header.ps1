<#
.SYNOPSIS
  Get http header of a server specified by URL
.DESCRIPTION
  Utilize HttpWebRequest and HttpWebResponse to retrieve header

.PARAMETER URL
  URI

.EXAMPLE
  $ Get-Header.ps1 http://rtur.net

.NOTES
- first write, 06-25-2011

tag: windows-only
#>


param([string]$Url)

if (! $Url) {
  $Url = "https://note.iqubit.xyz"
  echo "Defaulting to target host: $Url"
}

if (! ($Url.StartsWith("https://")) -and ! ($Url.StartsWith("http://"))) {
  $Url = "http://" + $Url
}

$WebRequestObject = [System.Net.HttpWebRequest] [System.Net.WebRequest]::Create($Url)
try{
  $ResponseObject = [System.Net.HttpWebResponse] $WebRequestObject.GetResponse()
}
catch [Net.WebException] {
  echo $_.Exception.ToString()
  break
}

echo "Header for $Url`n--------------------------------------"

foreach ($HeaderKey in $ResponseObject.Headers) {
  # "$HeaderKey"
  $HeaderStr = $ResponseObject.Headers[$HeaderKey]
  if ($HeaderStr) {
    # Doesn't display big cookie
     if ($HeaderKey.Equals("Set-Cookie") -and $HeaderStr.Length -gt 180) {
      $HeaderStr = $HeaderStr.Substring(0, 180) + " ..."
     }
     echo "$HeaderKey`: $HeaderStr"
  }
}
echo "--------------------------------------`nClosing connection."
$ResponseObject.Close()
