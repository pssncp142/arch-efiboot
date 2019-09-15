# Maintainer: Yigit Dallilar <yigit.dallilar@gmail.com>

pkgname=arch-efiboot-git
pkgver=1.0
pkgrel=1
epoch=
arch=(any)
url="https://github.com/pssncp142/arch-efiboot"
groups=()
depends=("binutils" "pacman")
makedepends=()
checkdepends=()
optdepends=()
provides=()
conflicts=()
replaces=()
backup=(etc/arch-efiboot.conf)
options=()
changelog=
source=("arch-efiboot-git::git+https://github.com/pssncp142/arch-efiboot")
license=('Apache')
md5sums=('SKIP')
pkgdesc="Builds bootable UEFI blobs (including kernel, initrd, ucode, cmdline) in /boot directory "
#install="${pkgname}.install"

pkgver() {
	cd ${srcdir}/${pkgname}
	git describe --long --tags | sed 's/^v//;s/\([^-]*-g\)/r\1/;s/-/./g'
}

package () {
	install -D -m644 ${srcdir}/${pkgname}/etc/arch-efiboot.conf ${pkgdir}/etc/arch-efiboot.conf
    install -D -m755 ${srcdir}/${pkgname}/build_kernel.sh ${pkgdir}/usr/bin/build_efi_kernels
    install -D -m644 ${srcdir}/${pkgname}/kernel-update.hook ${pkgdir}/etc/pacman.d/hooks/efi-kernel-update.hook
    sed -i 's/\/opt\/build_kernel\.sh/\/usr\/bin\/build_efi_kernels/' ${pkgdir}/etc/pacman.d/hooks/efi-kernel-update.hook
}

