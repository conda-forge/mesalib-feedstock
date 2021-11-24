#!/bin/bash

set -ex

meson builddir/ \
  -Dbuildtype=release \
  -Dprefix=$PREFIX \
  -Dlibdir=lib \
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

meson builddir/ \
  -Dbuildtype=release \
  -Dprefix=$PREFIX \
  -Dlibdir=lib \
  -Dplatforms=x11 \
  -Dosmesa=true \
  -Dosmesa-bits=32 \
  -Dvulkan-drivers=[] \
  -Dgallium-drivers=swrast \
  -Ddri-drivers=[] \
  -Dllvm=false

ninja -C builddir/ -j ${CPU_COUNT}

ninja -C builddir/ install

