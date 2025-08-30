@echo off

set EXE_NAME=gjk.exe
set SDL_VERSION=release-3.2.16
set VSDEVCMD="C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat"

if not exist build mkdir build
if not exist build\output mkdir build\output
if not exist build\vendor mkdir build\vendor

cls

if "%~1" == "get-sdl3" (
    curl -L -o build\output\SDL3.dll https://raw.githubusercontent.com/odin-lang/Odin/master/vendor/sdl3/SDL3.dll
    curl -L -o build\output\SDL3.lib https://raw.githubusercontent.com/odin-lang/Odin/master/vendor/sdl3/SDL3.lib
)

if "%~1" == "build-sdl3" (
    cd build\vendor
    git clone https://github.com/libsdl-org/SDL.git sdl
    cd sdl
    git checkout %SDL_VERSION%
    %VSDEVCMD%
    cmake -S . -B build
    cmake --build build --config Release
    cd ..\..
    copy /Y "vendor\sdl\build\Release\SDL3.dll" "output\SDL3.dll"
    copy /Y "vendor\sdl\build\Release\SDL3.lib" "output\SDL3.lib"
)

if "%~1" == "build" (
    odin build source -out:build\output\%EXE_NAME%
)

if "%~1" == "run" (
    odin run source -out:build\output\%EXE_NAME%
)

if "%~1" == "build-debug" (
    odin build source -out:build\output\%EXE_NAME% -debug
)

if "%~1" == "run-debug" (
    odin run source -out:build\output\%EXE_NAME% -debug
)
