#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
TOOLCHAIN=$(${CROSS_COMPILE}gcc --print-sysroot)

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then

    cp ${FINDER_APP_DIR}/dtc-multiple-definition.patch ${OUTDIR}/linux-stable
    cd linux-stable

    patch -p1 -Nb -r /dev/null < ./dtc-multiple-definition.patch || true

    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
    #make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs

    if [ ! RESULT -eq 0 ]; then
	    git apply dtc-multiple-definition.patch
	    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
    fi
fi

echo "Adding the Image in outdir"

cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir -p ${OUTDIR}/rootfs
cd ${OUTDIR}/rootfs
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log
mkdir -p home/conf

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox	
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} -j4 distclean
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} -j4 defconfig

else
    cd busybox
fi

# TODO: Make and install busybox
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} CONFIG_PREFIX=${OUTDIR}/rootfs -j4 install

cd "${OUTDIR}/rootfs"

echo "Library dependencies"
${CROSS_COMPILE}readelf -a "${OUTDIR}/rootfs/bin/busybox" | grep "program interpreter"
${CROSS_COMPILE}readelf -a "${OUTDIR}/rootfs/bin/busybox" | grep "Shared library"

# TODO: Add library dependencies to rootfs
cp "${TOOLCHAIN}/lib/ld-linux-aarch64.so.1" "${OUTDIR}/rootfs/lib"
cp -L "${TOOLCHAIN}/lib/ld-linux-aarch64.so.1" "${OUTDIR}/rootfs/lib64"
cp -L "${TOOLCHAIN}/lib64/libm.so.6" "${OUTDIR}/rootfs/lib64"
cp -L "${TOOLCHAIN}/lib64/libresolv.so.2" "${OUTDIR}/rootfs/lib64"
cp -L "${TOOLCHAIN}/lib64/libc.so.6" "${OUTDIR}/rootfs/lib64"

# TODO: Make device nodes
cd "${OUTDIR}/rootfs/dev"
sudo mknod -m 600 console c 5 1
sudo mknod -m 666 null c 1 3

# TODO: Clean and build the writer utility
cd "${FINDER_APP_DIR}"
make clean
if [ -f "writer" ]
then
	rm writer
fi
${CROSS_COMPILE}gcc writer.c -o writer
make CROSS_COMPILE=${CROSS_COMPILE}

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cd "${FINDER_APP_DIR}"
cp -r writer finder.sh finder-test.sh autorun-qemu.sh "${OUTDIR}/rootfs/home"
sudo chmod 755 ${OUTDIR}/rootfs/home/{finder.sh,finder-test.sh,autorun-qemu.sh}
cd conf
cp -L -v * "${OUTDIR}/rootfs/home/conf"

# TODO: Chown the root directory
cd "${OUTDIR}/rootfs"
sudo chown -R root:root "${OUTDIR}/rootfs"

# TODO: Create initramfs.cpio.gz
cd "${OUTDIR}/rootfs"

find . | cpio -H newc -ov --owner root:root  > ${OUTDIR}/initramfs.cpio

cd "${OUTDIR}"
gzip -f initramfs.cpio
