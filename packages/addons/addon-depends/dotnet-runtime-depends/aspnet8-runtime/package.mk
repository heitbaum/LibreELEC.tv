# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2023-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="aspnet8-runtime"
PKG_VERSION="8.0.16"
PKG_LICENSE="MIT"
PKG_SITE="https://dotnet.microsoft.com/"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="ASP.NET Core Runtime enables you to run existing web/server applications."
PKG_TOOLCHAIN="manual"

case "${ARCH}" in
  "aarch64")
    PKG_SHA256="3481559ea465a0abbd087b7338b1329726650a8f6595fc269b9c1a701ce91ecc"
    PKG_URL="https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/8.0.16/aspnetcore-runtime-8.0.16-linux-arm64.tar.gz"
    ;;
  "arm")
    PKG_SHA256="9838259377fb179e83b865a76aa8d1480aab4126e680ee3b1564ed90133acfde"
    PKG_URL="https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/8.0.16/aspnetcore-runtime-8.0.16-linux-arm.tar.gz"
    ;;
  "x86_64")
    PKG_SHA256="e5d52f7f6fec4b22c7d7061efd67aa8e79b7fa5b7b2cbd5d9e41758b999f0eed"
    PKG_URL="https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/8.0.16/aspnetcore-runtime-8.0.16-linux-x64.tar.gz"
    ;;
esac
PKG_SOURCE_NAME="aspnetcore-runtime_${PKG_VERSION}_${ARCH}.tar.gz"
