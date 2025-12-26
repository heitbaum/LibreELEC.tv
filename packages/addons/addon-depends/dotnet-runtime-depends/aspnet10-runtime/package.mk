# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2022-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="aspnet10-runtime"
PKG_VERSION="10.0.2"
PKG_LICENSE="MIT"
PKG_SITE="https://dotnet.microsoft.com/"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="ASP.NET Core Runtime enables you to run existing web/server applications."
PKG_TOOLCHAIN="manual"

case "${ARCH}" in
  "aarch64")
    PKG_SHA256="39a06430066a23448818c5dcbe5d149a52b1df5aada4fce7ce9a66cfbf747a2d"
    PKG_URL="https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/10.0.2/aspnetcore-runtime-10.0.2-linux-arm64.tar.gz"
    ;;
  "arm")
    PKG_SHA256="a20330b881b7a81c4a4246971976de25bb43af37d1db0fd9ecb3381b631d8551"
    PKG_URL="https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/10.0.2/aspnetcore-runtime-10.0.2-linux-arm.tar.gz"
    ;;
  "x86_64")
    PKG_SHA256="267452b48aa4c296bd3cc757c41b813d2104f4ff7478bc699b83c59452c9735b"
    PKG_URL="https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/10.0.2/aspnetcore-runtime-10.0.2-linux-x64.tar.gz"
    ;;
esac
PKG_SOURCE_NAME="aspnetcore-runtime_${PKG_VERSION}_${ARCH}.tar.gz"
