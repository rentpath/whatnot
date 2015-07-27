# Whatnot

Whatnot is a Ruby wrapper for the Minisat CSP solver with flexible constraint definition syntax.

### Motivation

I looked at the existing tools for constraint-solving in Ruby and found that they were either: (a) too slow to handle highly complex systems of constraints, or (b) too inflexible to support all but the most well-known types of problems. So I wanted to provide a tool that was both flexible and fast.

### Concepts

To define a constraint problem, you can create two types of variables:

1. A *slot*: a variable that can only hold one value in an array of possible values.
2. A *set*: a variable that can hold one or more of an array of values.

Then you may specify any number of *constraints* between any number of variables.

### Syntax

#### Initializing

First, you have to include the library and create a SwitchInterpreter:

```ruby
include Whatnot

i = SwitchInterpreter.new
```

#### Creating variables

To create a slot called `:B` which can either hold `1` or `2`:

```ruby
i.create_slot(:B, [1,2])
```

To create a set called `:C` which can hold up to 3 values between 1 and 6:

```ruby
i.create_set(:C, [1,2,3,4,5,6], max_values: 3)
```

#### Solving

To solve the system:

```ruby
solution = SolutionEnumerator.new(i.method(:interpret), i.dimacs).first
```

See the Sudoku test in `switch_interpreter_spec.rb` for a more thorough usage example.

#### Creating constraints

To create a constraint that all values of C should be greater than B:

```ruby
i.create_constraint(:C, :B) { |**sol| sol[:C].all? { |c| c > sol[:B] } }
```

### Installing

Minisat must be installed. On a Mac:

```bash
$ brew install gcc
$ brew install minisat
```

