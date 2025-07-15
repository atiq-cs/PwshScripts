# -----------------------------------------------------------------------------
# Provide perpetual variables for the shell session
# - $ShellHome

# env.config.history.size is about 100k by default
# Modify window title, ref, https://github.com/nushell/nushell/issues/2527
#
# Note: this script is part of config.nu
#  not exposing $homeDir for whole session hence, initialized inside $env.PROMPT_COMMAND block
#
# tag: cross-platform
# -----------------------------------------------------------------------------

# Detect OS and set $env.Home accordingly
let $ShellHome = (if ($nu.os-info.name == "windows") { "D:\\Code" } else { $env.Home }) | path join "shell"

# User added changes
$env.PROMPT_COMMAND = {
  let user = (whoami)
  let host = (hostname)
  let pwd = (pwd)
  # homeDir is declared here so that it is not exposed for the whole session
  #  since we are in config.nu
  let homeDir = if ($nu.os-info.name == "windows") { "D:\\Code" } else { $env.Home }
  let path = if ($pwd | str starts-with $ShellHome) { # gotta be first line
    $pwd | str replace $ShellHome "~*"     # since $home will always match
  } else if ($pwd | str starts-with $homeDir) {   # otherwise
    $pwd | str replace $homeDir "~"    # As a result, the other match will get skipped
  } else {
    $pwd
  }

  $"($user)@($host) (ansi cyan)($path)(ansi reset)"
}

$env.PROMPT_INDICATOR = "$ "

# editor
$env.config.buffer_editor = "code"

# Remove welcome msg / banner
$env.config.show_banner = false

# Custom Cmds
cd $ShellHome

# Put in our welcome banner
print $"Welcome to (ansi green)Matrix Terminal(ansi reset)"
print $"NuShell ($env.NU_VERSION) on ($nu.os-info.name) ($nu.os-info.kernel_version)"
print ""

# Porting tasks TODO
#  InitConsoleUI
#  resetEnvPath and app specific adjustments that are coming from sdkman ?