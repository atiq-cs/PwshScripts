# Provide perpetual variables for the shell session
# - $ShellHome

# env.config.history.size is about 100k by default
# Modify window title, ref, https://github.com/nushell/nushell/issues/2527

# Works for all: $nu.os-info.family unix or win
let $ShellHome = $env.Home | path join "shell"

# User added changes
$env.PROMPT_COMMAND = {
  let user = (whoami)
  let host = (hostname)
  let pwd = (pwd)
  let home = $env.HOME
  let path = if ($pwd | str starts-with $ShellHome) { # gotta be first line
    $pwd | str replace $ShellHome "~*"     # since $home will always match
  } else if ($pwd | str starts-with $home) {   # otherwise
    $pwd | str replace $home "~"    # As a result, the other match will get skipped
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