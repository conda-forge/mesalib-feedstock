#!/bin/bash

set -ex

# Possible ctng-compiler-activation bug - MESON_SYSTEM is undefined, should be MESON_NAME
# This sets system = 'linux' in the cross file where it's currently empty
# Submitted Issue: https://github.com/conda-forge/ctng-compiler-activation-feedstock/issues/174
if [[ $CONDA_BUILD_CROSS_COMPILATION == "1" && "${target_platform}" == linux-* ]]; then
  sed -i "s/^system = ''$/system = 'linux'/" $BUILD_PREFIX/meson_cross_file.txt
  echo "=== Patched meson cross file ==="
  cat $BUILD_PREFIX/meson_cross_file.txt
fi

export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$BUILD_PREFIX/lib/pkgconfig
export PKG_CONFIG=$BUILD_PREFIX/bin/pkg-config

VULKAN_DRIVERS="swrast"

if [[ "${target_platform}" == osx-* ]]; then
  MESA_PLATFORMS="macos"
else
  MESA_PLATFORMS="x11"
fi

if [[ $CONDA_BUILD_CROSS_COMPILATION == "1" ]]; then
  if [[ "${CMAKE_CROSSCOMPILING_EMULATOR:-}" == "" ]]; then
    rm $PREFIX/bin/llvm-config
    cp $BUILD_PREFIX/bin/llvm-config $PREFIX/bin/llvm-config
    export LLVM_CONFIG=${PREFIX}/bin/llvm-config
  else
    export LLVM_CONFIG=${BUILD_PREFIX}/bin/llvm-config
  fi
fi

meson setup builddir/ \
  ${MESON_ARGS} \
  -Dplatforms=${MESA_PLATFORMS} \
  -Dgles1=disabled \
  -Dgles2=disabled \
  -Dgallium-va=disabled \
  -Dgbm=disabled \
  -Dshared-glapi=enabled \
  -Dgallium-drivers= \
  -Degl=disabled \
  -Dglx=disabled \
  -Dllvm=enabled \
  -Dshared-llvm=enabled \
  -Dlibdir=lib \
  -Dvulkan-drivers=${VULKAN_DRIVERS} \
  -Dopengl=true \
  -Dglx-direct=false \
  || { cat builddir/meson-logs/meson-log.txt; exit 1; }

ninja -C builddir/ -j ${CPU_COUNT}

ninja -C builddir/ install

# meson test -C builddir/ \
#   -t 4
