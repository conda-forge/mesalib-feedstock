#!/bin/bash

osname=`uname`

CFLAGS="-std=c11 ${CFLAGS}"

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

