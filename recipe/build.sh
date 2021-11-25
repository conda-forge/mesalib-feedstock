#!/bin/bash

set -ex

export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$BUILD_PREFIX/lib/pkgconfig
export PKG_CONFIG=$BUILD_PREFIX/bin/pkg-config

meson builddir/ \
  ${MESON_ARGS} \
  --buildtype=release \
  --prefix=$PREFIX \
  -Dlibdir=lib \
  -Dplatforms=x11 \
  -Dosmesa=true \
  -Dvulkan-drivers=[] \
  -Dgallium-drivers=swrast \
  -Ddri-drivers=[] \
  -Dllvm=false || { cat builddir/meson-logs/meson-log.txt; exit 1; }

ninja -C builddir/ -j ${CPU_COUNT}

ninja -C builddir/ install

# meson test -C builddir/ \
#   -t 4

