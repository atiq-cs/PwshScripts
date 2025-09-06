#!/usr/bin/env bash
# =============================================================================
# Disk Hammer for illumos - Complete Disk Cleanup Utility
# -----------------------------------------------------------------------------
# Purpose : Completely wipe disk metadata for clean illumos/OpenIndiana setup.
#           illumos tools (prtvtoc, fmthard, format, zfs) can behave buggy
#           when encountering metadata/records from previously deleted partitions.
# Usage   : Run from Linux before installing illumos to ensure clean disk state.
#           Set DISK_DEVICE variable to your target disk (e.g., sda, nvme0n1)
# Notes   : - Must be run as root/sudo for all operations
#           - Update DISK_DEVICE variable for your specific disk
#           - More thorough than standard Linux disk wiping for illumos compatibility
# =============================================================================

# Configuration: Set your target disk device here
# Examples: sda, sdb, nvme0n1, nvme1n1, etc.
DISK_DEVICE="sdX"  # CHANGE THIS TO YOUR ACTUAL DISK

# Validate that user has updated the device variable
if [ "$DISK_DEVICE" = "sdX" ]; then
    echo "ERROR: Please update DISK_DEVICE variable with your actual disk device name"
    echo "Examples: sda, sdb, nvme0n1, etc."
    exit 1
fi

# Install required tools for comprehensive disk wiping
# Replace with 'dnf install --assume-yes' for Fedora-based systems
# util-linux provides wipefs, parted handles partition tables, gdisk manages GPT
sudo apt install --yes parted gdisk util-linux

echo "WARNING: This will completely wipe /dev/$DISK_DEVICE"
echo "Press Ctrl+C within 10 seconds to cancel..."
sleep 10

# Step 1: Remove filesystem signatures and partition metadata
# Wipes all filesystem signatures from the entire disk (not just partitions)
# This handles ext4, NTFS, ZFS, and other filesystem metadata
echo "Step 1: Wiping filesystem signatures..."
sudo wipefs --all --force /dev/$DISK_DEVICE

# Step 2: Destroy both GPT and MBR partition table structures
# Creates a completely clean slate for new partitioning
echo "Step 2: Destroying partition tables..."
sudo sgdisk --zap-all /dev/$DISK_DEVICE

# Steps 3-5: Zero out critical disk areas (required for illumos compatibility)
# illumos is more sensitive to residual data than Linux

# Step 3: Zero the beginning of the disk (first 16MB)
# Clears boot sectors, partition tables, and filesystem headers
echo "Step 3: Zeroing first 16MB of disk..."
sudo dd if=/dev/zero of=/dev/$DISK_DEVICE bs=1M count=16 status=progress conv=sync

# Step 4: Calculate and zero the end of the disk (last 16MB)
echo "Step 4: Calculating disk size and zeroing last 16MB..."
# Get the total disk size in 512-byte sectors
TOTAL_SECTORS=$(sudo blockdev --getsz /dev/$DISK_DEVICE)
echo "Total sectors: $TOTAL_SECTORS"

# Calculate seek offset: sectors / 2048 - 16 (converts sectors to MB, minus 16MB)
SEEK_OFFSET=$((TOTAL_SECTORS / 2048 - 16))
echo "Seek offset (MB): $SEEK_OFFSET"

sudo dd if=/dev/zero of=/dev/$DISK_DEVICE bs=1M count=16 seek=$SEEK_OFFSET \
  status=progress conv=sync

# Step 5: Clean up the final sectors with precise sector-level addressing
# Handles any rounding errors from MB-based calculations above
echo "Step 5: Final cleanup of last 1MB with sector precision..."
# OFFSET_SECTOR = TOTAL_SECTORS - 2048 (last 1MB in 512-byte sectors)
OFFSET_SECTOR=$((TOTAL_SECTORS - 2048))
echo "Final sector offset: $OFFSET_SECTOR"

sudo dd if=/dev/zero of=/dev/$DISK_DEVICE bs=512 count=2048 seek=$OFFSET_SECTOR \
  status=progress conv=sync

echo "Disk cleanup complete! /dev/$DISK_DEVICE is now ready for illumos installation."
echo "After running this script, illumos partition management tools should work without issues."
