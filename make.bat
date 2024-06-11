@echo off
setlocal

REM Check command-line arguments
echo Command-line argument: %1

if "%1"=="clean" goto clean
if "%1"=="package" goto package
if "%1"=="compile" goto compile
if "%1"=="html" goto html

REM Default case: no valid argument provided
echo No valid argument provided.
echo Usage: make.bat [clean|package|compile|html]
goto end

REM Define the clean function
:clean
echo Deleting all .c and .pyd files from the Sloth directory and its subdirectories...
del /s /q "Sloth\*.c"
del /s /q "Sloth\*.pyd"

echo Removing the build directory...
rmdir /s /q "build"

if exist "docs\build" (
    echo Removing the docs\build directory...
    rmdir /s /q "docs\build"
)

echo Cleanup completed.
goto end

REM Define the package function
:package
echo Packaging the project...
python setup.py sdist bdist_wheel
pip install .
goto end

REM Define the compile function
:compile
echo Compiling Cython files...
python setup.py build_ext --inplace
goto end

REM Define the html function
:html
echo Building HTML documentation...
sphinx-build -M html ./docs/source ./docs/build/ -E
goto end

:end
endlocal
