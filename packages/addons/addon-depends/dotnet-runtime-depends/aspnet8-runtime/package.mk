# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2023-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="aspnet8-runtime"
PKG_VERSION="8.0.0-rc.2"
PKG_LICENSE="MIT"
PKG_SITE="https://dotnet.microsoft.com/"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="ASP.NET Core Runtime enables you to run existing web/server applications."
PKG_TOOLCHAIN="manual"

case "${ARCH}" in
  "aarch64")
    PKG_SHA256="c190a0487867ec6478622c6c87da06c1f33ad1197759ec547d7de2132ff2f3d4"
    PKG_URL="https://download.visualstudio.microsoft.com/download/pr/c5d92a9c-c318-422e-b66a-7849199de735/6c3bc3f5958917851fe7dacd383bcaea/aspnetcore-runtime-8.0.0-rc.2.23480.2-linux-arm64.tar.gz"
    ;;
  "arm")
    PKG_SHA256="a7648c5c15f527fd84f9fd9c7e7ac8ca2a32ffc3c600bc05243165418e281557"
    PKG_URL="https://download.visualstudio.microsoft.com/download/pr/bfa751f5-17fe-489b-bc5d-6f53a578e601/4137a4e66d3c0895035925e7073cb47a/aspnetcore-runtime-8.0.0-rc.2.23480.2-linux-arm.tar.gz"
    ;;
  "x86_64")
    PKG_SHA256="e4c0ad37d1fe47805ce4f21de28c95eac7b5650be1b41d2de5a2c20000c369d8"
    PKG_URL="https://download.visualstudio.microsoft.com/download/pr/0d7fb51b-f30e-4b84-b4c2-b739ec8f7978/68e9fc71fb2c4f01a9c7f25672caf1d1/aspnetcore-runtime-8.0.0-rc.2.23480.2-linux-x64.tar.gz"
    ;;
esac
PKG_SOURCE_NAME="aspnetcore-runtime_${PKG_VERSION}_${ARCH}.tar.gz"
