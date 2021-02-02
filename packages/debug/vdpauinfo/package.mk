# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)

PKG_NAME="vdpauinfo"
PKG_VERSION="1.4"
PKG_SHA256="50d4326725d62fe1948b0236b96cfc753b035e406f4e6496508a76fbfdecc390"
PKG_LICENSE="GPL"
PKG_SITE="http://freedesktop.org/wiki/Software/VDPAU"
# https://gitlab.freedesktop.org/vdpau/vdpauinfo/uploads/8f047eac351672cc4316724edb6ad2b2/vdpauinfo-1.4.tar.gz
PKG_URL="https://gitlab.freedesktop.org/vdpau/vdpauinfo/-/archive/${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_TARGET="toolchain libvdpau"
PKG_LONGDESC="A tool to show vdpau infos."
