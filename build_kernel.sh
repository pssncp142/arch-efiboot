#!/bin/bash

#Default parameters
FORCE=0
ESP=/boot
TARGET_ESP=/EFI/Linux

. /etc/arch-efiboot.conf

if ! mount | grep "$ESP " | grep vfat > /dev/null ; then
	echo $ESP "is not a fat32 filesystem. Check your configuration."
	if [ $FORCE -eq 0 ] ; then echo "Aborting..."; exit; fi
fi

# Set environment variables
TARGET=$ESP/$TARGET_ESP
BOOTDIR=/boot
CMDLINE_DIR=$BOOTDIR
UCODE=$BOOTDIR/intel-ucode.img
EFISTUB=/usr/lib/systemd/boot/efi/linuxx64.efi.stub

OSRELEASE_FILE=/tmp/arch-efiboot/os-release 
INITRD_FILE=/tmp/arch-efiboot/initrd.bin 
CMDLINE_FILE=/tmp/arch-efiboot/cmdline

find_kernels () {

	KERNELS=$(ls /boot/vmlinuz-* | xargs -n1 basename | sed "s/vmlinuz-//")
	echo "Found kernels : "$KERNELS

}

make_initrd () {

	INITRD="$BOOTDIR/initramfs-$KERNEL.img"

	if [ -f "$UCODE" ]; then
		cat "$UCODE" "$INITRD" > $INITRD_FILE
	else
		echo "    Intel microcode not found."
		cat "$INITRD" > $INITRD_FILE
	fi

}

set_cmdline () {

	if [ -v CMDLINE ]; then
		echo "    Using command line string."
		echo $CMDLINE > $CMDLINE_FILE
	else
		echo "    CMDLINE missing. Extracting from running kernel..."
		cat /proc/cmdline |sed 's/BOOT_IMAGE=[^ ]* \?//' > $CMDLINE_FILE
	fi
	cat $CMDLINE_FILE

}

pretty_os_release () {

	cp /usr/lib/os-release $OSRELEASE_FILE
	KERNEL_VERSION=$(pacman -Qi $KERNEL | grep Version | cut -d: -f2 | xargs)
	sed -i "s/BUILD_ID=rolling/BUILD_ID=$KERNEL_VERSION/" $OSRELEASE_FILE
	sed -i "s/ID=arch/ID=$KERNEL/" $OSRELEASE_FILE

}

make_efi_kernel () {

	objcopy \
	    --add-section .osrel="$OSRELEASE_FILE" --change-section-vma .osrel=0x20000 \
	    --add-section .cmdline="$CMDLINE_FILE" --change-section-vma .cmdline=0x30000 \
	    --add-section .linux="$BOOTDIR/vmlinuz-$KERNEL" --change-section-vma .linux=0x40000 \
	    --add-section .initrd="$INITRD_FILE" --change-section-vma .initrd=0x3000000 \
	    "$EFISTUB" "$TARGET/$KERNEL.efi"

}

mkdir -p /tmp/arch-efiboot

find_kernels

echo "Updating EFI kernels..."

for KERNEL in $KERNELS; do

	echo "  Building $KERNEL"

	make_initrd
	set_cmdline
	pretty_os_release
	make_efi_kernel

done

rm -r /tmp/arch-efiboot

