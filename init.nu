# env.config.history.size is about 100k by default
# Modify window title, ref, https://github.com/nushell/nushell/issues/2527

# User added changes
$env.PROMPT_COMMAND = {
  let user = (whoami)
  let host = (hostname)
  let pwd = (pwd)
  let home = $env.HOME
  let path = if ($pwd | str starts-with $home) {
    $pwd | str replace $home "~"
  }

  $"($user)@($host) (ansi cyan)($path)(ansi reset)"
}

$env.PROMPT_INDICATOR = "$ "

# Remove welcome msg / banner
$env.config.show_banner = false

# editor
$env.config.buffer_editor = "code"

print $"Welcome to (ansi green)Matrix Terminal(ansi reset)"
print $"NuShell ($env.NU_VERSION) on (^uname --kernel-release)"
print ""

# Porting tasks TODO
#  InitConsoleUI
#  resetEnvPath and app specific adjustments that are coming from sdkman ?