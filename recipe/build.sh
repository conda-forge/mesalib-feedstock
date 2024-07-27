#!/bin/bash

set -ex

export PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:${BUILD_PREFIX}/lib/pkgconfig"
export PKG_CONFIG="${BUILD_PREFIX}/bin/pkg-config"

if [[ "${target_platform}" == linux-* ]]; then
    LLVM_ENABLED=enabled
    if [[ $CONDA_BUILD_CROSS_COMPILATION == "1" ]]; then
        # https://github.com/mesonbuild/meson/issues/4254
        export LLVM_CONFIG=${BUILD_PREFIX}/bin/llvm-config
    fi
else
    LLVM_ENABLED=disabled
fi

meson setup builddir \
  ${MESON_ARGS} \
  --prefix=$PREFIX \
  -Dplatforms=auto \
  -Dgles1=disabled \
  -Dgles2=disabled \
  -Dgallium-va=disabled \
  -Dgallium-vdpau=disabled \
  -Dgallium-drivers=swrast \
  -Dgbm=$LLVM_ENABLED \
  -Dshared-glapi=enabled \
  -Ddri3=disabled \
  -Degl=disabled \
  -Dglx=disabled \
  -Dllvm=$LLVM_ENABLED \
  -Dshared-llvm=$LLVM_ENABLED \
  -Dlibdir=lib \
  -Dosmesa=true \
  -Dvulkan-drivers=[] \
  -Dopengl=true \
  -Dglx-direct=false \
  || { cat builddir/meson-logs/meson-log.txt; exit 1; }

ninja -C builddir/ -j ${CPU_COUNT}

ninja -C builddir/ install

# meson test -C builddir/ \
#   -t 4
