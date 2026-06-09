@echo on
@REM microsoft-experimental added for required DirectX-headers

echo MESON_ARGS are %MESON_ARGS%

@REM MESON_ARGS (from the meson conda package activation) already supplies
@REM -Dbuildtype=release and --prefix; passing them again makes meson error
@REM with "Got argument buildtype as both -Dbuildtype and --buildtype".
meson setup builddir ^
  %MESON_ARGS% ^
  -Dplatforms=windows ^
  -Dgles1=disabled ^
  -Dgles2=disabled ^
  -Dgallium-va=disabled ^
  -Dgbm=disabled ^
  -Dgallium-drivers= ^
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
