# Theorem AI

**Theorem AI** is a next-generation theorem prover and functional programming language designed for mathematical reasoning, formal verification, and advanced AI applications.

## 🚀 Quick Start (1st Method - No Build Required)

### Prerequisites

- **Python 3.8+** (for demo script)
- **Web Browser** (Chrome, Firefox, or Edge)

### Option 1: Web Interface
1. Open `index.html` in your web browser
2. Explore the web-based interface for Theorem AI

### Option 2: Python Demo
```bash
python demo_theorem_ai.py
```

## 🛠️ Advanced Installation (2nd Method - Build from Source)

### Prerequisites
- **CMake** (version 3.11 or higher)
- **C++ compiler** (GCC, Clang, or MSVC)
- **Git**
- **Python 3**

### Build Steps
1. **Clone the repository:**
   ```bash
   git clone https://github.com/Akshay404error/therom-ai.git
   cd theorem-ai
   ```

2. **Run the quick start script (Windows):**
   ```bash
   .\quick_start.bat
   ```
   
   Or manually:
   ```bash
   mkdir build
   cd build
   cmake ..
   cmake --build .
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
├── index.html             # Web interface
└── demo_theorem_ai.py     # Python demo script
```

## 🧪 Example Code

Try running the example from the demo:
```lean
-- Binary Search Tree Example
inductive Tree (β : Type v) where
  | leaf
  | node (left : Tree β) (key : Nat) (value : β) (right : Tree β)
  
def Tree.contains (t : Tree β) (k : Nat) : Bool :=
  match t with
  | leaf => false
  | node left key value right =>
    if k < key then
      left.contains k
    else if key < k then
      right.contains k
    else
      true
```

## 🔍 2nd Trial - Alternative Approach

If you encounter issues with the build process, try these alternatives:

1. **Use the Web Interface**:
   - Open `index.html` in your browser for a no-build experience
   - All core functionalities are available through the web interface

2. **Run the Python Demo**:
   ```bash
   python demo_theorem_ai.py
   ```
   This provides a comprehensive overview of Theorem AI's capabilities

3. **Check the `examples/` Directory**:
   - Contains ready-to-run example files
   - No compilation needed - just explore the code

## ⚠️ Troubleshooting

### Common Issues

- **Build Fails with 'stage0' Error**:
  - This is a known issue with the bootstrapping process
  - Use the web interface or Python demo as an alternative
  - Or try running `quick_start.bat` for Windows

- **Python Demo Not Working**:
  - Ensure Python 3.8+ is installed
  - Run `python --version` to check
  - Install required packages: `pip install -r requirements.txt`

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
