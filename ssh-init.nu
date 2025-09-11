#!/usr/bin/env nu
# -----------------------------------------------------------------------------
# Script : ssh-init.nu
# Desc   : SSH agent initialization and key loading for Nushell sessions.
#          Manages SSH agent lifecycle by persisting agent info to temp files
#          and reusing existing agents when available. Automatically loads
#          SSH keys after agent initialization.
#
# Date   : 09-10-2025
# Deps   : ssh-agent, ssh-add, Nushell core commands (path, load-env, save)
#
# Usage:
# source ssh-init.nu    # (typically called from init.nu via source)
#  - Checks for existing SSH agent via temp file in $nu.temp-path
#  - Reuses agent if process is still running, otherwise starts new one
#  - Parses ssh-agent output and loads environment variables
#  - Persists agent info to temp file for future session reuse
#  - Automatically runs ssh-add to load default SSH keys
#
# Notes:
#  - Part of config.nu initialization chain (sourced from init.nu)
#  - Uses do --env block to ensure environment changes persist
#  - Temp file naming: ssh-agent-{USER}.nuon for multi-user safety
#  - Validates agent process via /proc/{PID} existence check
#  - Cleans up stale temp files when agent processes are dead
#
# Flow:
#  1. Check if temp file exists with previous agent info
#  2. If exists, verify agent process is still running
#  3. If running, load existing env vars and return
#  4. If not running, clean up stale file and start new agent
#  5. Parse ssh-agent -c output into environment variables
#  6. Save agent info to temp file for future reuse
#  7. Add SSH keys using ssh-add
#
# tag: ssh, cross-platform
# -----------------------------------------------------------------------------

# SSH agent initialization with persistent state management
do --env {
  # Construct temp file path for agent persistence
  let ssh_agent_file = (
    $nu.temp-path | path join $"ssh-agent-($env.USER).nuon"
  )
  
  # Check if we have a previous agent session
  if ($ssh_agent_file | path exists) {
    let ssh_agent_env = open ($ssh_agent_file)
    
    # Verify the agent process is still alive
    if ($"/proc/($ssh_agent_env.SSH_AGENT_PID)" | path exists) {
      # Reuse existing agent
      load-env $ssh_agent_env
      return
    } else {
      # Clean up stale agent file
      rm $ssh_agent_file
    }
  }
  
  # Start new SSH agent and parse environment output
  let ssh_agent_env = ssh-agent -c
  | lines
  | first 2
  | parse "setenv {name} {value};"
  | transpose --header-row
  | into record
  
  # Load agent environment variables into current session
  load-env $ssh_agent_env
  
  # Persist agent info for future sessions
  $ssh_agent_env | save --force $ssh_agent_file
}

# Load default SSH keys into the agent
ssh-add