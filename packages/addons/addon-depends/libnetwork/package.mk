# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Lukas Rusak (lrusak@libreelec.tv)
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libnetwork"
PKG_VERSION="b3507428be5b458cb0e2b4086b13531fb0706e46" # 2021-01-26
PKG_SHA256="90a8dc84bc5d2d74dee0b2c3544f8786598ff85e9fc9f6a55a15b60b7cd78d63"
PKG_LICENSE="APL"
PKG_SITE="https://github.com/docker/libnetwork"
PKG_URL="https://github.com/docker/libnetwork/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain go:host"
PKG_LONGDESC="A native Go implementation for connecting containers."
PKG_TOOLCHAIN="manual"

pre_make_target() {
  go_configure

  export CGO_ENABLED=0
  export LDFLAGS="-extld ${CC}"

  mkdir -p ${GOPATH}
  if [ -d ${PKG_BUILD}/vendor ]; then
    mv ${PKG_BUILD}/vendor ${GOPATH}/src
  fi

  ln -fs ${PKG_BUILD} ${GOPATH}/src/github.com/docker/libnetwork
}

make_target() {
  mkdir -p bin
  ${GOLANG} build -v -o bin/docker-proxy -a -ldflags "${LDFLAGS}" ./cmd/proxy
}
