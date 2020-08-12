#!/bin/bash

meson builddir/ \
  -Dbuildtype=release \
  -Dprefix=$PREFIX \
  -Dlibdir=lib \
  -Dplatforms=x11,drm \
  -Dosmesa=gallium \
  -Dosmesa-bits=8 \
  -Dvulkan-drivers=[] \
  -Dgallium-drivers=swrast \
  -Ddri-drivers=[] \
  -Dbuild-tests=true \
  -Dllvm=false 

ninja -C builddir/ -j ${CPU_COUNT}

ninja -C builddir/ install

meson test -C builddir/
