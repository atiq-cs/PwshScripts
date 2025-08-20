#!/usr/bin/env nu
#------------------------------------------------------------------------------
# .SYNOPSIS
#   Initialize Specified Application
# .DESCRIPTION
#   TODO: Add Linux support (remove ~/bin when it doesn't exist)
#   Initializes shell/env for application
#   rewrite of pwsh/Init-App.ps1 *
#
# .EXAMPLE
#   init-app reset-env-path
#
# .NOTES
#   Not working on NuShell yet, hence moved to init.nu for now
#   Targeting apps i.e., choco, python (ML).
#   Required Env Vars:
#     - $pfiles_x64_dir
#------------------------------------------------------------------------------

def main [
  app_name: string = 'reset-env-path'     # Name of app for which to init
] {
  print $"Init for app: ($app_name)"
  # ShellHome from config.nu isn't available here on win for some reason
  let ShellHome = "D:\\Code\\shell"
  let pfiles_x64_dir = "C:\\PFiles_x64\\choco"

  print $"Current env Path: ($env.Path)"

  match $app_name {
    'git' => {
      let git_path = ($pfiles_x64_dir | path join 'git' 'cmd')
      $env.Path = ($env.Path | append $git_path)
      # $env.Path = ($env.Path | append "C:\\PFiles_x64\\choco\\git\\cmd")
      print $"Added to PATH: ($git_path)"
    }
    'reset-env-path' => {
      # Example: Reset PATH to default
      $env.Path = ( [
        ($env.SystemRoot | path join 'system32'),
        $env.SystemRoot,
        ($env.SystemRoot | path join 'System32' 'Wbem'),
        ($env.LOCALAPPDATA | path join 'Microsoft' 'WindowsApps'),
        $ShellHome,
        ($env.SystemRoot | path join 'System32' 'OpenSSH'),
        ($env.SystemRoot | path join 'System32' 'WindowsPowerShell' 'v1.0')
      ])
    }
    _ => {
      print $"Invalid command line argument: ($app_name)"
    }
  }

  print $"Updated env Path: ($env.Path)"
}