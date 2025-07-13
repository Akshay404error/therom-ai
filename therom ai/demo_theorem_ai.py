#!/usr/bin/env python3
"""
Theorem AI Demo Script
This script demonstrates the Theorem AI project for demo purposes.
"""

import os
import subprocess
import sys
from pathlib import Path

def print_banner():
    """Print a nice banner for the demo."""
    print("=" * 60)
    print("           THEOREM AI - DEMO")
    print("=" * 60)
    print("Welcome to Theorem AI - The Next Generation Theorem Prover!")
    print()

def show_project_structure():
    """Show the main project structure."""
    print("📁 Project Structure:")
    print("├── src/                    # Source code")
    print("│   ├── TheoremAI/          # Core Theorem AI library")
    print("│   ├── Init/               # Initialization modules")
    print("│   ├── Std/                # Standard library")
    print("│   └── lake/               # Build system")
    print("├── tests/                  # Test suite")
    print("├── doc/                    # Documentation")
    print("└── examples/               # Example code")
    print()

def show_key_features():
    """Show key features of Theorem AI."""
    print("🚀 Key Features:")
    print("• Advanced theorem proving capabilities")
    print("• Functional programming language")
    print("• Interactive proof assistant")
    print("• Type-safe programming")
    print("• Mathematical reasoning")
    print("• Code generation")
    print()

def show_example_code():
    """Show some example Theorem AI code."""
    print("💻 Example Theorem AI Code:")
    print()
    
    example_code = '''
-- Theorem AI Example: Binary Search Trees
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

-- Create and test a tree
#eval Tree.leaf.insert 2 "two"
      |>.insert 3 "three"
      |>.insert 1 "one"
'''
    
    print(example_code)

def check_theorem_ai_installation():
    """Check if Theorem AI is installed."""
    print("🔍 Checking Theorem AI Installation:")
    try:
        # Try to run theorem-ai --version
        result = subprocess.run(['theorem-ai', '--version'], 
                              capture_output=True, text=True, timeout=5)
        if result.returncode == 0:
            print("✅ Theorem AI is installed!")
            print(f"   Version: {result.stdout.strip()}")
        else:
            print("❌ Theorem AI command not found")
    except (subprocess.TimeoutExpired, FileNotFoundError):
        print("❌ Theorem AI is not installed or not in PATH")
        print("   To install, follow the setup guide in the documentation")
    print()

def show_build_instructions():
    """Show build instructions."""
    print("🔨 Building Theorem AI:")
    print("1. Install dependencies (CMake, C++ compiler)")
    print("2. Run: mkdir -p build/release")
    print("3. Run: cd build/release")
    print("4. Run: cmake ../../src")
    print("5. Run: make -j$(nproc)")
    print()

def show_usage_examples():
    """Show usage examples."""
    print("📖 Usage Examples:")
    print("• theorem-ai --help                    # Show help")
    print("• theorem-ai file.theorem_ai           # Run a file")
    print("• theorem-ai --interactive             # Start REPL")
    print("• lake build                           # Build project")
    print("• lake test                            # Run tests")
    print()

def main():
    """Main demo function."""
    print_banner()
    
    # Show different sections
    show_project_structure()
    show_key_features()
    show_example_code()
    check_theorem_ai_installation()
    show_build_instructions()
    show_usage_examples()
    
    print("=" * 60)
    print("🎉 Demo Complete!")
    print("Theorem AI is ready for mathematical reasoning and theorem proving!")
    print("=" * 60)

if __name__ == "__main__":
    main() 