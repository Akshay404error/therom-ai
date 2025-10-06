@echo off
echo ========================================
echo    Theorem AI - Quick Start Script
echo ========================================
echo.

echo Checking prerequisites...
echo.

REM Check if CMake is installed
cmake --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: CMake is not installed!
    echo Please install CMake from https://cmake.org/download/
    echo.
    pause
    exit /b 1
)

REM Check if Git is installed
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Git is not installed!
    echo Please install Git from https://git-scm.com/download/win
    echo.
    pause
    exit /b 1
)

echo Prerequisites check passed!
echo.

echo Building Theorem AI...
echo.

REM Create build directory
if not exist build mkdir build
cd build

REM Configure with CMake
echo Configuring with CMake...
cmake ..
if %errorlevel% neq 0 (
    echo ERROR: CMake configuration failed!
    echo Please check your C++ compiler installation.
    echo.
    pause
    exit /b 1
)

REM Build the project
echo Building Theorem AI...
cmake --build . --config Release
if %errorlevel% neq 0 (
    echo ERROR: Build failed!
    echo Please check the error messages above.
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo    Build completed successfully!
echo ========================================
echo.

echo You can now run Theorem AI:
echo.
echo 1. Run the demo script:
echo    python ..\demo_theorem_ai.py
echo.
echo 2. Run the hello world example:
echo    stage1\bin\theorem_ai.exe ..\hello.theorem_ai
echo.
echo 3. Start interactive mode:
echo    stage1\bin\theorem_ai.exe --interactive
echo.

pause 