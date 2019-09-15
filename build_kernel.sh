#!/bin/bash

. /etc/arch-efiboot.conf

TARGET=$ESP/$TARGET_ESP
BOOTDIR=/boot
CMDLINE_DIR=$BOOTDIR
UCODE=$BOOTDIR/intel-ucode.img
EFISTUB=/usr/lib/systemd/boot/efi/linuxx64.efi.stub

find_kernels () {

	KERNELS=$(ls /boot/vmlinuz-* | xargs -n1 basename | sed "s/vmlinuz-//")
	echo "Found kernels : "$KERNELS

}

add_ucode () {

	if [ -f "$UCODE" ]; then
		cat "$UCODE" "$INITRD" > /tmp/initrd.bin
		INITRDFILE=/tmp/initrd.bin
	else
		# Do not fail on AMD systems
		echo "    Intel microcode not found. Skipping."
		INITRDFILE="$INITRD"
	fi

}

set_cmdline () {

	# Check for custom command line for the kernel.
	CMDLINE="$CMDLINE_DIR/cmdline-$KERNEL.txt"
	if [ -f "$CMDLINE" ]; then
		echo "    Using custom command line $CMDLINE"
	else
		CMDLINE="$CMDLINE_DIR/cmdline.txt"
		if [ ! -f "$CMDLINE" ]; then
			echo "CMDLINE missing. Extracting from running kernel..."
			cat /proc/cmdline |sed 's/BOOT_IMAGE=[^ ]* \?//' > "$CMDLINE"
		fi
	fi

}

make_efi_kernel () {

	objcopy \
	    --add-section .osrel="/usr/lib/os-release" --change-section-vma .osrel=0x20000 \
	    --add-section .cmdline="$CMDLINE" --change-section-vma .cmdline=0x30000 \
	    --add-section .linux="$BOOTDIR/vmlinuz-$KERNEL" --change-section-vma .linux=0x40000 \
	    --add-section .initrd="$INITRDFILE" --change-section-vma .initrd=0x3000000 \
	    "$EFISTUB" "$TARGET/$KERNEL.efi"

}

find_kernels

echo "Updating EFI kernels..."

for KERNEL in $KERNELS; do

	echo "  Building $KERNEL"
	INITRD="$BOOTDIR/initramfs-$KERNEL.img"

	add_ucode
	set_cmdline
	make_efi_kernel

done
