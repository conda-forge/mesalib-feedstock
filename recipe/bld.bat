meson setup builddir ^
  --prefix=%LIBRARY_PREFIX% ^
  --buildtype=release ^
  -Dplatforms=windows ^
  -Dgles1=disabled ^
  -Dgles2=disabled ^
  -Dgallium-va=disabled ^
  -Dgbm=disabled ^
  -Dgallium-vdpau=disabled ^
  -Dshared-glapi=enabled ^
  -Dgallium-drivers=softpipe,llvmpipe ^
  -Degl=disabled ^
  -Dglx=disabled ^
  -Dllvm=enabled ^
  -Dosmesa=true ^
  -Dvulkan-drivers=swrast ^
  -Dopengl=true ^
  -Dglx-direct=false

@REM As of Mar 2025, LLVM doesn't not have support for shared libs on Windows
@REM See https://github.com/conda-forge/llvmdev-feedstock/issues/237
@REM -Dshared-llvm=enabled ^

meson compile -C builddir

ninja -C builddir install