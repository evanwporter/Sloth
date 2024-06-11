@echo off
setlocal

REM Check command-line arguments
echo Command-line argument: %1

if "%1"=="clean" goto clean
if "%1"=="package" goto package
if "%1"=="compile" goto compile
if "%1"=="html" goto html
if "%1"=="profile" goto profile

REM Default case: no valid argument provided
echo No valid argument provided.
echo Usage: make.bat [clean|package|compile|html|profile [profile_file]]
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

echo Removing the test\profile directory...
if exist "test\profile" (
    rmdir /s /q "test\profile"
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

REM Define the profile function
:profile
REM Create the test\profile directory if it doesn't exist
if not exist "tests\profile" (
    mkdir "tests\profile"
)

set PROF_FILE=%2
if "%PROF_FILE%"=="" (
    set PROF_FILE=Sloth.prof
)

set PROFILE_PATH=tests\profile\%PROF_FILE%

echo Profiling the project and saving to %PROFILE_PATH%...

REM Ensure the profile_example.py script is configured correctly to profile your code.
python -m cProfile -o %PROFILE_PATH% "tests\profiler.py"

REM Optionally convert the profiling data to a call graph using gprof2dot
if exist %PROFILE_PATH% (
    gprof2dot -f pstats %PROFILE_PATH% | dot -Tpng -o %PROFILE_PATH%.png
    echo Call graph generated as %PROFILE_PATH%.png
)

echo Profiling completed.
goto end

:end
endlocal
