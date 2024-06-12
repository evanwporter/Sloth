@echo off
:: Batch script to deploy gh-pages branch to GitHub Pages

:: Configurations
set REPO_URL=https://github.com/evanwporter/Sloth.git
set DOCS_DIR=docs
set BUILD_DIR=%DOCS_DIR%/build
set SPHINX_BUILD_COMMAND=sphinx-build -b html %DOCS_DIR%/source %BUILD_DIR% -E

:: Check if on gh-pages branch
echo Checking current branch...
git rev-parse --abbrev-ref HEAD
if not "%ERRORLEVEL%"=="0" goto error

for /f "tokens=*" %%i in ('git rev-parse --abbrev-ref HEAD') do set BRANCH_NAME=%%i

if not "%BRANCH_NAME%"=="gh-pages" (
    echo You are not on the gh-pages branch.
    echo Please switch to the gh-pages branch and run this script again.
    goto end
)

:: Build the Sphinx documentation
echo Building Sphinx documentation...
%SPHINX_BUILD_COMMAND%
if not "%ERRORLEVEL%"=="0" goto error

:: Commit the changes
echo Adding and committing changes...
git add %BUILD_DIR%/*
git commit -m "Update GitHub Pages"
if not "%ERRORLEVEL%"=="0" goto error

:: Push to gh-pages branch
echo Pushing to gh-pages branch...
git push origin gh-pages
if not "%ERRORLEVEL%"=="0" goto error

echo Deployment to GitHub Pages successful!

goto end

:error
echo An error occurred. Please check the output above for more details.

:end
pause
