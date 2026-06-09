#!/bin/bash

set -ex

export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$BUILD_PREFIX/lib/pkgconfig
export PKG_CONFIG=$BUILD_PREFIX/bin/pkg-config

VULKAN_DRIVERS="swrast"

if [[ "${target_platform}" == osx-* ]]; then
  MESA_PLATFORMS="macos"
else
  MESA_PLATFORMS="x11"
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

# For macOS cross-compilation, build native vtn_bindgen2 first
if [[ $CONDA_BUILD_CROSS_COMPILATION == "1" && "${target_platform}" == osx-* ]]; then
  CROSS_CC=$CC
  CROSS_CXX=$CXX
  CROSS_OBJC=$OBJC

  export CC=$CC_FOR_BUILD
  export CXX=$CXX_FOR_BUILD
  export OBJC=$OBJC_FOR_BUILD

  CROSS_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
  CROSS_LDFLAGS="$LDFLAGS"
  CROSS_CFLAGS="$CFLAGS"
  CROSS_CXXFLAGS="$CXXFLAGS"
  CROSS_LLVM_CONFIG="$LLVM_CONFIG"

  export PKG_CONFIG_PATH="$BUILD_PREFIX/lib/pkgconfig"
  export LDFLAGS="-L$BUILD_PREFIX/lib -Wl,-rpath,$BUILD_PREFIX/lib"
  export CFLAGS="-I$BUILD_PREFIX/include"
  export CXXFLAGS="-I$BUILD_PREFIX/include -stdlib=libc++"
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

  export PKG_CONFIG_PATH="$CROSS_PKG_CONFIG_PATH"
  export LDFLAGS="$CROSS_LDFLAGS"
  export CFLAGS="$CROSS_CFLAGS"
  export CXXFLAGS="$CROSS_CXXFLAGS"
  export LLVM_CONFIG="$CROSS_LLVM_CONFIG"

  export PATH="$SRC_DIR/builddir-native/src/compiler/spirv:$SRC_DIR/builddir-native/src/compiler/clc:$PATH"

  MESA_CLC_OPT="-Dmesa-clc=system"

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
  -Dgallium-drivers= \
  -Degl=disabled \
  -Dglx=disabled \
  -Dllvm=enabled \
  -Dshared-llvm=enabled \
  -Dlibdir=lib \
  -Dvulkan-drivers=${VULKAN_DRIVERS} \
  -Dopengl=true \
  -Dglx-direct=false \
  ${MESA_CLC_OPT:-} \
  || { cat builddir/meson-logs/meson-log.txt; exit 1; }

ninja -C builddir/ -j ${CPU_COUNT}

ninja -C builddir/ install
