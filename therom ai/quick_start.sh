#!/bin/bash

echo "========================================"
echo "    Theorem AI - Quick Start Script"
echo "========================================"
echo

echo "Checking prerequisites..."
echo

# Check if CMake is installed
if ! command -v cmake &> /dev/null; then
    echo "ERROR: CMake is not installed!"
    echo "Please install CMake:"
    echo "  Ubuntu/Debian: sudo apt-get install cmake"
    echo "  macOS: brew install cmake"
    echo "  Or download from https://cmake.org/download/"
    echo
    exit 1
fi

# Check if Git is installed
if ! command -v git &> /dev/null; then
    echo "ERROR: Git is not installed!"
    echo "Please install Git:"
    echo "  Ubuntu/Debian: sudo apt-get install git"
    echo "  macOS: brew install git"
    echo "  Or download from https://git-scm.com/download/"
    echo
    exit 1
fi

# Check if make is installed
if ! command -v make &> /dev/null; then
    echo "ERROR: Make is not installed!"
    echo "Please install Make:"
    echo "  Ubuntu/Debian: sudo apt-get install build-essential"
    echo "  macOS: Install Xcode Command Line Tools"
    echo
    exit 1
fi

echo "Prerequisites check passed!"
echo

echo "Building Theorem AI..."
echo

# Create build directory
mkdir -p build
cd build

# Configure with CMake
echo "Configuring with CMake..."
cmake ..
if [ $? -ne 0 ]; then
    echo "ERROR: CMake configuration failed!"
    echo "Please check your C++ compiler installation."
    echo
    exit 1
fi

# Build the project
echo "Building Theorem AI..."
make -j$(nproc 2>/dev/null || sysctl -n hw.logicalcpu 2>/dev/null || echo 4)
if [ $? -ne 0 ]; then
    echo "ERROR: Build failed!"
    echo "Please check the error messages above."
    echo
    exit 1
fi

echo
echo "========================================"
echo "    Build completed successfully!"
echo "========================================"
echo

echo "You can now run Theorem AI:"
echo
echo "1. Run the demo script:"
echo "   python ../demo_theorem_ai.py"
echo
echo "2. Run the hello world example:"
echo "   ./stage1/bin/theorem_ai ../hello.theorem_ai"
echo
echo "3. Start interactive mode:"
echo "   ./stage1/bin/theorem_ai --interactive"
echo
echo "4. Run tests:"
echo "   make test"
echo 