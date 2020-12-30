# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="sshfs"
PKG_VERSION="3.7.1"
PKG_SHA256="fe5d3436d61b46974889e0c4515899c21a9d67851e3793c209989f72353d7750"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/libfuse/sshfs"
PKG_URL="https://github.com/libfuse/sshfs/releases/download/sshfs-${PKG_VERSION}/sshfs-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain fuse glib"
PKG_LONGDESC="A filesystem client based on the SSH File Transfer Protocol."
PKG_BUILD_FLAGS="-sysroot"
