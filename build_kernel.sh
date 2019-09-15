#!/bin/bash

. /etc/arch-efiboot.conf

TARGET=$ESP/$TARGET_ESP
BOOTDIR=/boot
CMDLINE_DIR=$BOOTDIR
UCODE=$BOOTDIR/intel-ucode.img
EFISTUB=/usr/lib/systemd/boot/efi/linuxx64.efi.stub

OSRELEASE_FILE=/tmp/arch-efiboot/os-release 
INITRD_FILE=/tmp/arch-efiboot/initrd.bin 

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

pretty_os_release () {

	cp /usr/lib/os-release $OSRELEASE_FILE
	KERNEL_VERSION=$(pacman -Qi $KERNEL | grep Version | cut -d: -f2 | xargs)
	sed -i "s/BUILD_ID=rolling/BUILD_ID=$KERNEL_VERSION/" $OSRELEASE_FILE
	sed -i "s/ID=arch/ID=$KERNEL/" $OSRELEASE_FILE

}

make_efi_kernel () {

	objcopy \
	    --add-section .osrel=$OSRELEASE_FILE --change-section-vma .osrel=0x20000 \
	    --add-section .cmdline="$CMDLINE" --change-section-vma .cmdline=0x30000 \
	    --add-section .linux="$BOOTDIR/vmlinuz-$KERNEL" --change-section-vma .linux=0x40000 \
	    --add-section .initrd=$INITRD_FILE --change-section-vma .initrd=0x3000000 \
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

