#!/bin/bash

set -ex

if [[ $CONDA_BUILD_CROSS_COMPILATION == "1" ]] && [[ "${target_platform}" == linux-* ]] ; then
    # https://github.com/mesonbuild/meson/issues/4254
    export LLVM_CONFIG=${BUILD_PREFIX}/bin/llvm-config
fi

export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$BUILD_PREFIX/lib/pkgconfig
export PKG_CONFIG=$BUILD_PREFIX/bin/pkg-config

if [[ "${target_platform}" == linux-* ]]; then
    LLVM_ENABLED=true
else
    LLVM_ENABLED=false
fi

meson setup builddir/ \
  ${MESON_ARGS} \
  --buildtype=release \
  --prefix=$PREFIX \
  -Dplatforms=x11 \
  -Dgles1=disabled \
  -Dgles2=disabled \
  -Dgallium-va=disabled \
  -Dgbm=disabled \
  -Dgallium-vdpau=disabled \
  -Dshared-glapi=enabled \
  -Ddri3=disabled \
  -Ddri-drivers=[] \
  -Dgallium-drivers=swrast \
  -Degl=disabled \
  -Dglx=disabled \
  -Dllvm=$LLVM_ENABLED \
  -Dshared-llvm=$LLVM_ENABLED \
  -Dlibdir=lib \
  -Dosmesa=true \
  -Dvulkan-drivers=[] \
  -Dopengl=true \
  -Dglx-direct=false \
  ${EXTRA_FLAGS} \
  || { cat builddir/meson-logs/meson-log.txt; exit 1; }

ninja -C builddir/ -j ${CPU_COUNT}

ninja -C builddir/ install

# meson test -C builddir/ \
#   -t 4

