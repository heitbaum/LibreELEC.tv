PKG_NAME="zfs" 
PKG_VERSION="2.3.0" 
PKG_SHA256="6e8787eab55f24c6b9c317f3fe9b0da9a665eb34c31df88ff368d9a92e9356a6" 
PKG_URL="https://github.com/openzfs/zfs/releases/download/zfs-${PKG_VERSION}/zfs-${PKG_VERSION}.tar.gz" 
PKG_DESCRIPTION="ZFS filesystem support" 
#PKG_TOOLCHAIN="autotools" 
PKG_IS_KERNEL_PKG="yes"

configure_target() { 
  #https://github.com/openzfs/zfs/pull/16924
  cd $PKG_BUILD 
  export KERNEL_CROSS_COMPILE=${TARGET_KERNEL_PREFIX}
  export KERNEL_ARCH=${TARGET_KERNEL_ARCH}
  ./configure --host=$TARGET_NAME --prefix=/usr \
  --with-linux=$(kernel_path) \
  --with-linux-obj=$(kernel_path)
} 

make_target() { 
  make V=1 \
       ARCH=${TARGET_KERNEL_ARCH} \
       KSRC=$(kernel_path) \
       CROSS_COMPILE=${TARGET_KERNEL_PREFIX}
} 

makeinstall_target() { 
  make install DESTDIR=$INSTALL 
} 
