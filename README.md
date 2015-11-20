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

#### Creating constraints

To create a constraint that all values of C should be greater than B:

```ruby
i.create_constraint(:C, :B) { |**sol| sol[:C].all? { |c| c > sol[:B] } }
```

#### Solving

To solve the system:

```ruby
solution = SolutionEnumerator.new(i.method(:interpret), i.dimacs).first
```

### Usage

Below is a thorough usage example for solving a Sudoku problem.

```ruby
puts "\nSudoku: "

puzzle = {
  :A1 => 8,
  :C2 => 3,
  :D2 => 6,
  :B3 => 7,
  :E3 => 9,
  :G3 => 2,
  :B4 => 5,
  :F4 => 7,
  :E5 => 4,
  :F5 => 5,
  :G5 => 7,
  :D6 => 1,
  :H6 => 3,
  :C7 => 1,
  :H7 => 6,
  :I7 => 8,
  :C8 => 8,
  :D8 => 5,
  :H8 => 1,
  :B9 => 9,
  :G9 => 4
}

print_sudoku(puzzle)

i = SwitchInterpreter.new

("A".."I").to_a.each do |letter|
  slotnames = ('1'..'9').map { |n| :"#{letter}#{n}" }
  i.create_mutually_exclusive_slots(slotnames, [1,2,3,4,5,6,7,8,9], allow_empty: false)
end

(1..9).to_a.each do |slotnum|
  slots_for_column = ("A".."I").to_a.map { |letter| :"#{letter}#{slotnum}" }

  slots_for_column.combination(2) do |slot1, slot2|
    i.create_constraint(slot1, slot2) do |**solution|
      solution[slot1] != solution[slot2]
    end
  end
end

("A".."I").to_a.map(&:to_sym).each do |slotletter|
  slots_for_row = ('1'..'9').to_a.map { |num| :"#{slotletter}#{num}" }

  slots_for_row.combination(2) do |slot1, slot2|
    i.create_constraint(slot1, slot2) do |**solution|
      solution[slot1] != solution[slot2]
    end
  end
end

squares = [
  ["A1","A2","A3","B1","B2","B3","C1","C2","C3"],
  ["A4","A5","A6","B4","B5","B6","C4","C5","C6"],
  ["A7","A8","A9","B7","B8","B9","C7","C8","C9"],
  ["D1","D2","D3","E1","E2","E3","F1","F2","F3"],
  ["D4","D5","D6","E4","E5","E6","F4","F5","F6"],
  ["D7","D8","D9","E7","E8","E9","F7","F8","F9"],
  ["G1","G2","G3","H1","H2","H3","I1","I2","I3"],
  ["G4","G5","G6","H4","H5","H6","I4","I5","I6"],
  ["G7","G8","G9","H7","H8","H9","I7","I8","I9"]
]

squares.each do |square|
  slots_for_square = square.map(&:to_sym)

  slots_for_square.combination(2) do |slot1, slot2|
    i.create_constraint(slot1, slot2) do |**solution|
      solution[slot1] != solution[slot2]
    end
  end
end

puzzle.each do |slot, val|
  i.create_constraint(slot) { |**sol| sol[slot] == val }
end

solution = SolutionEnumerator.new(i.method(:interpret), i.dimacs).first

print_sudoku(solution)
```

Below is the output:

```
Sudoku:
+-------+-------+-------+
| 8     |       |       |
|     7 | 5     |     9 |
|   3   |       | 1 8   |
+-------+-------+-------+
|   6   |     1 |   5   |
|     9 |   4   |       |
|       | 7 5   |       |
+-------+-------+-------+
|     2 |   7   |     4 |
|       |     3 | 6 1   |
|       |       | 8     |
+-------+-------+-------+
+-------+-------+-------+
| 8 9 6 | 1 3 2 | 5 4 7 |
| 1 4 7 | 5 6 8 | 2 3 9 |
| 2 3 5 | 4 9 7 | 1 8 6 |
+-------+-------+-------+
| 7 6 4 | 2 8 1 | 9 5 3 |
| 5 8 9 | 3 4 6 | 7 2 1 |
| 3 2 1 | 7 5 9 | 4 6 8 |
+-------+-------+-------+
| 6 1 2 | 8 7 5 | 3 9 4 |
| 4 7 8 | 9 2 3 | 6 1 5 |
| 9 5 3 | 6 1 4 | 8 7 2 |
+-------+-------+-------+
```

This is found in switch_interpreter_spec.rb.

### Installing

Minisat must be installed. On a Mac:

```bash
$ brew install gcc
$ brew install minisat
```

