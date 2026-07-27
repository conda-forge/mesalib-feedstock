@echo on

echo MESON_ARGS are %MESON_ARGS%

@REM hmaarrfk - 2026/03
@REM I'm not sure why something is looking for this lib file
copy %LIBRARY_PREFIX%\lib\zstd.lib %LIBRARY_PREFIX%\lib\zstd.dll.lib

meson setup builddir ^
  %MESON_ARGS% ^
  -Dplatforms=windows ^
  -Dgles1=disabled ^
  -Dgles2=disabled ^
  -Dgallium-va=disabled ^
  -Dgbm=disabled ^
  -Dshared-glapi=enabled ^
  -Dgallium-drivers=llvmpipe ^
  -Degl=disabled ^
  -Dglx=disabled ^
  -Dllvm=enabled ^
  -Dvulkan-drivers= ^
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

@REM opengl32.dll is a *drop-in replacement* for the system's opengl32.dll --
@REM see docs/drivers/llvmpipe.rst, "put both DLLs in the same directory as
@REM your application".  Library\bin is the application directory for every
@REM conda-installed .exe, and conda-forge's python calls AddDllDirectory() on
@REM it, and user DLL directories are searched *before* System32.  So leaving
@REM opengl32.dll there hijacks the vendor's OpenGL driver for the whole
@REM environment and silently forces software rendering.
@REM https://github.com/conda-forge/mesalib-feedstock/issues/142
@REM
@REM Park it (and its import library, which would otherwise shadow the Windows
@REM SDK's opengl32.lib at link time) somewhere that is on no DLL search path.
@REM It is still shipped, so software rendering stays available to anyone who
@REM wants it: copy opengl32.dll next to your .exe, which is the usage mesa
@REM itself documents, or add this directory to the DLL search path for a
@REM single process (os.add_dll_directory() from Python, since user DLL
@REM directories are searched ahead of System32).
if not exist %LIBRARY_PREFIX%\opengl32 mkdir %LIBRARY_PREFIX%\opengl32
if %ERRORLEVEL% neq 0 exit 1
move /y %LIBRARY_PREFIX%\bin\opengl32.dll %LIBRARY_PREFIX%\opengl32\opengl32.dll
if %ERRORLEVEL% neq 0 exit 1
move /y %LIBRARY_PREFIX%\lib\opengl32.lib %LIBRARY_PREFIX%\opengl32\opengl32.lib
if %ERRORLEVEL% neq 0 exit 1
