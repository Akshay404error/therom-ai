# 📚 Theorem AI Tutorial

Welcome to the Theorem AI tutorial! This guide will teach you the fundamentals of theorem proving and functional programming using Theorem AI.

## 🎯 What You'll Learn

- Basic functional programming concepts
- Type theory and dependent types
- Theorem proving with tactics
- Pattern matching and recursion
- Mathematical reasoning
- Interactive proof construction

## 📖 Table of Contents

1. [Basic Concepts](#basic-concepts)
2. [Functions and Types](#functions-and-types)
3. [Pattern Matching](#pattern-matching)
4. [Inductive Types](#inductive-types)
5. [Theorems and Proofs](#theorems-and-proofs)
6. [Tactics](#tactics)
7. [Advanced Features](#advanced-features)

---

## 1. Basic Concepts

### What is Theorem AI?

Theorem AI is a functional programming language with a powerful type system that allows you to:
- Write programs with mathematical precision
- Prove properties about your code
- Ensure correctness at compile time
- Express complex mathematical concepts

### Your First Program

```theorem_ai
-- This is a comment
def hello : String := "Hello, Theorem AI!"

-- Evaluate the expression
#eval hello
```

**Key concepts:**
- `def` declares a definition
- `: String` specifies the type
- `:=` assigns a value
- `#eval` evaluates an expression

### Basic Types

```theorem_ai
-- Natural numbers (0, 1, 2, ...)
def myNumber : Nat := 42

-- Strings
def myString : String := "Hello"

-- Booleans
def myBool : Bool := true

-- Lists
def myList : List Nat := [1, 2, 3, 4, 5]

-- Functions
def addOne (x : Nat) : Nat := x + 1
```

---

## 2. Functions and Types

### Function Definitions

```theorem_ai
-- Simple function
def square (x : Nat) : Nat := x * x

-- Function with multiple parameters
def add (x y : Nat) : Nat := x + y

-- Function with type inference
def multiply x y := x * y

-- Higher-order function
def applyTwice (f : Nat → Nat) (x : Nat) : Nat := f (f x)

-- Example usage
#eval square 5        -- 25
#eval add 3 4         -- 7
#eval applyTwice square 2  -- 16
```

### Type Annotations

```theorem_ai
-- Explicit type annotations
def explicit : Nat := 42

-- Type inference (Theorem AI can figure out the type)
def inferred := 42

-- Function types
def functionType : Nat → Nat := fun x => x + 1

-- Dependent function types
def dependent (n : Nat) : Vector Nat n := -- implementation here
```

### Lambda Expressions

```theorem_ai
-- Lambda function
def lambda := fun (x : Nat) => x * x

-- Lambda with multiple parameters
def addLambda := fun (x y : Nat) => x + y

-- Lambda in higher-order functions
def map (f : Nat → Nat) (xs : List Nat) : List Nat :=
  match xs with
  | [] => []
  | x :: xs => f x :: map f xs

-- Usage
#eval map (fun x => x * 2) [1, 2, 3]  -- [2, 4, 6]
```

---

## 3. Pattern Matching

### Basic Pattern Matching

```theorem_ai
def describeNumber (n : Nat) : String :=
  match n with
  | 0 => "Zero"
  | 1 => "One"
  | 2 => "Two"
  | _ => "Many"

-- Pattern matching on lists
def listLength (xs : List α) : Nat :=
  match xs with
  | [] => 0
  | _ :: xs => 1 + listLength xs

-- Pattern matching on tuples
def swap (p : α × β) : β × α :=
  match p with
  | (x, y) => (y, x)
```

### Pattern Matching with Guards

```theorem_ai
def absolute (x : Int) : Nat :=
  match x with
  | Int.ofNat n => n
  | Int.negSucc n => n + 1

-- Pattern matching with conditions
def classify (n : Nat) : String :=
  match n with
  | 0 => "Zero"
  | n + 1 => 
    if n < 10 then "Small"
    else if n < 100 then "Medium"
    else "Large"
```

---

## 4. Inductive Types

### Defining Your Own Types

```theorem_ai
-- Simple inductive type
inductive Color where
  | red
  | green
  | blue

-- Inductive type with parameters
inductive Option (α : Type) where
  | none
  | some (val : α)

-- Recursive inductive type
inductive Tree (α : Type) where
  | leaf
  | node (left : Tree α) (value : α) (right : Tree α)

-- Inductive type with constructors
inductive Shape where
  | circle (radius : Float)
  | rectangle (width height : Float)
  | triangle (a b c : Float)
```

### Working with Inductive Types

```theorem_ai
-- Pattern matching on custom types
def colorToString (c : Color) : String :=
  match c with
  | Color.red => "Red"
  | Color.green => "Green"
  | Color.blue => "Blue"

-- Functions on trees
def treeSize (t : Tree α) : Nat :=
  match t with
  | Tree.leaf => 0
  | Tree.node left _ right => 1 + treeSize left + treeSize right

-- Option handling
def safeDivide (x y : Nat) : Option Nat :=
  if y = 0 then Option.none
  else Option.some (x / y)
```

---

## 5. Theorems and Proofs

### Your First Theorem

```theorem_ai
-- A simple theorem
theorem add_zero (n : Nat) : n + 0 = n := by
  simp

-- Theorem with multiple hypotheses
theorem add_comm (a b : Nat) : a + b = b + a := by
  induction b with
  | zero => simp
  | succ b ih => 
    simp [Nat.add_succ]
    rw [ih]
```

### Understanding Proofs

```theorem_ai
-- Theorem: For any natural number n, n + 0 = n
theorem add_zero_right (n : Nat) : n + 0 = n := by
  -- The 'by' keyword starts a proof
  -- 'simp' is a tactic that simplifies the goal
  simp

-- Theorem: Addition is commutative
theorem add_commutative (a b : Nat) : a + b = b + a := by
  -- Use induction on b
  induction b with
  | zero => 
    -- Base case: a + 0 = 0 + a
    simp
  | succ b ih => 
    -- Inductive case: a + (b + 1) = (b + 1) + a
    simp [Nat.add_succ]
    rw [ih]  -- Use the inductive hypothesis
```

### Proof by Induction

```theorem_ai
-- Prove that sum of first n natural numbers is n*(n+1)/2
theorem sum_formula (n : Nat) : 
  sum (List.range n) = n * (n - 1) / 2 := by
  induction n with
  | zero => 
    simp [List.range, sum]
  | succ n ih => 
    simp [List.range, sum]
    rw [ih]
    ring  -- Solve arithmetic
```

---

## 6. Tactics

### Basic Tactics

```theorem_ai
-- simp: Simplifies expressions
theorem example1 (n : Nat) : n + 0 = n := by
  simp

-- rw: Rewrites using equalities
theorem example2 (a b : Nat) : a + b = b + a := by
  rw [Nat.add_comm]

-- exact: Provides exact proof
theorem example3 (n : Nat) : n = n := by
  exact rfl

-- apply: Applies a theorem
theorem example4 (a b c : Nat) (h : a = b) (h2 : b = c) : a = c := by
  apply Eq.trans
  exact h
  exact h2
```

### Advanced Tactics

```theorem_ai
-- induction: Mathematical induction
theorem example5 (n : Nat) : n + 0 = n := by
  induction n with
  | zero => simp
  | succ n ih => 
    simp
    exact ih

-- cases: Case analysis
theorem example6 (b : Bool) : b = true ∨ b = false := by
  cases b with
  | true => left; rfl
  | false => right; rfl

-- contradiction: Proves false from contradiction
theorem example7 (n : Nat) (h : n ≠ n) : False := by
  contradiction

-- ring: Solves arithmetic
theorem example8 (a b : Nat) : (a + b) * (a + b) = a * a + 2 * a * b + b * b := by
  ring
```

---

## 7. Advanced Features

### Type Classes

```theorem_ai
-- Define a type class
class Monoid (α : Type) where
  empty : α
  append : α → α → α
  empty_append : ∀ x, append empty x = x
  append_empty : ∀ x, append x empty = x
  append_assoc : ∀ x y z, append (append x y) z = append x (append y z)

-- Instance for natural numbers
instance : Monoid Nat where
  empty := 0
  append := Nat.add
  empty_append := Nat.zero_add
  append_empty := Nat.add_zero
  append_assoc := Nat.add_assoc
```

### Dependent Types

```theorem_ai
-- Vector with length in type
inductive Vector (α : Type) : Nat → Type where
  | nil : Vector α 0
  | cons : α → Vector α n → Vector α (n + 1)

-- Function that preserves length
def map (f : α → β) : Vector α n → Vector β n :=
  match n with
  | 0 => fun _ => Vector.nil
  | n + 1 => fun xs =>
    match xs with
    | Vector.cons x xs => Vector.cons (f x) (map f xs)
```

### Metaprogramming

```theorem_ai
-- Macro for common patterns
macro "repeat" n:num "times" body:term : term => 
  `(List.replicate $n $body)

-- Usage
#eval repeat 3 times "Hello"  -- ["Hello", "Hello", "Hello"]

-- Custom notation
infix:50 "++" => List.append

-- Usage
#eval [1, 2] ++ [3, 4]  -- [1, 2, 3, 4]
```

---

## 🎓 Practice Exercises

### Exercise 1: Basic Functions
Write a function that doubles a number and adds one.

```theorem_ai
def doublePlusOne (x : Nat) : Nat :=
  -- Your solution here
```

### Exercise 2: List Functions
Write a function that reverses a list.

```theorem_ai
def reverse (xs : List α) : List α :=
  -- Your solution here
```

### Exercise 3: Simple Theorem
Prove that for any natural number n, n * 0 = 0.

```theorem_ai
theorem mul_zero (n : Nat) : n * 0 = 0 := by
  -- Your proof here
```

### Exercise 4: Pattern Matching
Write a function that counts the number of elements in a tree.

```theorem_ai
def countNodes (t : Tree α) : Nat :=
  -- Your solution here
```

---

## 🔍 Solutions

<details>
<summary>Click to see solutions</summary>

### Exercise 1 Solution
```theorem_ai
def doublePlusOne (x : Nat) : Nat :=
  2 * x + 1
```

### Exercise 2 Solution
```theorem_ai
def reverse (xs : List α) : List α :=
  match xs with
  | [] => []
  | x :: xs => reverse xs ++ [x]
```

### Exercise 3 Solution
```theorem_ai
theorem mul_zero (n : Nat) : n * 0 = 0 := by
  induction n with
  | zero => simp
  | succ n ih => 
    simp [Nat.mul_succ]
    exact ih
```

### Exercise 4 Solution
```theorem_ai
def countNodes (t : Tree α) : Nat :=
  match t with
  | Tree.leaf => 0
  | Tree.node left _ right => 1 + countNodes left + countNodes right
```

</details>

---

## 🎉 Congratulations!

You've completed the Theorem AI tutorial! You now understand:

- ✅ Basic functional programming concepts
- ✅ Type theory and dependent types
- ✅ Pattern matching and recursion
- ✅ Theorem proving with tactics
- ✅ Interactive proof construction

## 🚀 Next Steps

1. **Read the Reference Guide** - Deep dive into language features
2. **Explore Examples** - Check out the `examples/` directory
3. **Join the Community** - Connect with other users
4. **Build Your Own Projects** - Apply what you've learned

## 📚 Additional Resources

- **Reference Guide** - Complete language reference
- **Standard Library** - Built-in functions and types
- **Community Examples** - User-contributed code
- **Research Papers** - Theoretical foundations

---

**Ready for more?** Check out the [Reference Guide](reference.md) for complete language documentation! 