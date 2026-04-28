# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="runc"
PKG_VERSION="1.5.0-rc.2"
PKG_SHA256="9e343fbcab02e3d4809b85789dd2d800203a50aa8d4cd25560e251644a50236b"
PKG_LICENSE="Apache-2.0"
PKG_SITE="https://github.com/opencontainers/runc"
PKG_URL="https://github.com/opencontainers/runc/archive/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain go:host libseccomp"
PKG_DEPENDS_CONFIG="libseccomp"
PKG_LONGDESC="A CLI tool for spawning and running containers according to the OCI specification."
PKG_TOOLCHAIN="manual"

# Git commit of the matching release https://github.com/opencontainers/runc/releases
export PKG_GIT_COMMIT="c3e4075c344f23b219c8ac47c35a84e675f266de"

pre_make_target() {
  go_configure

  export LDFLAGS="-w -extldflags -static -X main.gitCommit=${PKG_GIT_COMMIT} -X main.version=$(cat ./VERSION) -extld ${CC}"

  mkdir -p ${GOPATH}
  if [ -d ${PKG_BUILD}/vendor ]; then
    mv ${PKG_BUILD}/vendor ${GOPATH}/src
  fi

  ln -fs ${PKG_BUILD} ${GOPATH}/src/github.com/opencontainers/runc
}

make_target() {
  mkdir -p bin
  ${GOLANG} build -v -o bin/runc -a -tags "cgo seccomp static_build" -ldflags "${LDFLAGS}" ./
}
