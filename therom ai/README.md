# Theorem AI

**Theorem AI** is a next-generation theorem prover and functional programming language designed for mathematical reasoning, formal verification, and advanced AI applications.

## 🚀 Quick Start

### Prerequisites

Before running Theorem AI, make sure you have the following installed:

- **CMake** (version 3.11 or higher)
- **C++ compiler** (GCC, Clang, or MSVC)
- **Git**
- **Python 3** (for demo script)

### Installation

#### Option 1: Build from Source (Recommended)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Akshay404error/therom-ai.git
   cd theorem-ai
   ```

2. **Create build directory:**
   ```bash
   mkdir build
   cd build
   ```

3. **Configure with CMake:**
   ```bash
   cmake ..
   ```

4. **Build the project:**
   ```bash
   make -j$(nproc)  # On Windows: make -j%NUMBER_OF_PROCESSORS%
   ```

5. **Install (optional):**
   ```bash
   make install
   ```

#### Option 2: Using Package Manager

```bash
# Using Nix (if available)
nix-shell
```

## 🎯 How to Run Code

### Running Theorem AI Files

1. **Run a single file:**
   ```bash
   ./build/stage1/bin/theorem_ai your_file.theorem_ai
   ```

2. **Start interactive mode:**
   ```bash
   ./build/stage1/bin/theorem_ai --interactive
   ```

3. **Run with specific options:**
   ```bash
   ./build/stage1/bin/theorem_ai --help
   ```

### Example Code

#### Basic Example
Create a file `hello.theorem_ai`:
```theorem_ai
-- Hello World in Theorem AI
def hello : String := "Hello, Theorem AI!"

#eval hello
```

Run it:
```bash
./build/stage1/bin/theorem_ai hello.theorem_ai
```

#### Mathematical Example
Create a file `math.theorem_ai`:
```theorem_ai
-- Mathematical functions
def factorial (n : Nat) : Nat :=
  match n with
  | 0 => 1
  | n + 1 => (n + 1) * factorial n

#eval factorial 5
```

### Running Examples

The repository includes several examples in the `doc/examples/` directory:

```bash
# Run binary tree example
./build/stage1/bin/theorem_ai doc/examples/bintree.theorem_ai

# Run palindrome checker
./build/stage1/bin/theorem_ai doc/examples/palindromes.theorem_ai

# Run interpreter example
./build/stage1/bin/theorem_ai doc/examples/interp.theorem_ai
```

### Running Tests

```bash
# Run all tests
make test

# Run specific test
./build/stage1/bin/theorem_ai tests/theorem_ai/run/example.theorem_ai
```

### Demo Script

Run the demo to see an overview of Theorem AI:

```bash
python demo_theorem_ai.py
```

## 📁 Project Structure

```
theorem-ai/
├── src/                    # Source code
│   ├── TheoremAI/          # Core library
│   ├── Init/               # Initialization modules
│   ├── Std/                # Standard library
│   └── lake/               # Build system
├── tests/                  # Test suite
├── doc/                    # Documentation
├── examples/               # Example code
└── build/                  # Build artifacts (created during build)
```

## 🔧 Development

### Building for Development

```bash
# Debug build
mkdir build-debug
cd build-debug
cmake -DCMAKE_BUILD_TYPE=Debug ..
make -j$(nproc)
```

### Running Tests

```bash
# Run all tests
make test

# Run specific test category
make test-theorem_ai
```





## 📥 Download

The **Download** button in the navigation provides several options:

1. **Source Code** - Download the complete source code as a ZIP file
2. **Pre-built Binaries** - Download compiled executables for your platform
3. **Documentation** - Download offline documentation packages

### What's Included in Downloads

- **Complete Source Code** (290+ C++ files, thousands of Theorem AI files)
- **Build Scripts** - Automated setup for Windows, Linux, and macOS
- **Documentation** - Comprehensive guides and references
- **Examples** - Sample programs and proofs
- **Test Suite** - Complete testing framework

### System Requirements

- **Windows**: Windows 10/11 with Visual Studio Build Tools
- **macOS**: macOS 10.15+ with Xcode Command Line Tools
- **Linux**: Ubuntu 18.04+ or equivalent with build essentials

## 🆘 Troubleshooting

### Common Issues

1. **CMake not found:**
   ```bash
   # Install CMake
   # Windows: Download from cmake.org
   # macOS: brew install cmake
   # Linux: sudo apt-get install cmake
   ```

2. **Compiler not found:**
   ```bash
   # Install C++ compiler
   # Windows: Install Visual Studio Build Tools
   # macOS: Install Xcode Command Line Tools
   # Linux: sudo apt-get install build-essential
   ```

3. **Build fails:**
   ```bash
   # Clean and rebuild
   rm -rf build
   mkdir build && cd build
   cmake ..
   make -j$(nproc)
   ```

## 🆘 Support

- **Documentation**: Check the [docs](docs/) directory
- **Community**: Join our [Discord server](https://discord.gg/UQYSkach)
- **Issues**: Report bugs on [GitHub](https://github.com/Akshay404error/therom-ai/issues)
- **Contact**: Email us at akshay2005air@gmail.com

---

**Theorem AI** - Advancing mathematical reasoning and AI through formal verification.
