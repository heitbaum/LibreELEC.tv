# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2023-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="aspnet8-runtime"
PKG_VERSION="8.0.5"
PKG_LICENSE="MIT"
PKG_SITE="https://dotnet.microsoft.com/"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="ASP.NET Core Runtime enables you to run existing web/server applications."
PKG_TOOLCHAIN="manual"

case "${ARCH}" in
  "aarch64")
    PKG_SHA256="b9889d2fe999ba262560928dc4d9365532775f0d793bd99904810aa256ede64b"
    PKG_URL="https://download.visualstudio.microsoft.com/download/pr/208a57a8-fcc0-4801-a337-79095304d2af/d1ffa79af24735af4bd748229778c1a9/aspnetcore-runtime-8.0.5-linux-arm64.tar.gz"
    ;;
  "arm")
    PKG_SHA256="66c0995c631f0d8046ad7b58cbe1aebefa608b2078552c5293d5931fb8811d32"
    PKG_URL="https://download.visualstudio.microsoft.com/download/pr/4a8e69b4-5f79-4b86-b922-5b431ff02736/db7eb177e07a80137aba9abaaf3246be/aspnetcore-runtime-8.0.5-linux-arm.tar.gz"
    ;;
  "x86_64")
    PKG_SHA256="2f6d859b8c4aacd21c2570ea093cc0abf9cd7bc6b9a07d6416fb455df71335af"
    PKG_URL="https://download.visualstudio.microsoft.com/download/pr/ccccfeb7-0af4-4713-b4f1-cf49b5c8bd6c/5b04c0188dfcf78b70da78ae3bd7f3ab/aspnetcore-runtime-8.0.5-linux-x64.tar.gz"
    ;;
esac
PKG_SOURCE_NAME="aspnetcore-runtime_${PKG_VERSION}_${ARCH}.tar.gz"
