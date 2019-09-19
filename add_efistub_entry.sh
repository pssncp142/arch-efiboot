#!/bin/bash

# Your ESP. For example, if your ESP partition is /dev/sda, DISK=/dev/sda PART=1
DISK=/dev/nvme0n1
PART=1

LABEL="ArchLinux - EFISTUB"
# Path to EFI file in your ESP, not the full path!
LOADER=EFI/Linux/linux-dracut.efi

if efibootmgr | grep "$LABEL"; then
    BOOTNUM=$(efibootmgr -v | grep "$LABEL" | sed 's/Boot\([0-F]*\)\*.*/\1/g')
    efibootmgr -B -b $BOOTNUM
    efibootmgr -c -b $BOOTNUM --disk $DISK --part $PART --label "$LABEL" --loader $LOADER --verbose
else
    efibootmgr -c --disk $DISK --part $PART --label "$LABEL" --loader $LOADER --verbose
fi
