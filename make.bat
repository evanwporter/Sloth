@echo off
REM Navigate to the build directory
cd /d C:\Users\evanw\Sloth-1\build

REM Run CMake to configure the project
cmake .. -G "Visual Studio 17 2022"

REM Build the project in Release mode
cmake --build . --config Release

cd ..
