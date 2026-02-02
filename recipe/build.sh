#!/bin/bash

set -ex

# Possible ctng-compiler-activation bug - MESON_SYSTEM is undefined, should be MESON_NAME
# This sets system = 'linux' in the cross file where it's currently empty
# Submitted Issue: https://github.com/conda-forge/ctng-compiler-activation-feedstock/issues/174
if [[ $CONDA_BUILD_CROSS_COMPILATION == "1" && "${target_platform}" == linux-* ]]; then
  sed -i "s/^system = ''$/system = 'linux'/" $BUILD_PREFIX/meson_cross_file.txt
  echo "=== Patched meson cross file ==="
  cat $BUILD_PREFIX/meson_cross_file.txt
fi

export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$BUILD_PREFIX/lib/pkgconfig
export PKG_CONFIG=$BUILD_PREFIX/bin/pkg-config

VULKAN_DRIVERS="swrast"

# macOS: Use native macos platform to avoid X11 header conflicts
# The macOS sysroot has old X11 headers that conflict with newer xorg-libx11
if [[ "${target_platform}" == osx-* ]]; then
  MESA_PLATFORMS="macos"
  VULKAN_DRIVERS="${VULKAN_DRIVERS},kosmickrisp"
else
  MESA_PLATFORMS="x11"
fi

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

# For macOS cross-compilation, build native vtn_bindgen2 first
if [[ $CONDA_BUILD_CROSS_COMPILATION == "1" && "${target_platform}" == osx-* ]]; then
  # Save cross compilers
  CROSS_CC=$CC
  CROSS_CXX=$CXX
  CROSS_OBJC=$OBJC

  # Use native compilers for tool build
  export CC=$CC_FOR_BUILD
  export CXX=$CXX_FOR_BUILD
  export OBJC=$OBJC_FOR_BUILD

  # Save cross-compilation environment
  CROSS_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
  CROSS_LDFLAGS="$LDFLAGS"
  CROSS_CFLAGS="$CFLAGS"
  CROSS_CXXFLAGS="$CXXFLAGS"
  CROSS_LLVM_CONFIG="$LLVM_CONFIG"

  # Override paths to use BUILD_PREFIX (x86_64) libraries, not PREFIX (arm64)
  export PKG_CONFIG_PATH="$BUILD_PREFIX/lib/pkgconfig"
  export LDFLAGS="-L$BUILD_PREFIX/lib"
  export CFLAGS="-I$BUILD_PREFIX/include"
  export CXXFLAGS="-I$BUILD_PREFIX/include"
  export LLVM_CONFIG="$BUILD_PREFIX/bin/llvm-config"

  meson setup builddir-native/ \
    --prefix="$SRC_DIR/native-install" \
    -Dplatforms= \
    -Dvulkan-drivers= \
    -Dgallium-drivers= \
    -Dglx=disabled \
    -Degl=disabled \
    -Dllvm=enabled \
    -Dmesa-clc=enabled \
    -Dinstall-mesa-clc=true

  ninja -C builddir-native/

  # Restore cross-compilation environment
  export PKG_CONFIG_PATH="$CROSS_PKG_CONFIG_PATH"
  export LDFLAGS="$CROSS_LDFLAGS"
  export CFLAGS="$CROSS_CFLAGS"
  export CXXFLAGS="$CROSS_CXXFLAGS"
  export LLVM_CONFIG="$CROSS_LLVM_CONFIG"

  # Add paths for both vtn_bindgen2 and mesa_clc
  export PATH="$SRC_DIR/builddir-native/src/compiler/spirv:$SRC_DIR/builddir-native/src/compiler/clc:$PATH"

  # Restore cross compilers
  export CC=$CROSS_CC
  export CXX=$CROSS_CXX
  export OBJC=$CROSS_OBJC
fi

meson setup builddir/ \
  ${MESON_ARGS} \
  -Dplatforms=${MESA_PLATFORMS} \
  -Dgles1=disabled \
  -Dgles2=disabled \
  -Dgallium-va=disabled \
  -Dgbm=disabled \
  -Dshared-glapi=enabled \
  -Dgallium-drivers=softpipe,llvmpipe \
  -Degl=disabled \
  -Dglx=disabled \
  -Dllvm=enabled \
  -Dshared-llvm=enabled \
  -Dlibdir=lib \
  -Dvulkan-drivers=${VULKAN_DRIVERS} \
  -Dopengl=true \
  -Dglx-direct=false \
  -Dmesa-clc=system \
  || { cat builddir/meson-logs/meson-log.txt; exit 1; }

ninja -C builddir/ -j ${CPU_COUNT}

ninja -C builddir/ install

# meson test -C builddir/ \
#   -t 4
