#!/bin/bash

set -ex

cat $BUILD_PREFIX/meson_cross_file.txt

echo ${MESON_ARGS}

meson builddir/ \
  ${MESON_ARGS} \
  -Dbuildtype=release \
  --prefix=$PREFIX \
  -Dlibdir=lib \
  -Dplatforms=x11 \
  -Dosmesa=true \
  -Dosmesa-bits=8 \
  -Dvulkan-drivers=[] \
  -Dgallium-drivers=swrast \
  -Ddri-drivers=[] \
  -Dllvm=false || { cat builddir/meson-logs/meson-log.txt; exit 1; }

ninja -C builddir/ -j ${CPU_COUNT}

ninja -C builddir/ install

# meson test -C builddir/ \
#   -t 4

