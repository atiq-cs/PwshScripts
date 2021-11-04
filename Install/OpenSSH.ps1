<#
.SYNOPSIS
  Installs Windows OpenSSH
.DESCRIPTION
  Checks for latest release of openssh github
.EXAMPLE
  Install\OpenSSH.ps1

.NOTES
  Deps,
  - $GITHUB_TOKEN: A read only access token from GH

  TODO:
    make GITHUB_TOKEN an argument to this script
    provide option to install in different location

  **References**
  - Install powersehll script,
   https://github.com/PowerShell/PowerShell/blob/master/tools/install-powershell.ps1#L346
  - Download latest GitHub release via Powershell
   https://gist.github.com/Splaxi/fe168eaa91eb8fb8d62eba21736dc88a
  - GitHub Rest API
   https://docs.github.com/en/rest/guides/getting-started-with-the-rest-api#repositories
  - GitHub Rest API, Simple Examples of PowerShell's Invoke-RestMethod
   https://www.jokecamp.com/blog/invoke-restmethod-powershell-examples
  - this project's GH page
   https://github.com/PowerShell/Win32-OpenSSH
  - bash ref
   https://gist.github.com/steinwaywhw/a4cd19cda655b8249d908261a62687f8
  - Official Install Instruction
   https://github.com/PowerShell/Win32-OpenSSH/wiki/Install-Win32-OpenSSH
  - More info, also, how to run this script
   https://github.com/atiq-cs/pwsh-scripts/wiki/Custom-Installations#win32-openssh
#>

function Main() {
    # Validate Arguments
    if ([string]::IsNullOrEmpty($GITHUB_TOKEN)) {
        'GITHUB_TOKEN is empty!'
        return
    }
    if ($GITHUB_TOKEN.Length -lt 40) {
        'Please check GITHUB_TOKEN!'
        return
    }

    # get new release version string
    $headers = @{
        'Authorization' = $GITHUB_TOKEN
    }

    $response = Invoke-RestMethod 'https://api.github.com/repos/PowerShell/Win32-OpenSSH/releases/latest' -Method Get -Headers $headers
    $release = $response.name

    # example release tag: v8.1.0.0p1-beta
    If ([string]::IsNullOrEmpty($release) -Or $release.Length -lt 'v8.1.0.0'.Length) {
        'invalid release tag'
        return
    }

    # use the release version string to form the download URL
    $packageName = "OpenSSH-Win64.zip"

    # Example download URL
    #  */PowerShell/Win32-OpenSSH/releases/download/V8.6.0.0p1-Beta/OpenSSH-Win64.zip
    $downloadURL = "https://github.com/PowerShell/Win32-OpenSSH/releases/download/$release/$packageName"
    # Write-Verbose "About to download package from '$downloadURL'" -Verbose
    "Downloading package from '$downloadURL'"

    $targetDir = 'D:\PFiles_x64\choco'
    $packagePath = $targetDir + '\' + $packageName

    # show version of previous ssh binary
    # it's placed here coz the output is messed up by Invoke-WebRequest
    # ssh binary is also a different console app, doesn't behave nice in powershell stdout
    'Previous version:'
    & "$targetDir\ssh\ssh" -V
    [System.Environment]::NewLine

    Invoke-WebRequest -Uri $downloadURL -OutFile $packagePath

    # prepare target dir
    if (Test-Path "$targetDir\ssh.old") { Remove-Item -Recurse "$targetDir\ssh.old" }
    if (Test-Path "$targetDir\ssh") { Rename-Item "$targetDir\ssh" "$targetDir\ssh.old" }
    Expand-Archive -Path $packagePath -DestinationPath $targetDir
    $packageBaseName = $packageName.Substring(0, $packageName.Length-4)
    Rename-Item "$targetDir\$packageBaseName" "$targetDir\ssh"
    "Rename '$targetDir\$packageBaseName' to '$targetDir\ssh'"

    # cleanup
    Remove-Item $packagePath
    'New version:'
    & "$targetDir\ssh\ssh" -V
    [System.Environment]::NewLine
}

Main
