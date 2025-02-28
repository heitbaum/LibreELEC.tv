PKG_NAME="zfs"
PKG_VERSION="2.3.0"
PKG_SHA256="6e8787eab55f24c6b9c317f3fe9b0da9a665eb34c31df88ff368d9a92e9356a6"
PKG_URL="https://github.com/openzfs/zfs/releases/download/zfs-${PKG_VERSION}/zfs-${PKG_VERSION}.tar.gz"
PKG_DESCRIPTION="ZFS filesystem support"
PKG_IS_KERNEL_PKG="yes"
PKG_DEPENDS_TARGET="toolchain linux libunwind zlib"

configure_target() {
  cd $PKG_BUILD
  KERNEL_DIR=$(kernel_path)
  if [ ! -d "$KERNEL_DIR" ]; then
    echo "Kernel directory not found: $KERNEL_DIR"
    exit 1
  fi
  export KERNEL_CROSS_COMPILE=${TARGET_KERNEL_PREFIX}
  export KERNEL_ARCH=${TARGET_KERNEL_ARCH}
  ./configure --host=$TARGET_NAME --prefix=/usr \
              --with-linux="$KERNEL_DIR" \
              --with-linux-obj="$KERNEL_DIR" \
              --disable-static \
              --enable-shared
}

make_target() {
  make V=1 \
       ARCH=${TARGET_KERNEL_ARCH} \
       KSRC=$(kernel_path) \
       CROSS_COMPILE=${TARGET_KERNEL_PREFIX} \
       LDFLAGS="$LDFLAGS -lunwind -lz"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/$(get_full_module_dir)/fs/${PKG_NAME}
    cp module/*.ko ${INSTALL}/$(get_full_module_dir)/fs/${PKG_NAME}
  # Install kernel modules to standard fs/zfs directory
  #mkdir -p ${INSTALL}/$(get_full_module_dir)/fs/zfs
  #find $PKG_BUILD/module -name "*.ko" -exec cp {} ${INSTALL}/$(get_full_module_dir)/fs/zfs/ \;
  # Install user-space tools
  #make install DESTDIR=$INSTALL
  # Generate module dependencies
  #${KERNEL_CROSS_COMPILE}depmod -a -b ${INSTALL} 6.12.15
}
