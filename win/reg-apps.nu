#!/usr/bin/env nu
# List Apps from the registry without switching shell

# TODO: figure out multi line break
.\($env.PFilesX64Dir | path join "pwsh" "pwsh") -NoProfile -Command "Get-ChildItem 'HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\App Paths' | Select-Object PSChildName"
.\($env.PFilesX64Dir | path join "pwsh" "pwsh") -NoProfile -Command "Get-ChildItem 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\App Paths' | Select-Object PSChildName"