#!/bin/bash

if [ -e boot.img ]; then
	rm boot.img
fi

if [ -e compile.log ]; then
	rm compile.log
fi

if [ -e ramdisk.cpio ]; then
	rm ramdisk.cpio
fi

# Set Default Path
TOP_DIR=$PWD
KERNEL_PATH=`readlink -f .`
ROOTFS_PATH=`readlink -f $KERNEL_PATH/../ramfs-sgs33`
#ROOTFS_PATH=`readlink -f $KERNEL_PATH/ramdisk-samsung`
#ROOTFS_PATH="/home/neophyte-x360/kernel/neak-gs3-kernel/ramdisk-samsung"

# Set toolchain and root filesystem path
#TOOLCHAIN="/home/neophyte-x360/linaro/4.7-2012.06/bin/arm-eabi-"
#TOOLCHAIN="/home/neophyte-x360/linaro/4.7-2012.06/bin/arm-eabi-"
#TOOLCHAIN="/home/neophyte-x360/linaro/4.7-2012.05/bin/arm-eabi-"
#TOOLCHAIN="/home/neophyte-x360/linaro/4.7-2012.04/bin/arm-eabi-"
#TOOLCHAIN="/home/neophyte-x360/linaro/2012.03/bin/arm-linux-gnueabi-"
#TOOLCHAIN="/home/neophyte-x360/linaro/2012.04/bin/arm-linux-gnueabi-"
#TOOLCHAIN="/home/neophyte-x360/linaro/2012.06/bin/arm-linux-gnueabihf-"
TOOLCHAIN="/home/neophyte-x360/linaro/2012.12/bin/arm-linux-gnueabihf-"
#TOOLCHAIN="/home/neophyte-x360/arm-google-4.4.3/bin/arm-linux-androideabi-"
#TOOLCHAIN="/home/neophyte-x360/linaro/2012.06/bin/arm-linux-gnueabihf-"
#TOOLCHAIN="/home/neophyte-x360/linaro/4.7-2012.08/bin/arm-linux-gnueabihf-"
#TOOLCHAIN="/home/neophyte-x360/linaro/android-toolchain-eabi-4.7/bin/arm-eabi-"
#TOOLCHAIN="/home/neophyte-x360/arm-google-4.4.3/bin/arm-linux-androideabi-"
#TOOLCHAIN="/home/neophyte-x360/linaro/4.7-2012.06/bin/arm-eabi-"
RAMFS_TMP="/tmp/ramfs-source-sgs3"

#export KBUILD_BUILD_VERSION="xT7.NeoPhyTe.x360"
export KERNELDIR=$KERNEL_PATH

export USE_SEC_FIPS_MODE=true

#echo "Cleaning latest build"
#make ARCH=arm CROSS_COMPILE=$TOOLCHAIN -j`grep 'processor' /proc/cpuinfo | wc -l` mrproper

# Making our .config
#make neak_defconfig

nice -n 10 make -j4 ARCH=arm CROSS_COMPILE=$TOOLCHAIN || exit 1

## Copying kernel modules
#rm -f $ROOTFS_PATH/lib/modules/*.ko
#find -name '*.ko' -exec cp -av {} $ROOTFS_PATH/lib/modules/ \;
#unzip $KERNEL_PATH/proprietary-modules/proprietary-modules.zip -d $ROOTFS_PATH/lib/modules

make -j`grep 'processor' /proc/cpuinfo | wc -l` ARCH=arm CROSS_COMPILE=$TOOLCHAIN || exit -1

# Copy Kernel Image
rm -f $KERNEL_PATH/releasetools/tar/*.tar
rm -f $KERNEL_PATH/releasetools/zip/*.zip
cp -f $KERNEL_PATH/arch/arm/boot/zImage .

# Create ramdisk.cpio archive
rm -rf $RAMFS_TMP
rm -rf $RAMFS_TMP.cpio
rm -rf $RAMFS_TMP.cpio.gz
rm -rf $RAMFS_TMP.cpio.xz
rm -rf $KERNEL_PATH/*.cpio
rm -rf $KERNEL_PATH/*.cpio.gz
rm -rf $KERNEL_PATH/*.cpio.xz
cd $ROOTFS_PATH
cp -ax $ROOTFS_PATH $RAMFS_TMP
find $RAMFS_TMP -name .git -exec rm -rf {} \;
#remove empty directory placeholders
find $RAMFS_TMP -name EMPTY_DIRECTORY -exec rm -rf {} \;
rm -rf $RAMFS_TMP/tmp/*
#remove mercurial repository
rm -rf $RAMFS_TMP/.hg
#copy modules into ramfs
mkdir -p $ROOTFS_PATH/lib/modules
rm -f $ROOTFS_PATH/lib/modules/*.ko
cd $KERNEL_PATH
find -name '*.ko' -exec cp -av {} $ROOTFS_PATH/lib/modules/ \;
#unzip $KERNEL_PATH/proprietary-modules/proprietary-modules.zip -d $ROOTFS_PATH/lib/modules

cd $RAMFS_TMP
find | fakeroot cpio -H newc -o > $RAMFS_TMP.cpio 2>/dev/null
ls -lh $RAMFS_TMP.cpio
xz --check=crc32 $BCJ --lzma2=$LZMA2OPTS,dict=8MiB $RAMFS_TMP.cpio
# gzip -9 $RAMFS_TMP.cpio
cd -
cd $KERNEL_PATH

nice -n 10 make -j4 ARCH=arm CROSS_COMPILE=$TOOLCHAIN zImage || exit 1

./mkbootimg --kernel $KERNEL_PATH/arch/arm/boot/zImage --ramdisk $RAMFS_TMP.cpio.xz --board smdk4x12 --base 0x10000000 --pagesize 2048 --ramdiskaddr 0x11000000 -o $KERNEL_PATH/boot.img


# $KERNELDIR/mkshbootimg.py $KERNEL_PATH/boot.img $KERNELDIR/boot.img.pre $KERNEL_PATH/payload.tar
# rm -f $KERNEL_PATH/boot.img.pre

# Copy boot.img
cp boot.img $KERNEL_PATH/releasetools/zip
cp boot.img $KERNEL_PATH/releasetools/tar

# Creating flashable zip and tar
cd $KERNEL_PATH
cd releasetools/zip
zip -0 -r HydRx-.zip *
cd ..
cd tar
tar cf HydRx-.tar boot.img && ls -lh HydRx-.tar

# Cleanup
rm $KERNEL_PATH/releasetools/zip/boot.img
rm $KERNEL_PATH/releasetools/tar/boot.img
rm $KERNEL_PATH/zImage
