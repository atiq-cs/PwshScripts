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
#   Targeting apps i.e., choco, python (ML).
#   Required Env Vars:
#     - $pfiles_x64_dir
#------------------------------------------------------------------------------

def main [
  app_name: string = 'reset-env-path'   # Name of app for which to init
] {
  print $"Init for app: ($app_name)"

  let pfiles_x64_dir = "C:\\PFiles_x64\\choco"
  let prior_env_path = $env.Path

  match $app_name {
    'git' => {
      let git_path = ($pfiles_x64_dir | path join 'git' 'cmd')
      let path_with_git = ($prior_env_path | append $git_path)
      $path_with_git
    }
    'reset-env-path' => {
      # Reset PATH to default
      [
        ($env.SystemRoot | path join 'system32'),
        $env.SystemRoot,
        ($env.SystemRoot | path join 'System32' 'Wbem'),
        ($env.LOCALAPPDATA | path join 'Microsoft' 'WindowsApps'),
        ($env.SystemRoot | path join 'System32' 'OpenSSH'),
        # ($env.SystemRoot | path join 'System32' 'WindowsPowerShell' 'v1.0'),
        $ShellHome
      ]
    }
    _ => {
      print $"Invalid command line argument: ($app_name)"
      $prior_env_path
    }
  }
}