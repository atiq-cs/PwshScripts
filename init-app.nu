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

def --env init-app [
  app_name: string = 'reset-env-path'   # Name of app for which to init
] {
  let pfiles_x64_dir = "C:\\PFiles_x64\\choco"

  match $app_name {
    # 'git' => managed via /usr/bin emulation
      # not required in Unix, return default
    #   if ($nu.os-info.name != "windows") {
    #     # No changes needed for Unix
    #   } else {
    #     let git_path = ($pfiles_x64_dir | path join 'git' 'cmd')
    #     $env.Path = ($env.Path | append $git_path)
    #   }
    # }
    'reset-env-path' => {
      # Reset PATH to platform-specific default
      # Expected default system PATH for comparison
      mut expected_system_path = [
        "/usr/bin",
        "/usr/sbin",
        "/usr/local/bin",
        ($env.HOME | path join '.local' 'sdkman' 'candidates' 'kotlin' 'current' 'bin'),
        ($env.HOME | path join '.local' 'sdkman' 'candidates' 'java' 'current' 'bin'),
        ($env.HOME | path join '.local' 'sdkman' 'candidates' 'gradle' 'current' 'bin'),
        ($env.HOME | path join '.local' 'bin')  # chezmoi
      ]

      if ($nu.os-info.name != "windows") {
        # backup of /etc/environment in configs dir
        # Check if current PATH differs from expected
        if ($env.Path != $expected_system_path) {
          print "WARN: System environment PATH has changed from expected defaults:"
          print $"Actual: ($env.Path)"
          print ""
          print $"Expected: ($expected_system_path)"
          print ""
        }
      } else {
        $expected_system_path = [
          ($env.SystemRoot | path join 'system32'),
          $env.SystemRoot,
          ($env.SystemRoot | path join 'System32' 'Wbem'),
          ($env.LOCALAPPDATA | path join 'Microsoft' 'WindowsApps'),
          ($env.SystemRoot | path join 'System32' 'OpenSSH'),
          # ($env.SystemRoot | path join 'System32' 'WindowsPowerShell' 'v1.0'),
          "C:\\PFiles_x64\\bin"  # /usr/bin emulation
        ]
      }

      # Assign to $env.Path instead of returning
      $env.Path = ($expected_system_path | append $ShellHome)
      print "Init: env.Path"
    }
    _ => {
      error make {
        msg: "Invalid argument",
        label: {
          text: $"Unknown app_name: ($app_name)",
          span: (metadata $app_name).span
        }
      }
    }
  }
}


# This runs when sourced
init-app 'reset-env-path'