# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Lukas Rusak (lrusak@libreelec.tv)
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="containerd"
PKG_VERSION="2.0.1"
PKG_SHA256="a2958e6c97dcc44d2b3fc5f1e0c5cfb267d4620b26b51ff52cbe7bd07678707d"
PKG_LICENSE="APL"
PKG_SITE="https://containerd.io"
PKG_URL="https://github.com/containerd/containerd/archive/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain go:host"
PKG_LONGDESC="A daemon to control runC, built for performance and density."
PKG_TOOLCHAIN="manual"

# Git commit of the matching release https://github.com/containerd/containerd/releases
export PKG_GIT_COMMIT="88aa2f531d6c2922003cc7929e51daf1c14caa0a"

pre_make_target() {

  go_configure

  export CONTAINERD_VERSION="${PKG_VERSION}"
  export CONTAINERD_REVISION="${PKG_GIT_COMMIT}"
  export CONTAINERD_PKG="github.com/containerd/containerd/v2"
  export LDFLAGS="-w -extldflags -static -X ${CONTAINERD_PKG}/version.Version=${CONTAINERD_VERSION} -X ${CONTAINERD_PKG}/version.Revision=${CONTAINERD_REVISION} -X ${CONTAINERD_PKG}/version.Package=${CONTAINERD_PKG} -extld ${CC}"
  export GO111MODULE=off

  mkdir -p ${GOPATH}
  if [ -d ${PKG_BUILD}/vendor ]; then
    mv ${PKG_BUILD}/vendor ${GOPATH}/src
  fi

  mv ${GOPATH}/src/github.com/containerd/containerd/api ${PKG_BUILD}/api-vendor-duplicate
  ln -fs ${PKG_BUILD} ${GOPATH}/src/github.com/containerd/containerd/v2
  ln -fs ${PKG_BUILD}/api ${GOPATH}/src/github.com/containerd/containerd/api
}

make_target() {
  mkdir -p bin
  ${GOLANG} build -v -o bin/containerd              -a -tags "static_build no_btrfs" -ldflags "${LDFLAGS}" ./cmd/containerd
  ${GOLANG} build -v -o bin/containerd-shim-runc-v2 -a -tags "static_build no_btrfs" -ldflags "${LDFLAGS}" ./cmd/containerd-shim-runc-v2
}
