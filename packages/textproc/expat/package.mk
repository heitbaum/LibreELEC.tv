# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="expat"
PKG_VERSION="2.4.0"
PKG_SHA256="8c59142ef88913bc0a8b6e4c58970c034210ca552e6271f52f6cd6cce3708424"
PKG_LICENSE="OSS"
PKG_SITE="http://expat.sourceforge.net/"
PKG_URL="https://github.com/libexpat/libexpat/releases/download/R_${PKG_VERSION//./_}/${PKG_NAME}-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_HOST="toolchain:host"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Expat is an XML parser library written in C."

PKG_CMAKE_OPTS_TARGET="-DEXPAT_BUILD_DOCS=OFF \
                       -DEXPAT_BUILD_TOOLS=OFF \
                       -DEXPAT_BUILD_EXAMPLES=OFF \
                       -DEXPAT_BUILD_TESTS=OFF \
                       -DEXPAT_SHARED_LIBS=ON"
PKG_CMAKE_OPTS_HOST="-DEXPAT_BUILD_DOCS=OFF \
                     -DEXPAT_BUILD_TOOLS=OFF \
                     -DEXPAT_BUILD_EXAMPLES=OFF \
                     -DEXPAT_BUILD_TESTS=OFF \
                     -DEXPAT_SHARED_LIBS=ON"
