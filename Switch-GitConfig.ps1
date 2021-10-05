# Copyright (c) iQubit Inc.
<#
.Synopsis
    Switch git config
.DESCRIPTION
    Switch to provided git config profile. Runs series of git config commands.
    Suggests updating GH Token
    ToDo:
    Fow now, go with this..
    provide Force flag
    probably read from a local json config file
    too many params to pass otherwise..

    facilitate proper checkout with GitUtil

    Demonstrates,
    - switch syntax
    - case insensitive string comparison: [System.StringComparison]
.Parameter ProfileName
    Select among available profiles
.Parameter CredUserNames
    Available git user names
.EXAMPLE
    Switch-GitConfig.ps1 Matrix @(USER_NAME_1, USER_NAME_2)
#>

[CmdletBinding()]
param(
    [ValidateSet('Matrix', 'MM')]
    [Parameter(Mandatory=$true)] [string] $ProfileName,
    [Parameter(Mandatory=$true)] [string[]] $CredUserNames
)


<#
.SYNOPSIS
    Switch to given git config profile
.DESCRIPTION
    Sets for both git repo local and global,
    - user name
    - user email
    - credential user name
#>
function Main() {
    switch ($ProfileName) {
        "Matrix" {
            $gitUserName = git config --get user.name
            $shellUserName = $($Home.SubString($Home.LastIndexOf('\')+1))

            if (-not ($gitUserName).StartsWith($shellUserName, [System.StringComparison]::`
                InvariantCultureIgnoreCase)) {
                throw [ArgumentException] ('Unexpected user name ' + $gitUserName + '!')
            }

            $gitUserEmail = git config --get user.email
            # global
            git config --global user.name "$gitUserName"
            git config --global user.email $gitUserEmail

            if ($CredUserNames.Length -lt 1) {
                throw [ArgumentException] ('Unexpected number of gUser Names!')
            }
            git config credential.username $CredUserNames[0]
            # ref, repo: atiq-cs/note
            $Env:GITHUB_TOKEN = '622c74c4d9106bda9a750c983343407ee4d4abe1'
            Break
        }
        "MM" {
            $gitUserName = git config --get user.name
            $userNameSuffix = 'mm'

            if (-not ($gitUserName).EndsWith($userNameSuffix)) {
                throw [ArgumentException] ('Unexpected user name ' + $gitUserName + '!')
            }

            $gitUserEmail = git config --get user.email
            # global
            git config --global user.name "$gitUserName"
            git config --global user.email $gitUserEmail

            if ($CredUserNames.Length -lt 2) {
                throw [ArgumentException] ('Unexpected number of gUser Names!')
            }
            git config credential.username $CredUserNames[1]
            # ref, repo: think-mm/blog
            $Env:GITHUB_TOKEN = '4770a857cb1482da0e8af7c39a06de4ccf001eeb'
            Break
        }
        Default { "Unexpected $ProfileName!" }
    }

    # verify
    git config --global --get user.name
    git config --global --get user.email
    git config --get user.name
    git config --get user.email
    git config --get credential.username

    'Remember to set your GITHUB_TOKEN before invoking ''deploy'''
}

Main
