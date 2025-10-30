#!/usr/bin/env nu
# -----------------------------------------------------------------------------
# Script : GPT Partition Creator for Dual-Boot (ZFS + Windows 11)
# Desc   : Creates GPT partition table with ESP, ZFS pool, and Windows partitions
#          Includes Microsoft Reserved (16 MiB), Windows OS (160 GiB),
#          Recovery Environment (768 MiB), and exFAT data partition
#          Partitions aligned for optimal performance with proper type codes
#
# Date   : 10-09-2025
# Deps   : parted, sgdisk, partprobe, sudo, create_gpt_partitions.sh
#
# Usage:
# ./create_gpt_parts_win.nu
#  - Creates all partitions on /dev/nvme0n1 with 256 GiB ZFS pool
#
# Notes:
#  - contains exFat format example
#  - Assumes create_gpt_partitions.sh handles ESP and ZFS partitions
#  - MSR size follows Windows 10/11 spec (16 MiB)
#  - Recovery partition uses ending sector to avoid unallocated space
#  - Data partition uses ending sector for precise allocation
#  - Run 'sudo sgdisk --print /dev/nvme0n1' to verify layout
#  - covered: https://codeishot.com/74SaocDB
#
# tag: nushell, sgdisk, zfs, windows, gpt, multi-boot, partitioning
# -----------------------------------------------------------------------------# 

# clean up partition table, cmds ref: `admin/create_gpt_parts.sh`
# TODO: add this to create_gpt_partitions.sh
# backup Partition Table
# sgdisk --backup=backup.gpt /dev/sda

# Create base partitions: ESP, ZFS pool
sudo ./create_gpt_partitions.sh --disk /dev/nvme0n1 --zfs-pool-size 256

# Microsoft Reserved Partition - 16 MiB (Windows 10/11 spec)
sudo parted /dev/nvme0n1 'mkpart "Microsoft Reserved" 262657MiB 262673MiB'
sudo sgdisk --typecode=4:0C01 /dev/nvme0n1
sudo parted /dev/nvme0n1 set 4 msftres on

# Windows OS partition - 160 GiB NTFS
sudo parted /dev/nvme0n1 mkpart WinOS 257GiB 417GiB
sudo parted /dev/nvme0n1 set 5 msftdata on

# Windows Recovery Environment - 768 MiB, ending sector prevents gaps
sudo parted --align optimal /dev/nvme0n1 'mkpart "Windows Recovery Env." 975986MiB 2000390831s'
sudo parted /dev/nvme0n1 set 6 diag on
sudo sgdisk --typecode=6:de94bba4-06d1-4d40-a16a-bfd50179d6ac /dev/nvme0n1
# also need to format it using ntfs (do it from diskpart, so need to install more
#  windows stuff on my clean Unix system)

# Data partition - exFAT, uses remaining space with precise ending sector
sudo parted /dev/nvme0n1 mkpart Data 417GiB 1998819327s
sudo parted /dev/nvme0n1 set 7 msftdata on
sudo mkfs.exfat --volume-label Data --cluster-size 256KiB --verbose /dev/nvme0n1p7

# Sort partition table and refresh kernel partition info
sudo sgdisk --sort /dev/nvme0n1
sudo partprobe /dev/nvme0n1

# Setup Bootloader - ZFS Boot Menu, ref: root_with_zfs/02_setup_ZBM.nu