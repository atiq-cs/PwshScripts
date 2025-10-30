#!/bin/bash
# -----------------------------------------------------------------------------
# Script : root_with_zfs/05_chroot.sh
# Desc   : Chroot into ZFS root and configure boot, initramfs, and services
# Date   : 10-30-2025
#
# Usage:
#   sudo ./05_chroot.sh
#     - Assumes rpool imported at /mnt with datasets mounted
#     - Bind-mounts pseudo-filesystems for chroot
#     - Installs ZFS initramfs, ZFSBootMenu integration, and laptop tunables
#     - Updates initramfs with battery-optimized ZFS module params
#
# Notes:
#   - Requires rpool/ROOT/pop mounted at /mnt
#   - Uses modern --rbind --make-rslave for clean mount propagation
#   - Removes Pop!_OS kernelstub and masks systemd-boot (ZFSBootMenu takes over)
#   - Sets zfs_arc_min and zfs_arc_max for laptops (requires initramfs rebuild)
#   - Disables systemd-udev-settle to eliminate boot delays
#
# Deps: zfsutils-linux, zfs-initramfs, efibootmgr
#
# Refs:
#   - https://www.perplexity.ai/search/based-on-all-the-experiences-i-rP0WwOZFQvy4s3U1fm1V_A#0
#   - OpenZFS Ubuntu Root on ZFS chroot steps
#   - ZFS module parameters (zfs_arc_max, zfs_txg_timeout)
#   - ZFSBootMenu org.zfsbootmenu:commandline property
#
# tag: linux-only, requires-chroot
# -----------------------------------------------------------------------------

set -euo pipefail

# Verify /mnt is a mountpoint
if ! mountpoint -q /mnt; then
  echo "ERROR: /mnt is not mounted; run 04_cp_install_image.sh first" >&2
  exit 1
fi

# Check partition table and fstab UUID
echo "Verify ESP partition UUID:"
ls -l /dev/disk/by-partuuid/
# Example: 0e0f7380-754e-4718-a299-a0b8aa34014a
echo "Edit /mnt/etc/fstab to match your ESP PARTUUID if needed:"
sudo vim /mnt/etc/fstab

# Enable tmpfs on /tmp (appends to chroot's fstab, not host)
if ! grep -q 'tmpfs /tmp tmpfs' /mnt/etc/fstab; then
  printf '%s\n' 'tmpfs /tmp tmpfs rw,nosuid,nodev,mode=1777,size=2G,nr_inodes=1000000 0 0' | sudo tee --append /mnt/etc/fstab > /dev/null
  echo "Added tmpfs /tmp to /mnt/etc/fstab"
fi

# Prepare chroot environment (modern bind-mount with --make-rslave for clean propagation)
# Yet to test this version of mount
for dir in dev dev/pts proc sys run; do
  sudo mkdir -p "/mnt/$dir"
  sudo mount --rbind "/$dir" "/mnt/$dir"
  sudo mount --make-rslave "/mnt/$dir"
done

# backup of prior mount cmds
# sudo mkdir -p /mnt/dev /mnt/dev/pts /mnt/proc /mnt/sys /mnt/run
# sudo mount --bind /dev /mnt/dev
# sudo mount --bind /dev/pts /mnt/dev/pts
# sudo mount --bind /proc /mnt/proc
# sudo mount --bind /sys /mnt/sys
# sudo mount --bind /run /mnt/run


echo "Entering chroot at /mnt..."

# Execute commands inside chroot via heredoc
sudo chroot /mnt /bin/bash <<'CHROOT_EOF'
set -euo pipefail

##################################################
## chroot starts
##################################################
mkdir /tmp

# Mount ESP to /boot/efi (adjust partition if needed)
mount /dev/nvme0n1p1 /boot/efi/
ls -a /boot/efi/

# Remove stale crypttab/swap refs (improves boot time by ~90s)
rm /etc/crypttab

# Remove Pop!_OS kernelstub (conflicts with ZFSBootMenu)
apt remove --yes --purge kernelstub

# Install ZFS initramfs and boot tooling
apt install --yes zfsutils-linux zfs-initramfs efibootmgr zfs-dkms

# Optional: remove bloat to save space
apt remove --yes --purge libreoffice* || true
apt autoremove --yes
apt clean --yes

# Hold bootloader packages to prevent Pop!_OS updates from conflicting with ZFSBootMenu
apt-mark hold efibootmgr grub-common grub-efi-amd64 grub-pc systemd-boot

# Mask Pop!_OS boot service (ZFSBootMenu replaces it)
systemctl mask pop-boot

# Add zfs module to initramfs
echo "zfs" >> /etc/initramfs-tools/modules

# Ensure cachefile exists for import-cache
mkdir /etc/zfs
zpool set cachefile=/etc/zfs/zpool.cache rpool

# Generate hostid for consistent pool imports
zgenhostid

# Disable slow boot services
systemctl disable --now NetworkManager-wait-online.service
systemctl disable --now cups-browsed.service

# Enable ZFS services (cache-based import, no scanning)
systemctl enable zfs-import-cache.service zfs-mount.service zfs-zed.service
# zfs-import-scan is needed when we are not using cachefile
systemctl disable --now zfs-import-scan.service zfs-share.service zfs-volume-wait.service

# Disable resume (no swap)
echo 'RESUME=none' > /etc/initramfs-tools/conf.d/resume

# Battery-optimized ZFS module params (requires initramfs rebuild)
cat << 'EOF' > /etc/modprobe.d/zfs.conf
# Limit ARC to 2GB on laptops
options zfs zfs_arc_max=2147483648

# Batch writes every 15s (balance between safety and power)
options zfs zfs_txg_timeout=15

# Disable prefetch to save random reads on battery
options zfs zfs_prefetch_disable=1
EOF

# Not required: default is 10: Reduce dirty data threshold to avoid write spikes
# options zfs zfs_dirty_data_max_percent=10

# Trigger udev rules for ZFS devices
# run after udev rules are updated
# ref, https://docs.zfsbootmenu.org/en/v3.0.x/guides/ubuntu/uefi.html
udevadm trigger

# final update initramfs, if kernel version installed is same as live's may be..
update-initramfs -u -k `uname --kernel-release`

# Unmount ESP before exiting chroot
umount /boot/efi/

exit
CHROOT_EOF

echo "Exited chroot successfully"

# To test this version: cleanup bind mounts (reverse order, recursive unmount)
for dir in run sys dev/pts dev proc; do
  sudo umount --recursive "/mnt/$dir" 2>/dev/null || true
done

# backup of prior mount cmds
# sudo umount /mnt/run
# sudo umount /mnt/proc
# sudo umount /mnt/dev/pts
# sudo umount /mnt/dev
# sudo umount -l /mnt/sys

# Check for lingering mounts
if sudo lsof +f -- /mnt/sys 2>/dev/null; then
  echo "WARNING: /mnt/sys still has open files"
fi

# Unmount all ZFS datasets, check if auto unmount works for /
sudo zfs umount -a

# backup of prior umount cmds
## sudo zfs umount rpool/tmp
# sudo zfs umount rpool/var/log
# sudo zfs umount rpool/home
# sudo zfs umount rpool/ROOT/pop

# Verify umount
if zfs mount | grep -q rpool; then
  echo "ERROR: ZFS datasets still mounted" >&2
  zfs mount | grep rpool
  exit 1
else
  echo "Clean: all ZFS datasets unmounted"
fi

# Configure ZFSBootMenu kernel command line (exclude root=, ZBM adds it)
# Note: nvidia-drm.modeset=1 can cause issues; test without if problems occur

# Debugging Notes
# may be try loglevel 6: KERN_INFO in case we want, 7: KERN_DEBUG might be much
# add when debugging is required
#  loglevel=6 systemd.show_status=true systemd.log_level=debug

HOSTID=$(hostid)
sudo zfs set org.zfsbootmenu:commandline="ro loglevel=4 nvidia-drm.modeset=1 spl.spl_hostid=0x${HOSTID}" rpool/ROOT/pop

# org.zfsbootmenu:name is not a documented ZFSBootMenu property
# sudo zfs set org.zfsbootmenu:name="pop_os 24.04" rpool/ROOT/pop

# Export pool cleanly
sudo zpool export rpool

echo "SUCCESS: chroot configuration complete, rpool exported"
echo "Next: reboot into ZFSBootMenu"