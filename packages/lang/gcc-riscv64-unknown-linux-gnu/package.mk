# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2021-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="gcc-riscv64-unknown-linux-gnu"
#PKG_VERSION="10.2.0-2020.12.8"
PKG_VERSION="11.1.0-2021.08.11"
PKG_SHA256="1eff95304bca8cec64bbc46eb30fd4ed7459b86aeb4f208ad5fd8eb93a30d709"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/sifive/freedom-tools/releases"
#PKG_URL="https://static.dev.sifive.com/dev-tools/freedom-tools/v2020.12/riscv64-unknown-elf-toolchain-${PKG_VERSION}-x86_64-linux-ubuntu14.tar.gz"
#PKG_URL="https://github.com/riscv/riscv-gnu-toolchain/releases/download/2021.06.26/riscv64-elf-ubuntu-18.04-nightly-2021.06.26-nightly.tar.gz"
PKG_URL="https://github.com/riscv/riscv-gnu-toolchain/releases/download/2021.08.11/riscv64-glibc-ubuntu-18.04-nightly-2021.08.11-nightly.tar.gz"
PKG_DEPENDS_HOST="ccache:host"
PKG_LONGDESC="riscv64 GNU Linux Binary Toolchain"
PKG_TOOLCHAIN="manual"

makeinstall_host() {
  mkdir -p ${TOOLCHAIN}/lib/gcc-riscv64-unknown-linux-gnu/
    cp -a * ${TOOLCHAIN}/lib/gcc-riscv64-unknown-linux-gnu

  # wrap gcc and g++ with ccache like in gcc package.mk
  PKG_GCC_PREFIX="${TOOLCHAIN}/lib/gcc-riscv64-unknown-linux-gnu/bin/riscv64-unknown-linux-gnu-"

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
