#!/usr/bin/env nu
-----------------------------------------------------------------------------
# Script : sdkman-patch.nu
# Desc   : Install SDKMAN and apply patches to fix Nushell compatibility
# Date   : 10-27-2025
#
# Usage:
#   ./sdkman-patch.nu
#     - Installs SDKMAN via bash (if not present)
#     - Installs specified SDK tools via bash
#     - Applies patches to ~/.local/sdkman for Nushell compatibility
#
# Notes:
#   - Run from directory containing configs/sdkman/ with patch files
#   - Requires bash, patch, wget/curl utilities
#   - SDK commands must run in bash shell, not nushell
#
# tag: linux-only
# -----------------------------------------------------------------------------

# Install SDKMAN if not present (requires bash)
if not ('~/.local/sdkman' | path exists) {
  print "Installing SDKMAN..."
  # wet2 --quiet --output-document - https://get.sdkman.io | bash
  # update .bashrc
}

# Install SDK tools (must run in bash environment)
print "Installing SDK tools..."
# env.Path is managed by init.sh
# source ~/.local/sdkman/bin/sdkman-init.sh
sdk install gradle 9.1.0
sdk install java 24.0.2-tem
sdk install kotlin 2.2.21     # doesn't target JVM 25 yet

# Apply patches for Nushell compatibility
# glob on configs/sdkman should also work
for patch_file in [configs/sdkman/sdkman-init.patch configs/sdkman/sdkman-path-helpers.patch] {
  print $"Applying ($patch_file)..."
  # not sure if this would work
  #  patch -d ~/.local/sdkman -p0
  open $patch_file | patch -d / -p0
}

print "Done! Restart your shell or source the config."