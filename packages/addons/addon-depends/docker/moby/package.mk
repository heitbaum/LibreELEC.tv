# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2022-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="moby"
PKG_VERSION="28.0.0"
PKG_SHA256="89e26ecb0c13ef7037305811b0eb6dd4c70741c34ec3428d4396d68b03deb641"
PKG_LICENSE="ASL"
PKG_SITE="https://mobyproject.org/"
PKG_URL="https://github.com/moby/moby/archive/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain go:host systemd"
PKG_LONGDESC="Moby is an open-source project created by Docker to enable and accelerate software containerization."
PKG_TOOLCHAIN="manual"

# Git commit of the matching release https://github.com/moby/moby
export PKG_GIT_COMMIT="af898abe44662d9554fb15ee4d4a7307f1b8e315"

PKG_MOBY_BUILDTAGS="daemon \
                    autogen \
                    exclude_graphdriver_devicemapper \
                    exclude_graphdriver_aufs \
                    exclude_graphdriver_btrfs \
                    journald"

configure_target() {
  go_configure

  export LDFLAGS="-w -linkmode external -extldflags -Wl,--unresolved-symbols=ignore-in-shared-libs -extld ${CC}"

  # used for docker version
  export GITCOMMIT=${PKG_GIT_COMMIT}
  export VERSION=${PKG_VERSION}
  export BUILDTIME="$(date --utc)"

  cat >"${PKG_BUILD}/go.mod" <<EOF
module github.com/docker/docker

go 1.18
EOF

  GO111MODULE=auto ${GOLANG} mod tidy -modfile 'vendor.mod' -compat 1.18
  GO111MODULE=auto ${GOLANG} mod vendor -modfile vendor.mod

  source hack/make/.go-autogen
}

make_target() {
  mkdir -p bin
  ${GOLANG} build -mod=mod -modfile=vendor.mod -v -o bin/docker-proxy -a -ldflags "${LDFLAGS}" ./cmd/docker-proxy
  ${GOLANG} build -mod=mod -modfile=vendor.mod -v -o bin/dockerd -a -tags "${PKG_MOBY_BUILDTAGS}" -ldflags "${LDFLAGS}" ./cmd/dockerd
}

makeinstall_target() {
  :
}
