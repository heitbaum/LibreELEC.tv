# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="llvm"
PKG_VERSION="23.1.3"
PKG_SHA256="c44186a7762ed28954be72e5ff6df9808e0779d4f1bf014ecc4e7e211d31ee34"
PKG_LICENSE="Apache-2.0 WITH LLVM-exception"
PKG_SITE="http://llvm.org/"
PKG_URL="https://github.com/llvm/llvm-project/releases/download/llvmorg-${PKG_VERSION}/llvm-project-${PKG_VERSION/-/}.src.tar.xz"
PKG_DEPENDS_HOST="toolchain:host"
PKG_DEPENDS_TARGET="toolchain llvm:host zlib"
PKG_LONGDESC="Low-Level Virtual Machine (LLVM) is a compiler infrastructure."
PKG_TOOLCHAIN="cmake"

PKG_CMAKE_OPTS_COMMON="-DLLVM_INCLUDE_TOOLS=ON \
                       -DLLVM_BUILD_TOOLS=OFF \
                       -DLLVM_BUILD_UTILS=OFF \
                       -DLLVM_BUILD_EXAMPLES=OFF \
                       -DLLVM_INCLUDE_EXAMPLES=OFF \
                       -DLLVM_BUILD_TESTS=OFF \
                       -DLLVM_INCLUDE_TESTS=OFF \
                       -DLLVM_BUILD_BENCHMARKS=OFF \
                       -DLLVM_INCLUDE_BENCHMARKS=OFF \
                       -DLLVM_BUILD_DOCS=OFF \
                       -DLLVM_INCLUDE_DOCS=OFF \
                       -DLLVM_ENABLE_DOXYGEN=OFF \
                       -DLLVM_ENABLE_SPHINX=OFF \
                       -DLLVM_ENABLE_OCAMLDOC=OFF \
                       -DLLVM_ENABLE_BINDINGS=OFF \
                       -DLLVM_ENABLE_ASSERTIONS=OFF \
                       -DLLVM_ENABLE_WERROR=OFF \
                       -DLLVM_ENABLE_ZLIB=OFF \
                       -DLLVM_ENABLE_ZSTD=OFF \
                       -DLLVM_ENABLE_LIBXML2=OFF \
                       -DLLVM_BUILD_LLVM_DYLIB=ON \
                       -DLLVM_LINK_LLVM_DYLIB=ON \
                       -DLLVM_OPTIMIZED_TABLEGEN=ON \
                       -DLLVM_APPEND_VC_REV=OFF \
                       -DLLVM_ENABLE_RTTI=ON \
                       -DLLVM_ENABLE_UNWIND_TABLES=OFF \
                       -DLLVM_ENABLE_Z3_SOLVER=OFF \
                       -DCMAKE_SKIP_RPATH=ON"

if listcontains "${GRAPHIC_DRIVERS}" "(imagination|iris|panfrost)"; then
  PKG_DEPENDS_UNPACK="spirv-headers spirv-llvm-translator"
  PKG_CMAKE_OPTS_COMMON+=" -DLLVM_SPIRV_INCLUDE_TESTS=OFF"
fi

# the prebuilt llvm:host published as llvm-reusable. llvm:host builds the
# backends of the target arch, and the graphic drivers add the spirv translator
# and clang-tblgen, so the name carries the target arch and the hash covers the
# recipes and that choice, so that a stale archive is never used
if [ "${USE_REUSABLE}" = "yes" -o "${USE_REUSABLE}" = "preferred" ] ||
   listcontains "${BUILD_REUSABLE}" "(all|llvm:host)"; then
  PKG_REUSABLE_HASH="$({ get_reusable_inputs_hash llvm spirv-headers spirv-llvm-translator
                         listcontains "${GRAPHIC_DRIVERS}" "(imagination|iris|panfrost)" && echo spirv
                         listcontains "${GRAPHIC_DRIVERS}" "imagination" && echo clang-tblgen
                       } | sha256sum | cut -c1-12)"
  PKG_REUSABLE_VERSION="${OS_VERSION}-${PKG_VERSION}"
  PKG_REUSABLE_SOURCE_NAME="llvm-reusable-${PKG_REUSABLE_VERSION}-${MACHINE_HARDWARE_NAME}-${TARGET_ARCH}-${PKG_REUSABLE_HASH}.tar.xz"
  PKG_REUSABLE_URL="${REUSABLE_URL}/llvm-${PKG_REUSABLE_VERSION}/${PKG_REUSABLE_SOURCE_NAME}"
fi

# preferred falls back to building llvm:host when no reusable archive is available
if [ "${USE_REUSABLE}" = "yes" ] ||
   { [ "${USE_REUSABLE}" = "preferred" ] &&
     [ -n "$(get_reusable_sha256 llvm-reusable ${PKG_REUSABLE_SOURCE_NAME} ${PKG_REUSABLE_URL})" ]; }; then
  # llvm:host then only pulls in the archive, llvm:target is still built
  PKG_REUSABLE="yes"
  PKG_DEPENDS_HOST="llvm-reusable:host"
elif listcontains "${BUILD_REUSABLE}" "(all|llvm:host)"; then
  PKG_DEPENDS_HOST+=" patchelf:host"
fi

post_unpack() {
  if listcontains "${GRAPHIC_DRIVERS}" "(imagination|iris|panfrost)"; then
    mkdir -p "${PKG_BUILD}"/llvm/projects/{SPIRV-Headers,SPIRV-LLVM-Translator}
      tar --strip-components=1 \
        -xf "${SOURCES}/spirv-headers/spirv-headers-$(get_pkg_version spirv-headers).tar.gz" \
        -C "${PKG_BUILD}/llvm/projects/SPIRV-Headers"
      tar --strip-components=1 \
        -xf "${SOURCES}/spirv-llvm-translator/spirv-llvm-translator-$(get_pkg_version spirv-llvm-translator).tar.gz" \
        -C "${PKG_BUILD}/llvm/projects/SPIRV-LLVM-Translator"
  fi
}

pre_configure() {
  PKG_CMAKE_SCRIPT=${PKG_BUILD}/llvm/CMakeLists.txt
}

pre_configure_host() {
  case "${MACHINE_HARDWARE_NAME}" in
    "aarch64")
      LLVM_BUILD_TARGETS="AArch64"
      ;;
    "arm")
      LLVM_BUILD_TARGETS="ARM"
      ;;
    "x86_64")
      LLVM_BUILD_TARGETS="X86"
      ;;
  esac

  case "${TARGET_ARCH}" in
    "aarch64")
      LLVM_BUILD_TARGETS+="\;AArch64"
      ;;
    "arm")
      LLVM_BUILD_TARGETS+="\;ARM"
      ;;
    "x86_64")
      LLVM_BUILD_TARGETS+="\;X86\;AMDGPU"
      ;;
  esac

  mkdir -p ${PKG_BUILD}/.${HOST_NAME}
  cd ${PKG_BUILD}/.${HOST_NAME}
  PKG_CMAKE_OPTS_HOST="${PKG_CMAKE_OPTS_COMMON} \
                       -DCMAKE_BINARY_DIR=${PKG_BUILD}/.${HOST_NAME} \
                       -DLLVM_NATIVE_BUILD=${PKG_BUILD}/.${HOST_NAME}/native \
                       -DLLVM_ENABLE_PROJECTS='clang' \
                       -DCLANG_LINK_CLANG_DYLIB=ON \
                       -DLLVM_TARGETS_TO_BUILD=${LLVM_BUILD_TARGETS}"
}

post_make_host() {
  ninja ${NINJA_OPTS} llc llvm-ar llvm-as llvm-config llvm-cov llvm-dis \
                      llvm-link llvm-nm llvm-objcopy llvm-objdump \
                      llvm-profdata llvm-readobj llvm-size llvm-strip \
                      llvm-tblgen opt

  if listcontains "${GRAPHIC_DRIVERS}" "imagination"; then
    ninja ${NINJA_OPTS} clang-tblgen
  fi

  if listcontains "${GRAPHIC_DRIVERS}" "(imagination|iris|panfrost)"; then
    ninja ${NINJA_OPTS} llvm-spirv
  fi
}

post_makeinstall_host() {
  mkdir -p ${TOOLCHAIN}/bin
    cp -a bin/{llc,llvm-ar,llvm-as,llvm-config,llvm-cov,llvm-dis} "${TOOLCHAIN}/bin"
    cp -a bin/{llvm-link,llvm-nm,llvm-objcopy,llvm-objdump} "${TOOLCHAIN}/bin"
    cp -a bin/{llvm-profdata,llvm-readobj,llvm-size,llvm-strip} "${TOOLCHAIN}/bin"
    cp -a bin/{llvm-tblgen,opt} "${TOOLCHAIN}/bin"

  if listcontains "${GRAPHIC_DRIVERS}" "imagination"; then
    cp -a bin/clang-tblgen "${TOOLCHAIN}/bin"
  fi

  if listcontains "${GRAPHIC_DRIVERS}" "(imagination|iris|panfrost)"; then
    cp -a bin/llvm-spirv "${TOOLCHAIN}/bin"
  fi

  if listcontains "${BUILD_REUSABLE}" "(all|llvm:host)"; then
    save_llvm_reusable
  fi
}

# pack llvm:host as the llvm-reusable archive: the ninja install and the tools
# copied above
save_llvm_reusable() {
  local stage="${PKG_BUILD}/.reusable/stage"
  local dir="${PKG_BUILD}/.reusable/llvm-reusable-${PKG_REUSABLE_VERSION}"
  local tool

  rm -rf "${PKG_BUILD}/.reusable"
  DESTDIR="${stage}" ninja ${NINJA_OPTS} install
  for tool in llc llvm-ar llvm-as llvm-config llvm-cov llvm-dis llvm-link llvm-nm \
              llvm-objcopy llvm-objdump llvm-profdata llvm-readobj llvm-size \
              llvm-strip llvm-tblgen opt clang-tblgen llvm-spirv; do
    if [ -f "${TOOLCHAIN}/bin/${tool}" ]; then
      cp -a "bin/${tool}" "${stage}${TOOLCHAIN}/bin"
    fi
  done
  mv "${stage}${TOOLCHAIN}" "${dir}"
  rm -rf "${stage}"

  reusable_make_relocatable "${dir}"

  {
    echo "archive: ${PKG_REUSABLE_SOURCE_NAME}"
    echo "host: ${MACHINE_HARDWARE_NAME}"
    echo "target arch: ${TARGET_ARCH}"
    echo "graphic drivers: ${GRAPHIC_DRIVERS}"
    echo "llvm: ${PKG_VERSION}"
  } >"${dir}/MANIFEST"

  save_reusable llvm-reusable "${PKG_REUSABLE_SOURCE_NAME}" "${dir}"
}

pre_configure_target() {
  case "${TARGET_ARCH}" in
    "aarch64")
      LLVM_BUILD_TARGETS=""
      LLVM_BUILD_CLANG="-DLLVM_ENABLE_PROJECTS=''"
      ;;
    "arm")
      LLVM_BUILD_TARGETS=""
      LLVM_BUILD_CLANG="-DLLVM_ENABLE_PROJECTS=''"
      ;;
    "x86_64")
      LLVM_BUILD_TARGETS="AMDGPU"
      # do not build clang (not needed)
      # llvm:target is only required to build mesa amd on x86_64 targets
      LLVM_BUILD_CLANG="-DLLVM_ENABLE_PROJECTS=''"
      ;;
  esac

  mkdir -p ${PKG_BUILD}/.${TARGET_NAME}
  cd ${PKG_BUILD}/.${TARGET_NAME}
  PKG_CMAKE_OPTS_TARGET="${PKG_CMAKE_OPTS_COMMON} \
                         -DCMAKE_BINARY_DIR=${PKG_BUILD}/.${TARGET_NAME} \
                         -DLLVM_NATIVE_BUILD=${PKG_BUILD}/.${TARGET_NAME}/native \
                         -DCMAKE_CROSSCOMPILING=ON \
                         ${LLVM_BUILD_CLANG} \
                         -DLLVM_TARGETS_TO_BUILD=${LLVM_BUILD_TARGETS} \
                         -DLLVM_TARGET_ARCH="${TARGET_ARCH}" \
                         -DLLVM_TABLEGEN=${TOOLCHAIN}/bin/llvm-tblgen"
}

post_makeinstall_target() {
  mkdir -p ${SYSROOT_PREFIX}/usr/bin
    cp -a ${TOOLCHAIN}/bin/llvm-config ${SYSROOT_PREFIX}/usr/bin

  rm -rf ${INSTALL}/usr/bin
  rm -rf ${INSTALL}/usr/lib/LLVMHello.so
  rm -rf ${INSTALL}/usr/lib/libLTO.so
  rm -rf ${INSTALL}/usr/share
}

# with llvm-reusable there is nothing to build for llvm:host. Defined last so
# that they replace the host steps above.
if [ "${PKG_REUSABLE}" = "yes" ]; then
  pre_configure_host() { :; }
  configure_host() { :; }
  make_host() { :; }
  post_make_host() { :; }
  makeinstall_host() { :; }
  post_makeinstall_host() { :; }
fi
