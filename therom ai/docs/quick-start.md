# 🚀 Theorem AI Quick Start Guide

Welcome to Theorem AI! This guide will help you get up and running in minutes.

## 📋 Prerequisites

Before you begin, make sure you have the following installed:

- **Windows 10/11** or **macOS 10.15+** or **Linux (Ubuntu 18.04+)**
- **Git** (for cloning the repository)
- **CMake 3.11+** (build system)
- **C++ Compiler** (GCC 8+, Clang 8+, or MSVC 2019+)
- **Python 3.7+** (for build scripts)

## 🔧 Installation

### Option 1: Build from Source (Recommended)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/theorem-ai.git
   cd theorem-ai
   ```

2. **Run the quick start script:**
   
   **Windows:**
   ```cmd
   quick_start.bat
   ```
   
   **Linux/macOS:**
   ```bash
   chmod +x quick_start.sh
   ./quick_start.sh
   ```

3. **Manual build (if needed):**
   ```bash
   mkdir build
   cd build
   cmake ..
   make -j$(nproc)  # or make -j4 on Windows
   ```

### Option 2: Using Nix (Advanced Users)

If you have Nix installed:

```bash
nix develop
lake build
```

## ✅ Verification

After installation, verify that Theorem AI is working:

```bash
theorem-ai --version
```

You should see output like:
```
Theorem AI version 4.0.0
```

## 🎯 Your First Theorem AI Program

Create a file called `hello.theorem_ai`:

```theorem_ai
-- Hello World in Theorem AI
def hello : String := "Hello, Theorem AI!"

-- Define a simple mathematical function
def factorial (n : Nat) : Nat :=
  match n with
  | 0 => 1
  | n + 1 => (n + 1) * factorial n

-- Evaluate and display results
#eval hello
#eval factorial 5
```

Run your program:

```bash
theorem-ai hello.theorem_ai
```

Expected output:
```
"Hello, Theorem AI!"
120
```

## 🔍 Interactive Mode

Start the interactive REPL:

```bash
theorem-ai --interactive
```

In the REPL, you can:
- Type expressions and see results
- Define functions and theorems
- Use tactics for proof construction
- Get help with `:help`

Example session:
```theorem_ai
Theorem AI> def greet (name : String) : String := s!"Hello, {name}!"
Theorem AI> #eval greet "World"
"Hello, World!"
Theorem AI> :quit
```

## 📦 Using Lake (Package Manager)

Lake is Theorem AI's built-in package manager:

```bash
# Initialize a new project
lake new my-project

# Build the project
lake build

# Run tests
lake test

# Add dependencies
lake add mathlib
```

## 🛠️ IDE Setup

### VS Code (Recommended)

1. Install the "Theorem AI" extension
2. Open your project folder
3. The extension will automatically detect Theorem AI files

### Other Editors

- **Emacs**: Install `lean4-mode`
- **Vim/Neovim**: Install `lean.nvim`
- **JetBrains IDEs**: Install the Theorem AI plugin

## 🎓 Next Steps

Now that you have Theorem AI installed, try:

1. **Complete the Tutorial** - Learn theorem proving basics
2. **Read the Reference** - Understand the language in detail
3. **Explore Examples** - Check out the `examples/` directory
4. **Join the Community** - Connect with other users

## 🆘 Getting Help

- **Documentation**: Check the Tutorial and Reference guides
- **Examples**: Browse the `examples/` directory
- **Community**: Join our Discord server
- **Issues**: Report bugs on GitHub

## 🔧 Troubleshooting

### Common Issues

**"theorem-ai: command not found"**
- Make sure the build completed successfully
- Add the build directory to your PATH
- Try running `lake build` again

**Build errors**
- Ensure you have the correct CMake version
- Check that your C++ compiler supports C++17
- Try cleaning and rebuilding: `lake clean && lake build`

**IDE not working**
- Restart your IDE after installation
- Check that the Theorem AI extension is installed
- Verify the language server is running

### System-Specific Notes

**Windows:**
- Use PowerShell or Command Prompt
- Install Visual Studio Build Tools if needed
- Use `make` from MinGW or WSL

**macOS:**
- Install Xcode Command Line Tools
- Use Homebrew for dependencies: `brew install cmake`

**Linux:**
- Install build essentials: `sudo apt-get install build-essential`
- Use `make -j$(nproc)` for parallel builds

## 🎉 Congratulations!

You've successfully installed Theorem AI and run your first program! You're now ready to explore the world of theorem proving and functional programming.

---

**Ready to dive deeper?** Check out the [Tutorial](tutorial.md) to learn theorem proving basics! 