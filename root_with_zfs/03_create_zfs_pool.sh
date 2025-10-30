#!/bin/bash
# -----------------------------------------------------------------------------
# Script : root_with_zfs/03_create_zfs_pool.sh
# Desc   : Create laptop-optimized ZFS root pool and datasets for Pop!_OS
# Date   : 10-30-2025
#
# Usage:
#   sudo ./03_create_zfs_pool.sh /dev/nvme0n1p2
#     - Assumes 01_create_gpt_parts.sh and 02_setup_ZBM.nu already ran
#     - Creates rpool on the specified ZFS partition
#     - Sets battery-friendly defaults and clean dataset layout
#
# Notes:
#   - prereq: 01_create_gpt_parts.sh and 02_setup_ZBM.nu
#   - root pool: uses OpenZFS latest, incompatible with illumos/opensolaris
#   - Requires root/sudo privileges
#   - Destroys ALL data on target partition
#   - Uses ZFS cachefile for deterministic import at boot
#   - I use nushell, but these shell scripts are here for convenience / public benefits
#   - if you need multi-boot with Windows also look at 'win/create_gpt_parts_win.nu'
#
# Deps: zfs-dkms, zfsutils-linux
#
# Refs:
#   - OpenZFS dataset & pool properties
#   - Ubuntu Root on ZFS structure
#   - ZFSBootMenu integration (separate step)
#
# tag: linux-only, destructive
# -----------------------------------------------------------------------------

# Boot pop_os latest live environment using first drive / first external SSD (/dev/sda)

# Prepare live environment

# Install essential tools
sudo apt install --yes vim gdisk wget2

# Install zfs-dkms on live env to use zfs commands
sudo apt install --yes zfs-dkms zfsutils-linux

# Install pop_os latest on a second external SSD (/dev/sdb) using pop_os installer

# Now open cosmic terminal on live environment to create zfs pools and datasets on your internal disk

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Verification function
verify_step() {
  if [[ $? -ne 0 ]]; then
    echo "ERROR: $1 failed"
    exit 1
  fi
}

# Check for partition argument
if [[ $# -ne 1 ]]; then
  echo "Usage: sudo $0 /dev/nvme0n1p2" >&2
  exit 1
fi

PARTITION="$1"

# Validate partition exists
if [[ ! -b "${PARTITION}" ]]; then
  echo "ERROR: Partition not found or not a block device: ${PARTITION}" >&2
  exit 1
fi

# Avoid re-creating an existing pool
if sudo zpool list -H -o name 2>/dev/null | grep -qx rpool; then
  echo "ERROR: pool 'rpool' already exists; export/destroy it first if re-running" >&2
  exit 1
fi

# Create root pool with laptop-friendly properties
sudo zpool create --force \
  --option ashift=12 \
  --option autotrim=off \
  --option cachefile=/etc/zfs/zpool.cache \
  --option compatibility=off \
  -O mountpoint=none \
  -O atime=off \
  -O xattr=sa \
  -O acltype=posixacl \
  -O compression=lz4 \
  -O dnodesize=auto \
  rpool "${PARTITION}"

verify_step "Pool creation"

# Create ROOT dataset container
sudo zfs create -o canmount=off -o mountpoint=none rpool/ROOT

# Create OS root filesystem dataset
sudo zfs create -o canmount=noauto -o mountpoint=/ rpool/ROOT/pop
sudo zpool set bootfs=rpool/ROOT/pop rpool

# Harden root dataset: prevent device node access
sudo zfs set devices=off rpool/ROOT/pop

# Create home dataset with metadata-only ARC caching
sudo zfs create \
  -o mountpoint=/home \
  -o primarycache=metadata \
  rpool/home

# On systems without L2ARC this property does nothing.
#  -o secondarycache=none \  # default: all

# Harden /home: no device nodes needed
sudo zfs set devices=off rpool/home

# Create /var container dataset
sudo zfs create -o canmount=off -o mountpoint=/var rpool/var

# Create /var/log with efficient write patterns for SSDs
sudo zfs create \
  -o mountpoint=/var/log \
  -o primarycache=metadata \
  -o logbias=throughput \
  rpool/var/log

# If you knowingly accept risk of recent log loss to save power:
sudo zfs set sync=disabled rpool/var/log

# Harden /var/log: no device nodes needed
sudo zfs set devices=off rpool/var/log

# /tmp: use system tmpfs instead of ZFS dataset
# Uncomment below if you prefer ZFS-backed /tmp:
# sudo zfs create \
#   -o mountpoint=/tmp \
#   -o sync=disabled \
#   -o primarycache=metadata \
#   rpool/tmp

# Optional: native encryption on laptops with AES-NI support
# Note: adds some CPU work; evaluate against your power budget
# sudo zfs set encryption=aes-256-gcm rpool/ROOT/pop
# sudo zfs set keyformat=passphrase rpool/ROOT/pop

# Export pool cleanly to finalize cachefile state
sudo zpool export rpool

echo "SUCCESS: rpool created and exported on ${PARTITION}"
echo "Next: proceed with rsync to copy system from install media"