# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2023-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="aspnet8-runtime"
PKG_VERSION="8.0.12"
PKG_LICENSE="MIT"
PKG_SITE="https://dotnet.microsoft.com/"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="ASP.NET Core Runtime enables you to run existing web/server applications."
PKG_TOOLCHAIN="manual"

case "${ARCH}" in
  "aarch64")
    PKG_SHA256="1c2b31eb0d1059f259822c651362d870efd21c5308a037dcc389a5e459b05573"
    PKG_URL="https://download.visualstudio.microsoft.com/download/pr/8953c6fe-3542-4cee-b022-a50e029882a5/1bbce821b1ae97ed11b305dd708c0437/aspnetcore-runtime-8.0.12-linux-arm64.tar.gz"
    ;;
  "arm")
    PKG_SHA256="5299c03e7de25e61e0c49cec0ca80642f541c142833c1ded9881c730f010da75"
    PKG_URL="https://download.visualstudio.microsoft.com/download/pr/26fe9c15-40f6-4eb5-88fd-63d98eb259fa/c36789f8460b7e20371c38129d7fc160/aspnetcore-runtime-8.0.12-linux-arm.tar.gz"
    ;;
  "x86_64")
    PKG_SHA256="8a441b42051607dc914b14b1a6271abbf81f72ba0579fcb21aabd8e845d68a70"
    PKG_URL="https://download.visualstudio.microsoft.com/download/pr/df752f45-7e9f-4d13-8568-a88adda5aa04/9d59726fb38525b4956cbb1e1fe8a2c8/aspnetcore-runtime-8.0.12-linux-x64.tar.gz"
    ;;
esac
PKG_SOURCE_NAME="aspnetcore-runtime_${PKG_VERSION}_${ARCH}.tar.gz"
