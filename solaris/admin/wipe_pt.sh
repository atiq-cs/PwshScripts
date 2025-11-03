#!/usr/bin/env bash
# =============================================================================
# Partition Table Wiper for illumos - Complete Disk Cleanup Utility
# -----------------------------------------------------------------------------
# Purpose : Completely wipe disk metadata for clean illumos/OpenIndiana setup.
#           illumos tools (prtvtoc, fmthard, format, zfs) can behave buggy
#           when encountering metadata/records from previously deleted partitions.
# Usage   : ./wipe_pt.sh -d /dev/sdX
#           ./wipe_pt.sh --target-disk /dev/nvme0n1
# Notes   : - Must be run as root/sudo for all operations
#           - More thorough than standard Linux disk wiping for illumos compat
# =============================================================================

# Function to display usage information
usage() {
    echo "Usage: $0 -d DEVICE | --target-disk DEVICE"
    echo ""
    echo "Options:"
    echo "  -d, --target-disk DEVICE    Target disk device"
    echo "                              (e.g., /dev/sda, /dev/nvme0n1)"
    echo "  -h, --help                  Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -d /dev/sda"
    echo "  $0 --target-disk /dev/nvme0n1"
    exit 1
}

# Function to handle fatal errors
fail() {
    echo "ERROR: $1" >&2
    exit 1
}

# Function to get user confirmation
confirm() {
    local prompt="$1"
    local response
    while true; do
        echo -n "$prompt (y/N): "
        read -r response
        case "$response" in
            [Yy]|[Yy][Ee][Ss])
                return 0
                ;;
            [Nn]|[Nn][Oo]|"")
                return 1
                ;;
            *)
                echo "Please answer yes (y) or no (n)."
                ;;
        esac
    done
}

# Parse command line arguments (supports both short and long options)
DISK_DEVICE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--target-disk)
            if [[ -n $2 && $2 != -* ]]; then
                DISK_DEVICE="$2"
                shift 2
            else
                fail "--target-disk requires a non-empty option argument"
            fi
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Check if device was specified
if [[ -z $DISK_DEVICE ]]; then
    echo "ERROR: No device specified"
    usage
fi

# Validate that the device exists and is a block device
[[ -b $DISK_DEVICE ]] || fail "no such block device $DISK_DEVICE"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    fail "This script must be run as root"
fi

echo "Target device: $DISK_DEVICE"
echo ""
echo "WARNING: This operation will COMPLETELY DESTROY all data on $DISK_DEVICE"
echo "This includes:"
echo "  - All partitions and their data"
echo "  - Filesystem signatures"
echo "  - Boot sectors and partition tables"
echo "  - First and last 16MB of disk content"
echo ""

# Get confirmation from user
if ! confirm "Are you absolutely sure you want to proceed?"; then
    echo "Operation cancelled."
    exit 0
fi

# Install required tools for comprehensive disk wiping
echo "Installing required tools..."
# Replace with 'dnf install --assume-yes' for Fedora-based systems
# util-linux provides wipefs, parted handles partition tables, 
# gdisk provides sgdisk
apt update && apt install --yes --quiet parted gdisk util-linux

# Steps 1-5: Complete disk sanitization process

# Step 1: Remove filesystem signatures and partition metadata
# Wipes all filesystem signatures from the entire disk (not just partitions)
# This handles ext4, NTFS, ZFS, and other filesystem metadata
echo ""
echo "Step 1: Wiping filesystem signatures..."
wipefs --all --force "$DISK_DEVICE" || \
    fail "Failed to wipe filesystem signatures"

# Step 2: Destroy both GPT and MBR partition table structures
# Creates a completely clean slate for new partitioning
echo "Step 2: Destroying partition tables..."
sgdisk --zap-all "$DISK_DEVICE" || \
    fail "Failed to destroy partition tables"

# Steps 3-5: Zero out critical disk areas (required for illumos compatibility)
# illumos is more sensitive to residual data than Linux

# Clears boot sectors, partition tables, and filesystem headers
echo "Step 3: Zeroing first 16MB of disk..."
dd if=/dev/zero of="$DISK_DEVICE" bs=1M count=16 status=progress \
    conv=sync || fail "Failed to zero beginning of disk"

echo "Step 4: Calculating disk size and zeroing last 16MB..."

# Get actual logical sector size of the device (512 for traditional, 4096 for 4Kn)
SECTOR_SIZE=$(blockdev --getss "$DISK_DEVICE") || \
    fail "Failed to get sector size"
echo "Logical sector size: $SECTOR_SIZE bytes"

# Get the total disk size in sectors
TOTAL_SECTORS=$(blockdev --getsz "$DISK_DEVICE") || \
    fail "Failed to get disk size"
echo "Total sectors: $TOTAL_SECTORS"

# Calculate MB conversion factor based on actual sector size
# For 512-byte sectors: 2048 sectors = 1MB (512 * 2048 = 1048576)
# For 4096-byte sectors: 256 sectors = 1MB (4096 * 256 = 1048576)
MB_CONVERSION=$((1048576 / SECTOR_SIZE))
echo "Sectors per MB: $MB_CONVERSION"

# Calculate seek offset: convert total sectors to MB, then subtract 16MB
SEEK_OFFSET=$((TOTAL_SECTORS / MB_CONVERSION - 16))
echo "Seek offset (MB): $SEEK_OFFSET"

dd if=/dev/zero of="$DISK_DEVICE" bs=1M count=16 seek=$SEEK_OFFSET \
    status=progress conv=sync || fail "Failed to zero end of disk"

# Step 5: Clean up the final sectors with precise sector-level addressing
# Handles any rounding errors from MB-based calculations above
echo "Step 5: Final cleanup of last 1MB with sector precision..."

# Calculate sectors in 1MB based on actual sector size
SECTORS_PER_MB=$MB_CONVERSION
OFFSET_SECTOR=$((TOTAL_SECTORS - SECTORS_PER_MB))
echo "Final sector offset: $OFFSET_SECTOR"

dd if=/dev/zero of="$DISK_DEVICE" bs="$SECTOR_SIZE" count="$SECTORS_PER_MB" \
    seek=$OFFSET_SECTOR status=progress conv=sync || \
    fail "Failed final sector cleanup"

echo "SUCCESS: Disk cleanup complete!"
echo ""
echo "$DISK_DEVICE is now ready for illumos installation or zfs/zpool creation commands."
echo "After running this script, illumos partition management tools should work"
echo "without issues."
