#!/bin/bash
# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* ./bin
set -ex

osname=`uname`

export CFLAGS="-Wno-implicit-function-declaration ${CFLAGS} -std=c11 -Wno-implicit-function-declaration"
echo $CFLAGS

./configure \
    --prefix=$PREFIX \
    --disable-gles1 \
    --disable-gles2 \
    --disable-va \
    --disable-gbm \
    --disable-xvmc \
    --disable-vdpau \
    --enable-shared-glapi \
    --enable-texture-float \
    --disable-dri \
    --with-dri-drivers= \
    --with-gallium-drivers=swrast \
    --disable-egl \
    --with-egl-platforms= \
    --enable-gallium-osmesa \
    --disable-glx \
    --enable-llvm \
    --disable-llvm-shared-libs \
    --with-osmesa-bits=32

make -j${CPU_COUNT}
make install

