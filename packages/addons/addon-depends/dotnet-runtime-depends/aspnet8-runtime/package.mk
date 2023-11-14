# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2023-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="aspnet8-runtime"
PKG_VERSION="8.0.0"
PKG_LICENSE="MIT"
PKG_SITE="https://dotnet.microsoft.com/"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="ASP.NET Core Runtime enables you to run existing web/server applications."
PKG_TOOLCHAIN="manual"

case "${ARCH}" in
  "aarch64")
    PKG_SHA256="2c501257aa5f7437ab7cbc7419b3a4368ad2b72b515b3f3f9acfd83c0b75d057"
    PKG_URL="https://download.visualstudio.microsoft.com/download/pr/91223e4e-2300-4e8e-9364-09ea1c317294/47fb26a2df5eeee08f77a4d1b720a34a/aspnetcore-runtime-8.0.0-linux-arm64.tar.gz"
    ;;
  "arm")
    PKG_SHA256="dc89239d90011b8e373c796c22b91a72d90fe22110b984e18e7758a29270d49d"
    PKG_URL="https://download.visualstudio.microsoft.com/download/pr/6d3049cc-4dcf-4dfb-9444-009997fbe620/fa9da42c88a2d74aef7e99f56269e36d/aspnetcore-runtime-8.0.0-linux-arm.tar.gz"
    ;;
  "x86_64")
    PKG_SHA256="4418b2169d5f3bb33064e40e34f2cff0f67659dcd3fb0f3c9355b2b69e688964"
    PKG_URL="https://download.visualstudio.microsoft.com/download/pr/257bdcc7-cbfd-4680-964a-cbe8e9160bca/ac0cbf19d897ba51ae004b4146940a0a/aspnetcore-runtime-8.0.0-linux-x64.tar.gz"
    ;;
esac
PKG_SOURCE_NAME="aspnetcore-runtime_${PKG_VERSION}_${ARCH}.tar.gz"
