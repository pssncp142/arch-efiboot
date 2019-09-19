#!/bin/bash

DISK=/dev/nvme0n1
PART=1
LABEL="ArchLinux - EFISTUB"
LOADER=/boot/efi/EFI/Linux/linux-dracut.efi

if efibootmgr | grep "$LABEL"; then
    BOOTNUM=$(efibootmgr -v | grep "$LABEL" | sed 's/Boot\([0-F]*\)\*.*/\1/g')
    efibootmgr -B -b $BOOTNUM
    efibootmgr -c -b $BOOTNUM --disk $DISK --part $PART --label "$LABEL" --loader $LOADER --verbose
else
    efibootmgr -c --disk $DISK --part $PART --label "$LABEL" --loader $LOADER --verbose
fi
