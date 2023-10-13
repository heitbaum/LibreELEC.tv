# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2023-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="aspnet8-runtime"
PKG_VERSION="8.0.1"
PKG_LICENSE="MIT"
PKG_SITE="https://dotnet.microsoft.com/"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="ASP.NET Core Runtime enables you to run existing web/server applications."
PKG_TOOLCHAIN="manual"

case "${ARCH}" in
  "aarch64")
    PKG_SHA256="4419289855f180dd689826925b829fa9cb0e57852c5a593acd929143be72243e"
    PKG_URL="https://download.visualstudio.microsoft.com/download/pr/0688a08e-fdaf-489b-90e4-033cc19cfffc/c9a9c648862b0b18c9aca77d3be0ef9f/aspnetcore-runtime-8.0.1-linux-arm64.tar.gz"
    ;;
  "arm")
    PKG_SHA256="2f0a24b5f40b3b6947f5a37a6f73f83f223695886b40b9f4ce3b382ab213a81a"
    PKG_URL="https://download.visualstudio.microsoft.com/download/pr/6d73b0dc-fd8a-4f4a-9b16-bf075c2985e0/345ca37b7db49d9528406707aa97ff6c/aspnetcore-runtime-8.0.1-linux-arm.tar.gz"
    ;;
  "x86_64")
    PKG_SHA256="cd825a5bd7b40e5706840d7b22650b787f71db5e2e496c80e16571bf5003f8fe"
    PKG_URL="https://download.visualstudio.microsoft.com/download/pr/8e19b03a-93be-43ae-8cd6-95b89a849572/facbb896d726a2496dd23bcecb28c9e9/aspnetcore-runtime-8.0.1-linux-x64.tar.gz"
    ;;
esac
PKG_SOURCE_NAME="aspnetcore-runtime_${PKG_VERSION}_${ARCH}.tar.gz"
