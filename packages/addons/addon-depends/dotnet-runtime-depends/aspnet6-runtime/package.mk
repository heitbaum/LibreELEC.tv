# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2022-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="aspnet6-runtime"
PKG_VERSION="6.0.30"
PKG_LICENSE="MIT"
PKG_SITE="https://dotnet.microsoft.com/"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="ASP.NET Core Runtime enables you to run existing web/server applications."
PKG_TOOLCHAIN="manual"

case "${ARCH}" in
  "aarch64")
    PKG_SHA256="c1c81f07ba3b8d1f7edddeb0df923b5595f278a541c9e260a37ccabaa85ae232"
    PKG_URL="https://download.visualstudio.microsoft.com/download/pr/a4c8e994-c595-4698-8cfc-cf3ac166bbbf/9e6b514da011de5191d148d95601a7ec/aspnetcore-runtime-6.0.30-linux-arm64.tar.gz"
    ;;
  "arm")
    PKG_SHA256="bbaaca48f58f4cf3008b447848f7b7d2ace5bb97b61a436f47dd7d10b02a92b3"
    PKG_URL="https://download.visualstudio.microsoft.com/download/pr/4e9433f6-d96f-412e-9eea-006657b32057/fcffac6fb601db009bceb8a4c58a9eea/aspnetcore-runtime-6.0.30-linux-arm.tar.gz"
    ;;
  "x86_64")
    PKG_SHA256="b387fd004b3dff5185b080a1bd80f8e508e6f357814c4f15a014326f84974ea9"
    PKG_URL="https://download.visualstudio.microsoft.com/download/pr/03d1bc71-2ad1-41b4-aa2f-9e4ef6d5c6ed/29b655655d626c590cb216e0c30bccb3/aspnetcore-runtime-6.0.30-linux-x64.tar.gz"
    ;;
esac
PKG_SOURCE_NAME="aspnetcore-runtime_${PKG_VERSION}_${ARCH}.tar.gz"
