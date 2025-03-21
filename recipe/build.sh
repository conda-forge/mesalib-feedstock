#!/bin/bash

set -ex

export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$BUILD_PREFIX/lib/pkgconfig
export PKG_CONFIG=$BUILD_PREFIX/bin/pkg-config

if [[ $CONDA_BUILD_CROSS_COMPILATION == "1" ]]; then
  if [[ "${CMAKE_CROSSCOMPILING_EMULATOR:-}" == "" ]]; then
    # Mostly taken from https://github.com/conda-forge/pocl-feedstock/blob/b88046a851a95ab3c676c0b7815da8224bd66a09/recipe/build.sh#L52
    rm $PREFIX/bin/llvm-config
    cp $BUILD_PREFIX/bin/llvm-config $PREFIX/bin/llvm-config
    export LLVM_CONFIG=${PREFIX}/bin/llvm-config
  else
    # https://github.com/mesonbuild/meson/issues/4254
    export LLVM_CONFIG=${BUILD_PREFIX}/bin/llvm-config
  fi
fi

meson setup builddir/ \
  ${MESON_ARGS} \
  -Dplatforms=x11 \
  -Dgles1=disabled \
  -Dgles2=disabled \
  -Dgallium-va=disabled \
  -Dgbm=disabled \
  -Dgallium-vdpau=disabled \
  -Dshared-glapi=enabled \
  -Dgallium-drivers=softpipe,llvmpipe \
  -Degl=disabled \
  -Dglx=disabled \
  -Dllvm=enabled \
  -Dshared-llvm=enabled \
  -Dlibdir=lib \
  -Dosmesa=true \
  -Dvulkan-drivers=swrast \
  -Dopengl=true \
  -Dglx-direct=false \
  || { cat builddir/meson-logs/meson-log.txt; exit 1; }

ninja -C builddir/ -j ${CPU_COUNT}

ninja -C builddir/ install

# library_path in the ICD JSON points to the absolute path during the build
# process. Patch it to point to the correct lib path.
# Users should add $CONDA_PREFIX/share/vulkan/icd.d/lvp_icd.x86_64.json
# to VK_DRIVER_FILES environment variable for the VK loader to pick up lavapipe.
ICD_PATH=$PREFIX/share/vulkan/icd.d/lvp_icd.x86_64.json
jq '.ICD.library_path = "../../../lib/libvulkan_lvp.so"' $ICD_PATH > icd_temp.json
mv icd_temp.json $ICD_PATH

# meson test -C builddir/ \
#   -t 4

