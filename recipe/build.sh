#!/bin/bash

set -ex

meson builddir/ \
  ${MESON_ARGS} \
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

