#!/bin/bash
# -----------------------------------------------------------------------------
# Script : root_with_zfs/06_post_install.sh
# Desc   : Post-install configuration after first boot into ZFS root
# Date   : 10-30-2025
#
# Usage:
#   sudo ./06_post_install.sh
#     - Run after first successful boot into ZFS root system
#     - Removes systemd-udev-settle dependencies from ZFS services
#     - Verifies ZFS module parameters are active
#     - Optional: sets hostname and adjusts Pop!_OS package priorities
#
# Notes:
#   - systemctl edit cannot run in chroot, must be done post-boot
#   - Removing systemd-udev-settle deps improves boot time significantly (~30-90s)
#   - ZFS parameter verification confirms initramfs rebuild worked
#   - apt-mark hold commands are already in 05_chroot.sh (kept here for safety)
#
# Refs:
#   - systemd-udev-settle deprecation (OpenZFS issue #10891)
#   - ZFS service dependencies and boot optimization
#
# tag: linux-only, post-boot-only
# -----------------------------------------------------------------------------

set -euo pipefail

# Set hostname (optional, customize as needed)
sudo hostnamectl set-hostname TuringMachine

# Cleanup unnecessary packages if not removed earlier
# Note: Already done in 05_chroot.sh, but kept as safety net
sudo apt remove --yes --purge libreoffice* || true
sudo apt autoremove --yes
sudo apt clean --yes

# Remove systemd-udev-settle dependencies from ZFS services
# This MUST be done post-boot (systemctl edit doesn't work in chroot)
# Improves boot time by eliminating deprecated service wait (~30-90s savings)
#
# For each service, remove lines containing:
#   - Requires=systemd-udev-settle.service
#   - After=systemd-udev-settle.service
#   - After=cryptsetup.target (if present, not needed without encryption)
#
# Ref: github.com/openzfs/zfs/issues/10891
echo "Editing ZFS service units to remove systemd-udev-settle dependencies..."
echo "Remove lines: Requires=systemd-udev-settle.service and After=systemd-udev-settle.service"
sudo systemctl edit --full zfs-import-cache.service
sudo systemctl edit --full zfs-load-module.service

# Verify systemd-udev-settle is no longer pulled in by ZFS
echo "Verifying systemd-udev-settle dependencies (should show minimal or no ZFS services):"
systemctl list-dependencies --reverse systemd-udev-settle.service

# Optionally mask systemd-udev-settle to prevent any service from using it
# Uncomment if you want to enforce no usage of this deprecated service
# sudo systemctl mask systemd-udev-settle.service

# Adjust Pop!_OS package priority (optional)
# Default 1001 is aggressive (always prefers Pop repos); 610 is standard Ubuntu priority
# Edit to your preference: 1001=aggressive, 610=standard, 500=equal to Ubuntu
echo "Review and adjust Pop!_OS apt priority (current: likely 1001)"
sudo vim /etc/apt/preferences.d/pop-default-settings

# Verify ZFS module parameters are active (from /etc/modprobe.d/zfs.conf)
echo "Verifying ZFS module parameters:"
echo -n "  zfs_arc_max: "
cat /sys/module/zfs/parameters/zfs_arc_max
echo -n "  zfs_arc_min: "
cat /sys/module/zfs/parameters/zfs_arc_min
echo -n "  zfs_txg_timeout: "
cat /sys/module/zfs/parameters/zfs_txg_timeout
echo -n "  zfs_prefetch_disable: "
cat /sys/module/zfs/parameters/zfs_prefetch_disable

# Check available space on ESP
echo "ESP filesystem info:"
mount | grep efi
df --human-readable /boot/efi

# Safety: Hold bootloader packages and mask pop-boot
# Note: Already done in 05_chroot.sh, but repeated here for robustness
# Prevents Pop!_OS updates from overwriting ZFSBootMenu configuration
sudo apt-mark hold efibootmgr grub-common grub-efi-amd64 grub-pc systemd-boot
sudo systemctl mask pop-boot