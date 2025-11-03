#!/usr/bin/env bash
# =============================================================================
# Solaris GPT Partition Creator - OpenIndiana/illumos System Layout
# -----------------------------------------------------------------------------
# Purpose : Create GPT partition layout optimized for OpenIndiana/illumos 
#           systems. Sets up ESP, Solaris root ZFS pool, data partition, and 
#           reserved partition.
# Usage   : ./create_gpt_parts.sh -d /dev/sdX
#           ./create_gpt_parts.sh --target-disk /dev/nvme0n1
# Notes   : - Requires prior run of wipe_pt.sh for clean disk state
#           - Creates 4 partitions: ESP (512MB), Solaris root, data, reserved 
#           - Uses proper Solaris partition type codes (BF00, BF05, BF07)
#           - Works with both 512-byte and 4Kn disks
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

# Get disk information for sector size calculations
SECTOR_SIZE=$(blockdev --getss "$DISK_DEVICE") || \
    fail "Failed to get sector size"
TOTAL_SECTORS=$(blockdev --getsz "$DISK_DEVICE") || \
    fail "Failed to get disk size"

echo "Disk information:"
echo "  Device: $DISK_DEVICE"
echo "  Logical sector size: $SECTOR_SIZE bytes"
echo "  Total sectors: $TOTAL_SECTORS"

# Configuration: Solaris root partition size (adjust as needed)
SOLARIS_ROOT_SIZE_GB=128
SOLARIS_ROOT_END_MIB=$((513 + SOLARIS_ROOT_SIZE_GB * 1024))

echo ""
echo "Creating GPT partition layout optimized for OpenIndiana/illumos"
echo ""
echo "Planned partition layout:"
echo "  1. ESP (EFI System Partition) - 512MB FAT32 for UEFI boot"
echo "  2. Solaris root ZFS pool - ${SOLARIS_ROOT_SIZE_GB}GB for system"
echo "  3. Data partition - remaining space for user data/additional pools"
echo "  4. Solaris reserved - 8MB traditional marker at end of disk"
echo ""

# Prerequisite check
echo "NOTE: Ensure you have run wipe_pt.sh first for clean disk state"
echo ""

# Get confirmation from user
if ! confirm "Proceed with creating partition layout?"; then
    echo "Operation cancelled."
    exit 0
fi

# Initialize GPT label on the disk
echo ""
echo "Initializing GPT label on $DISK_DEVICE..."
parted "$DISK_DEVICE" mklabel gpt || \
    fail "Failed to create GPT label on $DISK_DEVICE"

# Layout: 4 partitions total
# 1. ESP (EFI System Partition) - 512MB FAT32 for UEFI boot
# 2. Solaris root ZFS pool - configurable size for system installation  
# 3. Data partition - remaining space for user data/additional pools
# 4. Solaris reserved - traditional 8MB marker at end of disk

# ===== Partition 1: EFI System Partition (ESP) =====
echo ""
echo "Creating partition 1: EFI System Partition (512MB)..."
# Create 512MB ESP partition starting at 1MiB for proper alignment
# MiB units automatically handle sector size alignment
parted "$DISK_DEVICE" \
    'mkpart "EFI System Partition" fat32 1MiB 513MiB' || \
    fail "Failed to create ESP partition"

# Set ESP and boot flags required for UEFI systems
parted "$DISK_DEVICE" set 1 esp on || \
    fail "Failed to set ESP flag"
parted "$DISK_DEVICE" set 1 boot on || \
    fail "Failed to set boot flag"

# Format as FAT32 with "EFI" label for bootloader compatibility
# Handle both NVMe (p1) and SATA (1) partition naming
if [[ $DISK_DEVICE =~ nvme ]]; then
    ESP_PARTITION="${DISK_DEVICE}p1"
else
    ESP_PARTITION="${DISK_DEVICE}1"
fi

mkfs.fat -F 32 -n EFI "$ESP_PARTITION" || \
    fail "Failed to format ESP partition"

# ===== Partition 2: Solaris Root Pool =====
echo "Creating partition 2: Solaris root pool (${SOLARIS_ROOT_SIZE_GB}GB)..."
# Create partition for OpenIndiana/illumos root ZFS pool
# MiB units automatically handle alignment for any sector size
parted "$DISK_DEVICE" mkpart solaris 513MiB ${SOLARIS_ROOT_END_MIB}MiB || \
    fail "Failed to create Solaris root partition"

# Set Solaris root partition type (BF00) for proper recognition by illumos
sgdisk --typecode=2:BF00 "$DISK_DEVICE" || \
    fail "Failed to set Solaris root partition type"

# ===== Partition 4: Solaris Reserved (create before data partition) =====
echo ""
echo "NOTE: The Solaris reserved partition is a traditional 8MB placeholder"
echo "and intentionally does not require 1MiB alignment for performance."
echo "Parted may display an alignment warning - this is expected and safe"
echo "to ignore. If prompted, press 'i' to ignore the alignment warning."
echo ""
echo "Creating partition 4: Solaris reserved (8MB at end of disk)..."

# Calculate sectors for 8MB reserved partition based on actual sector size
# This works correctly for both 512-byte and 4Kn disks
RESERVED_SIZE_BYTES=$((8 * 1024 * 1024))  # 8MB in bytes
RESERVE_END_BYTES=$((1 * 1024 * 1024))    # Reserve last 1MB in bytes

# Convert bytes to sectors based on actual sector size
RESERVED_SECTORS=$((RESERVED_SIZE_BYTES / SECTOR_SIZE))
RESERVE_END_SECTORS=$((RESERVE_END_BYTES / SECTOR_SIZE))

# Calculate partition boundaries, -1 since sector numbers use 0-based indexing
LAST_USABLE_SECTOR=$((TOTAL_SECTORS - RESERVE_END_SECTORS - 1))
RESERVED_START_SECTOR=$((LAST_USABLE_SECTOR - RESERVED_SECTORS))

echo "Calculated reserved partition:"
echo "  Start sector: $RESERVED_START_SECTOR"
echo "  End sector: $LAST_USABLE_SECTOR"
echo "  Size: $RESERVED_SECTORS sectors (8MB)"

# Create traditional Solaris reserved partition for compatibility
parted "$DISK_DEVICE" unit s mkpart solaris_reserved \
    $RESERVED_START_SECTOR $LAST_USABLE_SECTOR || \
    fail "Failed to create Solaris reserved partition"

# Set Solaris reserved partition type (BF07)
#  currently partition 3 even though it resides at the end of the disk
sgdisk --typecode=3:BF07 "$DISK_DEVICE" || \
    fail "Failed to set Solaris reserved partition type"

# ===== Partition 3: Data Partition =====
echo "Creating partition 3: Data partition (remaining space)..."
# Create data partition using remaining space between root and reserved
# Calculate the end position in MiB - parted will automatically adjust
RESERVED_START_MB=$((RESERVED_START_SECTOR * SECTOR_SIZE / 1024 / 1024))

echo "Data partition end: ${RESERVED_START_MB}MiB"

parted "$DISK_DEVICE" mkpart data \
    ${SOLARIS_ROOT_END_MIB}MiB ${RESERVED_START_MB}MiB || \
    fail "Failed to create data partition"

# Set Solaris /home partition type (BF05) - currently partition 4
sgdisk --typecode=4:BF05 "$DISK_DEVICE" || \
    fail "Failed to set data partition type"

# ===== Sort partitions to correct logical order =====
echo "Sorting partitions to proper numerical order..."
sgdisk --sort "$DISK_DEVICE" || \
    fail "Failed to sort partitions"

# ===== Display final partition layout =====
echo ""
echo "SUCCESS: Partition layout created successfully!"
echo ""
sgdisk --print "$DISK_DEVICE" || \
    echo "Warning: Could not display partition table"
echo ""
echo "Final partition type codes:"
echo "  Partition 1: ESP (EFI System Partition)"
echo "  Partition 2: BF00 (Solaris root)"
echo "  Partition 3: BF05 (Solaris /home - data)"
echo "  Partition 4: BF07 (Solaris reserved)"
echo ""
echo "Ready for OpenIndiana/illumos installation!"
echo "You can now proceed with ZFS pool creation and OS installation."
