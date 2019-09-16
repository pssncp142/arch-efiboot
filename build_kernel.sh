#!/bin/bash

#Default parameters
FORCE=0
ESP=/boot
TARGET_ESP=/EFI/Linux
FALLBACK=0

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

set_cmdline () {

	#Hacky way to get CMDLINE_LINUX, CMDLINE_LINUX_LTS etc.
	CMDLINE_THIS=CMDLINE_$(echo $KERNEL | sed "s/-/_/" | tr [a-z] [A-Z])

	if [ -v CMDLINE ]; then
		echo "    Using command line string."
		echo $CMDLINE ${!CMDLINE_THIS} > $CMDLINE_FILE
	else
		echo "    CMDLINE missing. Extracting from running kernel..."
		cat /proc/cmdline |sed 's/BOOT_IMAGE=[^ ]* \?//' > $CMDLINE_FILE
	fi

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

make_initrd_fallback () {

	INITRD="$BOOTDIR/initramfs-$KERNEL-fallback.img"

	if [ -f "$UCODE" ]; then
		cat "$UCODE" "$INITRD" > $INITRD_FILE
	else
		echo "    Intel microcode not found."
		cat "$INITRD" > $INITRD_FILE
	fi

}

pretty_os_release_fallback () {

	cp /usr/lib/os-release $OSRELEASE_FILE
	KERNEL_VERSION=$(pacman -Qi $KERNEL | grep Version | cut -d: -f2 | xargs)
	sed -i "s/BUILD_ID=rolling/BUILD_ID=$KERNEL_VERSION/" $OSRELEASE_FILE
	sed -i "s/ID=arch/ID=$KERNEL/" $OSRELEASE_FILE
	sed -i "s/NAME=\"Arch Linux\"/NAME=\"Arch Linux - Fallback\"/" $OSRELEASE_FILE

}

make_efi_kernel_fallback () {

	objcopy \
	    --add-section .osrel="$OSRELEASE_FILE" --change-section-vma .osrel=0x20000 \
	    --add-section .cmdline="$CMDLINE_FILE" --change-section-vma .cmdline=0x30000 \
	    --add-section .linux="$BOOTDIR/vmlinuz-$KERNEL" --change-section-vma .linux=0x40000 \
	    --add-section .initrd="$INITRD_FILE" --change-section-vma .initrd=0x3000000 \
	    "$EFISTUB" "$TARGET/$KERNEL-fallback.efi"

}



mkdir -p /tmp/arch-efiboot

find_kernels

echo "Updating EFI kernels..."

for KERNEL in $KERNELS; do

	echo "  Building $KERNEL.efi"
	set_cmdline

	make_initrd
	pretty_os_release
	make_efi_kernel

	if [ $FALLBACK -ne 0 ]; then

		echo "  Building $KERNEL-fallback.efi"

		make_initrd_fallback
		pretty_os_release_fallback
		make_efi_kernel_fallback

	fi

done

rm -r /tmp/arch-efiboot

