#!/usr/bin/env bash
# =============================================================================
# Solaris GPT Partition Creator - OpenIndiana/illumos System Layout
# -----------------------------------------------------------------------------
# Purpose : Create GPT partition layout optimized for OpenIndiana/illumos systems.
#           Sets up ESP, Solaris root ZFS pool, data partition, and reserved partition.
# Usage   : Run after disk_hammer_illumos.sh to create clean partition layout.
#           Set DISK_DEVICE variable to your target disk.
# Notes   : - Requires prior run of disk_hammer_illumos.sh for clean disk state
#           - Creates 4 partitions: ESP (512MB), Solaris root, data, reserved (8MB)
#           - Uses proper Solaris partition type codes (BF00, BF05, BF07)
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

# Configuration: Solaris root partition size (adjust as needed)
SOLARIS_ROOT_SIZE_GB=128
SOLARIS_ROOT_END_MIB=$((513 + SOLARIS_ROOT_SIZE_GB * 1024))

echo "Creating GPT partition layout on /dev/$DISK_DEVICE"
echo "Solaris root partition will be ${SOLARIS_ROOT_SIZE_GB}GB"
echo "Press Ctrl+C within 5 seconds to cancel..."
sleep 5

# Prerequisite: Clean/hammer GPT partition table using disk_hammer_illumos.sh
echo "NOTE: Ensure you have run disk_hammer_illumos.sh first for clean disk state"

# Layout: 4 partitions total
# 1. ESP (EFI System Partition) - 512MB FAT32 for UEFI boot
# 2. Solaris root ZFS pool - configurable size for system installation  
# 3. Data partition - remaining space for user data/additional pools
# 4. Solaris reserved - traditional 8MB marker at end of disk

# ===== Partition 1: EFI System Partition (ESP) =====
echo "Creating partition 1: EFI System Partition (512MB)..."
# Create 512MB ESP partition starting at 1MiB for proper alignment
sudo parted /dev/$DISK_DEVICE 'mkpart "EFI System Partition" fat32 1MiB 513MiB'
# Set ESP and boot flags required for UEFI systems
sudo parted /dev/$DISK_DEVICE set 1 esp on
sudo parted /dev/$DISK_DEVICE set 1 boot on
# Format as FAT32 with "EFI" label for bootloader compatibility
sudo mkfs.fat -F 32 -n EFI /dev/${DISK_DEVICE}p1 || sudo mkfs.fat -F 32 -n EFI /dev/${DISK_DEVICE}1

# ===== Partition 2: Solaris Root Pool =====
echo "Creating partition 2: Solaris root pool (${SOLARIS_ROOT_SIZE_GB}GB)..."
# Create partition for OpenIndiana/illumos root ZFS pool
sudo parted /dev/$DISK_DEVICE mkpart "solaris" 513MiB ${SOLARIS_ROOT_END_MIB}MiB
# Set Solaris root partition type (BF00) for proper recognition by illumos tools
sudo sgdisk --typecode=2:BF00 /dev/$DISK_DEVICE

# ===== Partition 4: Solaris Reserved (create before data partition) =====
echo "Creating partition 4: Solaris reserved (8MB at end of disk)..."
# Calculate sectors for 8MB reserved partition at end of disk
# Get total sectors, reserve last 1MB, then place 8MB reserved partition before it
TOTAL_SECTORS=$(sudo blockdev --getsz /dev/$DISK_DEVICE)
LAST_USABLE_SECTOR=$((TOTAL_SECTORS - 2048))  # Reserve last 1MB (2048 sectors)
RESERVED_START_SECTOR=$((LAST_USABLE_SECTOR - 16384))  # 8MB = 16384 sectors

# Create traditional Solaris reserved partition for compatibility
sudo parted /dev/$DISK_DEVICE unit s mkpart solaris_reserved \
  $RESERVED_START_SECTOR $LAST_USABLE_SECTOR
# Set Solaris reserved partition type (BF07)
sudo sgdisk --typecode=4:BF07 /dev/$DISK_DEVICE

# ===== Partition 3: Data Partition =====
echo "Creating partition 3: Data partition (remaining space)..."
# Create data partition using remaining space between root and reserved partitions
# parted will automatically use available space up to the reserved partition
sudo parted /dev/$DISK_DEVICE mkpart data ${SOLARIS_ROOT_END_MIB}MiB -8200MiB
# Set Solaris /home partition type (BF05) for user data
sudo sgdisk --typecode=3:BF05 /dev/$DISK_DEVICE

# ===== Display final partition layout =====
echo ""
echo "Partition layout created successfully:"
sudo parted /dev/$DISK_DEVICE print
echo ""
echo "Partition type codes set:"
echo "  Partition 1: ESP (EFI System Partition)"
echo "  Partition 2: BF00 (Solaris root)"  
echo "  Partition 3: BF05 (Solaris /home)"
echo "  Partition 4: BF07 (Solaris reserved)"
echo ""
echo "Ready for OpenIndiana/illumos installation!"
