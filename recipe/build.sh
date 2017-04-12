#!/bin/bash

osname=`uname`
if [ $osname == Linux ]; then
    export CC="gcc"
    export CXX="g++"
elif [ $osname == Darwin ]; then
    export CC="clang"
    export CXX="clang++"
fi

export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig/:"${PKG_CONFIG_PATH}
export CFLAGS="-I${PREFIX}/include "${CFLAGS}
export LDFLAGS="-L${PREFIX}/lib "${LDFLAGS}

./configure \
    --prefix=$PREFIX \
    --enable-opengl \
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
    --disable-glx

make -j${CPU_COUNT}
make install

