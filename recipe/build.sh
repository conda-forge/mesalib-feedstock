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
  -Dllvm=false

ninja -C builddir/ -j ${CPU_COUNT}

ninja -C builddir/ install

# meson test -C builddir/ \
#   -t 4

