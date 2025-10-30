# -----------------------------------------------------------------------------
# Script : Setup ZFSBootMenu.nu
# Desc   : Create GPT partitions and install ZFSBootMenu as UEFI bootloader
# Date   : 10-29-2025
#
# Usage:
#   ./setup_ZBM.nu
#     - Wipes existing partition table on /dev/nvme0n1
#     - Creates ESP (512MiB) and ZFS pool partition
#     - Downloads and installs ZFSBootMenu EFI binaries
#     - Registers boot entries via efibootmgr
#
# Notes:
#   - Requires root/sudo privileges
#   - Destroys ALL data on target disk (/dev/nvme0n1)
#   - Requires create_gpt_partitions.sh in current directory
#   - ESP mount point: /mnt/boot/efi
#   - Requires efibootmgr, wget2, sgdisk, wipefs utilities
#
# Deps: wget2, efibootmgr
#
# Refs:
#   - https://docs.zfsbootmenu.org
#   - https://github.com/zbm-dev/zfsbootmenu
#
# tag: linux-only, destructive
# -----------------------------------------------------------------------------


# Run this script after running "./create_gpt_partitions.sh"
#  which creates GPT partitions (ESP 512MiB + ZFS pool)

const DISK = "/dev/nvme0n1"
const ESP_PART = $"($DISK)p1"
const ESP_MOUNT = "/mnt/boot/efi"
const ZBM_DIR = $"($ESP_MOUNT)/EFI/ZBM"

# Verify disk exists
if not ($DISK | path exists) {
  error make {msg: $"Disk ($DISK) not found"}
}

print $"WARNING: This will DESTROY ALL DATA on ($DISK)"
print "Press Ctrl+C to cancel, or Enter to continue..."
input


# Mount ESP
print $"Mounting ESP at ($ESP_MOUNT)..."
sudo mkdir --parents $ESP_MOUNT
sudo mount $ESP_PART $ESP_MOUNT
if $env.LAST_EXIT_CODE != 0 {
  error make {msg: "Failed to mount ESP"}
}

# Create ZBM directory
sudo mkdir --parents $ZBM_DIR

# Download ZFSBootMenu EFI binaries
print "Downloading ZFSBootMenu binaries..."
sudo wget2 --trust-server-names --output-document=$"($ZBM_DIR)/vmlinuz.efi" https://get.zfsbootmenu.org/efi
if $env.LAST_EXIT_CODE != 0 {
  sudo umount $ESP_MOUNT
  error make {msg: "Failed to download ZBM EFI binary"}
}

sudo wget2 --trust-server-names --output-document=$"($ZBM_DIR)/vmlinuz-rec.efi" https://get.zfsbootmenu.org/efi/recovery
if $env.LAST_EXIT_CODE != 0 {
  sudo umount $ESP_MOUNT
  error make {msg: "Failed to download ZBM recovery binary"}
}

# Verify downloads
print "\nVerifying downloads:"
sudo ls -lh $ZBM_DIR

# Register UEFI boot entries
print "\nRegistering UEFI boot entries..."
sudo efibootmgr --disk $DISK --part 1 --create --label "ZFSBootMenu" --loader '\EFI\ZBM\vmlinuz.efi'
sudo efibootmgr --disk $DISK --part 1 --create --label "ZFSBootMenu Recovery" --loader '\EFI\ZBM\vmlinuz-rec.efi'

if $env.LAST_EXIT_CODE == 0 {
  print "\nBoot entries registered successfully"
  sudo efibootmgr | grep -i zbm
} else {
  print "WARNING: efibootmgr failed - you may need to register manually in BIOS"
}

# Unmount ESP
print $"\nUnmounting ($ESP_MOUNT)..."
sudo umount $ESP_MOUNT

print "\nZFSBootMenu installation complete"