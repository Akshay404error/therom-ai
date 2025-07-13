# 📖 Theorem AI Reference

This is the complete reference guide for the Theorem AI language and system.

## 📚 Quick Links

- **[Quick Start Guide](quick-start.md)** - Get up and running
- **[Tutorial](tutorial.md)** - Learn theorem proving and programming
- **[Language Reference](#language-reference)** - Complete syntax and semantics
- **[Standard Library](#standard-library)** - Built-in functions and types
- **[Tactics Reference](#tactics-reference)** - Proof construction tactics

## 🔗 Language Reference

### Basic Syntax

```theorem_ai
-- Comments
-- Single line comment

/- 
  Multi-line comment
-/

-- Definitions
def name : Type := value

-- Functions
def functionName (param : Type) : ReturnType := body

-- Theorems
theorem theoremName (param : Type) : statement := by
  proof

-- Inductive types
inductive TypeName where
  | constructor1
  | constructor2 (param : Type)
```

### Types

```theorem_ai
-- Basic types
Nat          -- Natural numbers (0, 1, 2, ...)
Int          -- Integers
Float        -- Floating point numbers
String       -- Strings
Bool         -- Booleans (true, false)
Unit         -- Unit type (single value)

-- Function types
α → β        -- Function from α to β
α → β → γ    -- Curried function

-- Dependent types
Π x : α, β   -- Dependent function type
Σ x : α, β   -- Dependent pair type

-- Type universes
Type         -- Type of types
Prop         -- Type of propositions
```

### Expressions

```theorem_ai
-- Variables
x            -- Variable
f x          -- Function application
f x y        -- Multiple arguments

-- Lambda expressions
fun x => body
fun (x : Type) => body

-- Pattern matching
match expr with
| pattern1 => result1
| pattern2 => result2

-- Let expressions
let x := value in body

-- If expressions
if condition then value1 else value2
```

### Tactics

```theorem_ai
-- Basic tactics
simp                    -- Simplification
rw [theorem]           -- Rewriting
exact proof            -- Exact proof
apply theorem          -- Apply theorem
induction variable     -- Mathematical induction
cases variable         -- Case analysis
contradiction          -- Prove false from contradiction
ring                   -- Solve arithmetic
```

## 📚 Standard Library

### Core Types

- **Nat** - Natural numbers with arithmetic operations
- **List** - Linked lists with standard operations
- **Option** - Optional values (some/none)
- **Either** - Union types (left/right)
- **Tuple** - Product types
- **Vector** - Fixed-length vectors

### Core Functions

```theorem_ai
-- List operations
List.map f xs          -- Apply function to each element
List.filter p xs       -- Filter elements by predicate
List.foldl f init xs   -- Left fold
List.foldr f init xs   -- Right fold
List.length xs         -- Length of list
List.append xs ys      -- Concatenate lists

-- String operations
String.length s        -- String length
String.append s1 s2    -- String concatenation
String.toList s        -- Convert to character list

-- Arithmetic
Nat.add a b            -- Addition
Nat.mul a b            -- Multiplication
Nat.sub a b            -- Subtraction
Nat.div a b            -- Division
Nat.mod a b            -- Modulo
```

## 🎯 Tactics Reference

### Simplification Tactics

```theorem_ai
simp                    -- Basic simplification
simp [theorem1, theorem2]  -- Simplify with specific theorems
simp only [theorem]     -- Only use specified theorem
simp at h               -- Simplify in hypothesis h
```

### Rewriting Tactics

```theorem_ai
rw [theorem]            -- Rewrite using theorem
rw [← theorem]          -- Rewrite in reverse direction
rw [theorem] at h       -- Rewrite in hypothesis h
```

### Proof Construction

```theorem_ai
exact proof             -- Provide exact proof
apply theorem           -- Apply theorem to goal
intro x                 -- Introduce variable x
exists x                -- Provide witness x for existential
left                    -- Choose left disjunct
right                   -- Choose right disjunct
```

### Induction and Cases

```theorem_ai
induction n with        -- Mathematical induction
| zero => tactic1
| succ n ih => tactic2

cases b with            -- Case analysis
| true => tactic1
| false => tactic2
```

## 🔧 Compiler Options

```bash
# Basic usage
theorem-ai file.theorem_ai

# Interactive mode
theorem-ai --interactive

# Show help
theorem-ai --help

# Verbose output
theorem-ai --verbose file.theorem_ai

# Type check only
theorem-ai --type-check file.theorem_ai
```

## 📦 Package Management (Lake)

```bash
# Initialize new project
lake new project-name

# Build project
lake build

# Run tests
lake test

# Add dependency
lake add package-name

# Update dependencies
lake update

# Clean build artifacts
lake clean
```

## 🛠️ IDE Integration

### VS Code
- Install "Theorem AI" extension
- Automatic syntax highlighting
- Interactive theorem proving
- Code completion and navigation

### Emacs
- Install `lean4-mode`
- Interactive proof assistant
- Syntax highlighting
- REPL integration

### Vim/Neovim
- Install `lean.nvim`
- Language server support
- Syntax highlighting
- Interactive features

## 🔍 Debugging

### Common Error Messages

```theorem_ai
-- Type mismatch
-- Expected: Nat, Got: String

-- Unresolved identifier
-- Unknown identifier 'functionName'

-- Type class resolution failed
-- Failed to synthesize instance for 'TypeClass α'

-- Termination check failed
-- Function may not terminate
```

### Debugging Techniques

```theorem_ai
-- Print debugging
#eval expression

-- Type checking
#check expression

-- Print definition
#print definitionName

-- Print theorems
#print theoremName

-- Show goals
#show
```

## 📖 Further Reading

- **Type Theory**: Martin-Löf Type Theory
- **Functional Programming**: Haskell, OCaml, F#
- **Theorem Proving**: Coq, Agda, Isabelle
- **Category Theory**: Basic concepts for advanced features

## 🆘 Getting Help

- **Documentation**: Check the [docs](docs/) directory
- **Community**: Join our [Discord server](https://discord.gg/UQYSkach)
- **Issues**: Report bugs on [GitHub](https://github.com/Akshay404error/therom-ai/issues)
- **Contact**: Email us at akshay2005air@gmail.com

---

**Need more details?** Check out the [Tutorial](tutorial.md) for hands-on examples! 