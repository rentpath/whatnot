require 'spec_helper'

def print_sudoku(solution)
  puts "+-------+-------+-------+"
  ("A".."C").to_a.each do |letter|
    print "| "
    print solution.fetch(:"#{letter}1", " ").to_s + " "
    print solution.fetch(:"#{letter}2", " ").to_s + " "
    print solution.fetch(:"#{letter}3", " ").to_s
    print " | "
    print solution.fetch(:"#{letter}4", " ").to_s + " "
    print solution.fetch(:"#{letter}5", " ").to_s + " "
    print solution.fetch(:"#{letter}6", " ").to_s
    print " | "
    print solution.fetch(:"#{letter}7", " ").to_s + " "
    print solution.fetch(:"#{letter}8", " ").to_s + " "
    print solution.fetch(:"#{letter}9", " ").to_s
    print " |\n"
  end
  puts "+-------+-------+-------+"
  ("D".."F").to_a.each do |letter|
    print "| "
    print solution.fetch(:"#{letter}1", " ").to_s + " "
    print solution.fetch(:"#{letter}2", " ").to_s + " "
    print solution.fetch(:"#{letter}3", " ").to_s
    print " | "
    print solution.fetch(:"#{letter}4", " ").to_s + " "
    print solution.fetch(:"#{letter}5", " ").to_s + " "
    print solution.fetch(:"#{letter}6", " ").to_s
    print " | "
    print solution.fetch(:"#{letter}7", " ").to_s + " "
    print solution.fetch(:"#{letter}8", " ").to_s + " "
    print solution.fetch(:"#{letter}9", " ").to_s
    print " |\n"
  end
  puts "+-------+-------+-------+"
  ("G".."I").to_a.each do |letter|
    print "| "
    print solution.fetch(:"#{letter}1", " ").to_s + " "
    print solution.fetch(:"#{letter}2", " ").to_s + " "
    print solution.fetch(:"#{letter}3", " ").to_s
    print " | "
    print solution.fetch(:"#{letter}4", " ").to_s + " "
    print solution.fetch(:"#{letter}5", " ").to_s + " "
    print solution.fetch(:"#{letter}6", " ").to_s
    print " | "
    print solution.fetch(:"#{letter}7", " ").to_s + " "
    print solution.fetch(:"#{letter}8", " ").to_s + " "
    print solution.fetch(:"#{letter}9", " ").to_s
    print " |\n"
  end
  puts "+-------+-------+-------+"
end

module Whatnot
  describe SwitchInterpreter do
    describe "full usage" do
      context "simplest with set, slot, & constraint" do
        let(:expected) do
          [{:B=>2}, {:B=>1}, {:A=>[3], :B=>1}, {:A=>[5], :B=>1}, {:A=>[4], :B=>1}, {:A=>[3, 4], :B=>1}, {:A=>[4, 5], :B=>1}, {:A=>[3, 5], :B=>1}]
        end

        it "works" do
          i = SwitchInterpreter.new
          i.create_set(:A, [3,4,5], allow_empty: true, max_values: 2)
          i.create_slot(:B, [1,2], allow_empty: false)
          i.create_constraint(:A, :B) do |**sol| sol[:A].nil? || sol[:B] == 1; end

          solutions = SolutionEnumerator.new(i.method(:interpret), i.dimacs).entries
          expect(solutions).to eq(expected)
        end
      end

      context "mutually exclusive slots" do
        let(:expected) do
          [{},
           {:B=>5},
           {:B=>3},
           {:B=>4},
           {:A=>3},
           {:A=>5},
           {:A=>5, :B=>3},
           {:A=>4},
           {:A=>5, :B=>4},
           {:A=>4, :B=>5},
           {:A=>3, :B=>4},
           {:A=>3, :B=>5},
           {:A=>4, :B=>3}]
        end

        it "works" do
          i = SwitchInterpreter.new
          i.create_mutually_exclusive_slots([:A, :B], [3,4,5], allow_empty: true)

          solutions = SolutionEnumerator.new(i.method(:interpret), i.dimacs).entries
          expect(solutions).to eq(expected)
        end
      end

      context "mutually exclusive sets" do
        let(:expected) do
          [{:B=>[3, 4, 5]},
           {:A=>[3], :B=>[4, 5]},
           {:A=>[4], :B=>[3, 5]},
           {:A=>[3, 4, 5]},
           {:A=>[5], :B=>[3, 4]},
           {:A=>[3, 4], :B=>[5]},
           {:A=>[3, 5], :B=>[4]},
           {:A=>[4, 5], :B=>[3]}]
        end

        it "works" do
          i = SwitchInterpreter.new
          i.create_mutually_exclusive_sets([:A, :B], [3,4,5], allow_empty: true, max_values: 3)

          solutions = SolutionEnumerator.new(i.method(:interpret), i.dimacs).entries
          expect(solutions).to eq(expected)
        end
      end
    end

    describe "sudoku" do
      it "works" do
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

        solution = i.enumerator.first

        print_sudoku(solution)

        puts
      end
    end
  end
end
