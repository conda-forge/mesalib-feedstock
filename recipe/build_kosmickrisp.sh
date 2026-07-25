#!/bin/bash

set -ex

export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$BUILD_PREFIX/lib/pkgconfig
export PKG_CONFIG=$BUILD_PREFIX/bin/pkg-config

meson setup builddir/ \
  ${MESON_ARGS} \
  -Dplatforms=macos \
  -Dgles1=disabled \
  -Dgles2=disabled \
  -Dgallium-va=disabled \
  -Dgbm=disabled \
  -Dgallium-drivers= \
  -Degl=disabled \
  -Dglx=disabled \
  -Dllvm=enabled \
  -Dshared-llvm=enabled \
  -Dlibdir=lib \
  -Dvulkan-drivers=kosmickrisp \
  -Dopengl=true \
  -Dglx-direct=false \
  || { cat builddir/meson-logs/meson-log.txt; exit 1; }

ninja -C builddir/ -j ${CPU_COUNT}

ninja -C builddir/ install
