require 'spec_helper'

module Whatnot
  describe SolutionEnumerator do
    def noop(str); str end

    describe "#each" do
      context "simplest" do
        let(:dimacs) do
          %(
          c Test DIMACS 1
          c -------------
          p cnf 2 2
          1 -2 0
          -1 2 0
          )
        end

        let(:interpreter) { method(:noop) }

        it "finds all solutions" do
          enum = SolutionEnumerator.new(interpreter, dimacs)

          expect(enum.entries).to eq(["-1 -2 0", "1 2 0"])
        end
      end

      context "with SwitchGroup" do
        before do
          Switch.class_variable_set(:"@@all", {})
          Switch.class_variable_set(:"@@next_number", 1)
          Switch.new({foo: 1})
          Switch.new({foo: 2})
          Switch.new({foo: 3})
        end

        let(:interpreter) { method(:noop) }

        it "finds all solutions" do
          group = SwitchGroup.new(max_on: 2) { true }
          enum = SolutionEnumerator.new(interpreter, group.dimacs)
          expect(enum.entries).to eq(["-1 -2 3 0", "1 -2 -3 0", "-1 2 -3 0", "1 2 -3 0", "-1 2 3 0", "1 -2 3 0"])
        end
      end
    end
  end
end
