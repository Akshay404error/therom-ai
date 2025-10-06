# Theorem AI - Sample Demo

This guide will walk you through running a sample demo of Theorem AI, showcasing its theorem proving and functional programming capabilities.

## Prerequisites

- Python 3.8 or later
- Web browser (Chrome, Firefox, or Edge recommended)

## Running the Demo

### Method 1: Python Demo Script

1. Open a terminal/command prompt
2. Navigate to the project directory
3. Run the demo script:
   ```bash
   python demo_theorem_ai.py
   ```

### Method 2: Web Interface

1. Open `index.html` in your web browser
2. The interactive interface will load automatically

## Example: Working with Binary Search Trees

Here's a sample code snippet demonstrating Theorem AI's capabilities with binary search trees:

```lean
-- Define a binary tree data structure
inductive Tree (β : Type v) where
  | leaf
  | node (left : Tree β) (key : Nat) (value : β) (right : Tree β)

-- Function to check if a key exists in the tree
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

-- Insert a key-value pair into the tree
def Tree.insert (t : Tree β) (k : Nat) (v : β) : Tree β :=
  match t with
  | leaf => Tree.node leaf k v leaf
  | node left key value right =>
    if k < key then
      Tree.node (left.insert k v) key value right
    else if key < k then
      Tree.node left key value (right.insert k v)
    else
      Tree.node left k v right

-- Example usage
#eval Tree.leaf
  |>.insert 2 "two"
  |>.insert 3 "three"
  |>.insert 1 "one"
  |>.contains 2  -- Returns: true
```

## Expected Output

When you run the example, you should see output similar to:

```
📁 Project Structure:
├── src/                    # Source code
│   ├── TheoremAI/          # Core Theorem AI library
│   ├── Init/               # Initialization modules
│   ├── Std/                # Standard library
│   └── lake/               # Build system
├── tests/                  # Test suite
├── doc/                    # Documentation
└── examples/               # Example code

🚀 Key Features:
• Advanced theorem proving capabilities
• Functional programming language
• Interactive proof assistant
• Type-safe programming
• Mathematical reasoning
• Code generation

💻 Example Output:
Tree.node (Tree.node leaf 1 "one" leaf) 2 "two" (Tree.node leaf 3 "three" leaf)
true
```

## Next Steps

1. Try modifying the example code to add more nodes to the tree
2. Experiment with different operations like searching for values
3. Explore the `examples/` directory for more complex examples
4. Check the documentation in the `docs/` folder for more information

## Troubleshooting

If you encounter any issues:
1. Ensure you have Python 3.8 or later installed
2. Make sure you're in the correct directory when running the demo
3. Check the browser's console for any error messages when using the web interface
4. Refer to the `README.md` for additional setup instructions
