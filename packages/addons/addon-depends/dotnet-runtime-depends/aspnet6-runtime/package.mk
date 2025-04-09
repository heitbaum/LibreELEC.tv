# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2022-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="aspnet6-runtime"
PKG_VERSION="6.0.36"
PKG_LICENSE="MIT"
PKG_SITE="https://dotnet.microsoft.com/"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="ASP.NET Core Runtime enables you to run existing web/server applications."
PKG_TOOLCHAIN="manual"

case "${ARCH}" in
  "aarch64")
    PKG_SHA256="a82e7ff766ab961b581971eaa7358b6d13ce1132451eebf85d25a1e4599446a2"
    PKG_URL="https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/6.0.36/aspnetcore-runtime-6.0.36-linux-arm64.tar.gz"
    ;;
  "arm")
    PKG_SHA256="3ba06e73e3e78186be7db2d636039c33726b467c1775a541eb53d8dcd12717d8"
    PKG_URL="https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/6.0.36/aspnetcore-runtime-6.0.36-linux-arm.tar.gz"
    ;;
  "x86_64")
    PKG_SHA256="e269fa26930f08c6df920969a4e6c36138372115e193db3cccbbaa06f61e15be"
    PKG_URL="https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/6.0.36/aspnetcore-runtime-6.0.36-linux-x64.tar.gz"
    ;;
esac
PKG_SOURCE_NAME="aspnetcore-runtime_${PKG_VERSION}_${ARCH}.tar.gz"
