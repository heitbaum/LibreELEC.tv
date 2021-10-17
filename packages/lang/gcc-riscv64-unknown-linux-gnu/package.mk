# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2021-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="gcc-riscv64-unknown-linux-gnu"
#PKG_VERSION="10.2.0-2020.12.8"
PKG_VERSION="2020.08-1"
PKG_VERSION="11.1.0-2021.09.16"
PKG_SHA256="09818eccb414359b1df87ec347d94e7bfccc45f8a5eafe8791fddf8110fcc581"
PKG_SHA256="01d767327e6296ba07c6f34b27db63b68f70315d937d0cf5f801ea620bded7a6"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/sifive/freedom-tools/releases"
#PKG_URL="https://static.dev.sifive.com/dev-tools/freedom-tools/v2020.12/riscv64-unknown-elf-toolchain-${PKG_VERSION}-x86_64-linux-ubuntu14.tar.gz"
#PKG_URL="https://github.com/riscv/riscv-gnu-toolchain/releases/download/2021.06.26/riscv64-elf-ubuntu-18.04-nightly-2021.06.26-nightly.tar.gz"
#PKG_URL="https://github.com/riscv/riscv-gnu-toolchain/releases/download/2021.08.11/riscv64-glibc-ubuntu-18.04-nightly-2021.08.11-nightly.tar.gz"
PKG_URL="https://toolchains.bootlin.com/downloads/releases/toolchains/riscv64/tarballs/riscv64--glibc--bleeding-edge-2020.08-1.tar.bz2"
PKG_URL="https://github.com/riscv-collab/riscv-gnu-toolchain/releases/download/2021.09.16/riscv64-glibc-ubuntu-20.04-nightly-2021.09.16-nightly.tar.gz"
PKG_DEPENDS_HOST="ccache:host"
PKG_LONGDESC="riscv64 GNU Linux Binary Toolchain"
PKG_TOOLCHAIN="manual"

makeinstall_host() {
  mkdir -p ${TOOLCHAIN}/lib/gcc-riscv64-unknown-linux-gnu/
    cp -a * ${TOOLCHAIN}/lib/gcc-riscv64-unknown-linux-gnu

  # wrap gcc and g++ with ccache like in gcc package.mk
  PKG_GCC_PREFIX="${TOOLCHAIN}/lib/gcc-riscv64-unknown-linux-gnu/bin/riscv64-unknown-linux-gnu-"
  #PKG_GCC_PREFIX="${TOOLCHAIN}/lib/gcc-riscv64-unknown-linux-gnu/bin/riscv64-buildroot-linux-gnu-"

  cp "${PKG_GCC_PREFIX}gcc" "${PKG_GCC_PREFIX}gcc.real"
cat > "${PKG_GCC_PREFIX}gcc" << EOF
#!/bin/sh
${TOOLCHAIN}/bin/ccache ${PKG_GCC_PREFIX}gcc.real "\$@"
EOF

  chmod +x "${PKG_GCC_PREFIX}gcc"

  cp "${PKG_GCC_PREFIX}g++" "${PKG_GCC_PREFIX}g++.real"
cat > "${PKG_GCC_PREFIX}g++" << EOF
#!/bin/sh
${TOOLCHAIN}/bin/ccache ${PKG_GCC_PREFIX}g++.real "\$@"
EOF

  chmod +x "${PKG_GCC_PREFIX}g++"
}
