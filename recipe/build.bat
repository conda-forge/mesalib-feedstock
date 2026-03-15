@echo on
@REM microsoft-experimental added for required DirectX-headers

echo MESON_ARGS are %MESON_ARGS%

@REM hmaarrfk - 2026/03
@REM I'm not sure why something is looking for this lib file
copy %LIBRARY_PREFIX%\lib\zstd.lib %LIBRARY_PREFIX%\lib\zstd.dll.lib

meson setup builddir ^
  %MESON_ARGS% ^
  --buildtype=release ^
  --prefix=%LIBRARY_PREFIX% ^
  -Dplatforms=windows ^
  -Dgles1=disabled ^
  -Dgles2=disabled ^
  -Dgallium-va=disabled ^
  -Dgbm=disabled ^
  -Dshared-glapi=enabled ^
  -Dgallium-drivers=softpipe,llvmpipe ^
  -Degl=disabled ^
  -Dglx=disabled ^
  -Dllvm=enabled ^
  -Dvulkan-drivers=swrast,microsoft-experimental ^
  -Dopengl=true ^
  -Dglx-direct=false
if %ERRORLEVEL% neq 0 exit 1

@REM As of Aug 2025, LLVM doesn't not have support for shared libs on Windows
@REM See https://github.com/conda-forge/llvmdev-feedstock/issues/237
@REM -Dshared-llvm=enabled ^

meson compile -C builddir
if %ERRORLEVEL% neq 0 exit 1

ninja -C builddir install
if %ERRORLEVEL% neq 0 exit 1

@REM hmaarrfk - 2026/03
@REM I'm not sure why something is looking for this lib file
@REM Removed so it doesn't get included as part of the final package
del %LIBRARY_PREFIX%\lib\zstd.dll.lib
