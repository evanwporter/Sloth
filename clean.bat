@echo off
REM Delete all .c and .pyd files from the Sloth directory and its subdirectories
echo Deleting all .c and .pyd files from the Sloth directory and its subdirectories...
del /s /q "Sloth\*.c"
del /s /q "Sloth\*.pyd"

REM Remove the build directory
echo Removing the build directory...
rmdir /s /q "build"

REM Remove the build directory inside docs if it exists
if exist "docs\build" (
    echo Removing the docs\build directory...
    rmdir /s /q "docs\build"
)

echo Cleanup completed.
pause
