#!/bin/bash

set -ex

export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$BUILD_PREFIX/lib/pkgconfig
export PKG_CONFIG=$BUILD_PREFIX/bin/pkg-config

# Unlike the gallium drivers, a Vulkan ICD statically links the Vulkan runtime,
# NIR and mesa-util that it needs, so there is no shared library to factor out
# and each driver gets its own meson configuration.  Mesa has no option to link
# that runtime shared -- see src/vulkan/{runtime,util,wsi}/meson.build, all of
# which are unconditional static_library() -- because a process routinely loads
# several ICDs at once and they must not share mesa-internal symbols.
case "${PKG_NAME}" in
  mesa-lavapipe)     VULKAN_DRIVERS="swrast" ;;
  mesa-anv)          VULKAN_DRIVERS="intel" ;;
  mesa-hasvk)        VULKAN_DRIVERS="intel_hasvk" ;;
  mesa-venus)        VULKAN_DRIVERS="virtio" ;;
  mesa-kosmickrisp)  VULKAN_DRIVERS="kosmickrisp" ;;
  *)
    echo "build_vulkan.sh has no vulkan-drivers mapping for ${PKG_NAME}" >&2
    exit 1
    ;;
esac

if [[ "${target_platform}" == osx-* ]]; then
  MESA_PLATFORMS="macos"
  ICD_NAME_SUFFIX=""
else
  MESA_PLATFORMS="x11"
  ICD_NAME_SUFFIX="conda"
fi

if [[ $CONDA_BUILD_CROSS_COMPILATION == "1" ]]; then
  if [[ "${CMAKE_CROSSCOMPILING_EMULATOR:-}" == "" ]]; then
    rm $PREFIX/bin/llvm-config
    cp $BUILD_PREFIX/bin/llvm-config $PREFIX/bin/llvm-config
    export LLVM_CONFIG=${PREFIX}/bin/llvm-config
  else
    export LLVM_CONFIG=${BUILD_PREFIX}/bin/llvm-config
  fi
fi

meson setup builddir/ \
  ${MESON_ARGS} \
  -Dplatforms=${MESA_PLATFORMS} \
  -Dgles1=disabled \
  -Dgles2=disabled \
  -Dgallium-va=disabled \
  -Dvideo-codecs= \
  -Dgbm=disabled \
  -Dshared-glapi=enabled \
  -Dgallium-drivers= \
  -Degl=disabled \
  -Dglx=disabled \
  -Dllvm=enabled \
  -Dshared-llvm=enabled \
  -Dlibdir=lib \
  -Dvulkan-drivers=${VULKAN_DRIVERS} \
  -Dvulkan-icd-name-suffix=${ICD_NAME_SUFFIX} \
  -Dopengl=true \
  -Dglx-direct=false \
  || { cat builddir/meson-logs/meson-log.txt; exit 1; }

ninja -C builddir/ -j ${CPU_COUNT}

ninja -C builddir/ install
