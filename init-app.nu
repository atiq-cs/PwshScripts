#!/usr/bin/env nu
#------------------------------------------------------------------------------
# .SYNOPSIS
#   Initialize application-specific env path
#
# .DESCRIPTION
#  Resets PATH to platform-specific defaults or adds application paths.
#  Notes:
#  - currently 2 apps: system default and git
#  - system defaults with SDKMAN tools on Unix/Linux
#  - On Windows, PFiles is currently used by git
#
# .PARAMETER app_name
#   Application to initialize: 'git', 'reset-env-path' (default)
#
# .EXAMPLE
#   source ./init-app.nu
#   $env.Path = (main APP_NAME)
#
# .NOTES
#   Platform-specific behavior:
#   - Windows: Uses SystemRoot, PFiles_x64 paths (overlaps with choco)
#   - Unix/Linux: Includes SDKMAN (Java, Kotlin, Gradle) + system paths
#   - Unix/Linux: Warns if current PATH differs from expected baseline
#   - Target apps: git, choco, python (ML) etc. more in future
#------------------------------------------------------------------------------

def main [
  app_name: string = 'reset-env-path'   # Name of app for which to init
] {
  print $"Init for app: ($app_name)"

  let pfiles_x64_dir = "C:\\PFiles_x64\\choco"
  let prior_env_path = $env.Path

  match $app_name {
    'git' => {
      # not required in Unix, return default
      if ($nu.os-info.name != "windows") {
        $prior_env_path
      } else {
        let git_path = ($pfiles_x64_dir | path join 'git' 'cmd')
        let path_with_git = ($prior_env_path | append $git_path)
        $path_with_git
      }
    }
    'reset-env-path' => {
      # Reset PATH to platform-specific default
      if ($nu.os-info.name != "windows") {
        # backup of /etc/environment in configs dir
        # Expected default system PATH for comparison
        let expected_system_path = [
          "/usr/bin",
          "/usr/sbin",
          "/usr/local/bin",
          "/home/atiq/.local/sdkman/candidates/kotlin/current/bin",
          "/home/atiq/.local/sdkman/candidates/java/current/bin",
          "/home/atiq/.local/sdkman/candidates/gradle/current/bin"
        ]
        
        # Check if current PATH differs from expected
        if ($env.Path != $expected_system_path) {
          print "WARN: System environment PATH has changed from expected defaults:"
          print $"Actual: ($env.Path)"
          print ""
          print $"Expected: ($expected_system_path)"
          print ""
        }

        # return standard system path with our shell's dir appended
        ($expected_system_path | append $ShellHome)
      } else {
        [
          ($env.SystemRoot | path join 'system32'),
          $env.SystemRoot,
          ($env.SystemRoot | path join 'System32' 'Wbem'),
          ($env.LOCALAPPDATA | path join 'Microsoft' 'WindowsApps'),
          ($env.SystemRoot | path join 'System32' 'OpenSSH'),
          # ($env.SystemRoot | path join 'System32' 'WindowsPowerShell' 'v1.0'),
          "C:\\PFiles_x64\\bin",  # /usr/bin emulation
          $ShellHome
        ]
      }
    }
    _ => {
      print $"Invalid command line argument: ($app_name)"
      $prior_env_path
    }
  }
}