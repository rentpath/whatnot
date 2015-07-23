require 'spec_helper'

module Whatnot
  describe SwitchGroup do
    describe "dimacs" do
      let(:min_one_max_one_dimacs) do
        %(1 2 3 0
          -1 -2 0
          -1 -3 0
          -2 -3 0).lines.map(&:strip).join("\n") + "\n"
      end

      let(:min_two_max_two_dimacs) do
        %(1 2 0
          1 3 0
          2 3 0
          -1 -2 -3 0).lines.map(&:strip).join("\n") + "\n"
      end

      let(:min_zero_max_two_dimacs) do
        %(-1 -2 -3 0).lines.map(&:strip).join("\n") + "\n"
      end

      let(:min_one_max_two_dimacs) do
        %(1 2 3 0
          -1 -2 -3 0).lines.map(&:strip).join("\n") + "\n"
      end

      before do
        Switch.class_variable_set(:"@@all", {})
        Switch.class_variable_set(:"@@next_number", 1)
        Switch.new({foo: 1})
        Switch.new({foo: 2})
        Switch.new({foo: 3})
      end

      context "simplest" do
        it "produces correct clauses" do

          group = SwitchGroup.new { true }
          expect(group.dimacs).to include(min_one_max_one_dimacs)
        end
      end

      context "min_on: 2, max_on: 2" do
        it "produces correct clauses" do
          group = SwitchGroup.new(min_on: 2, max_on: 2) { true }
          expect(group.dimacs).to include(min_two_max_two_dimacs)
        end
      end

      context "min_on: 0, max_on: 2" do
        it "produces correct clauses" do
          group = SwitchGroup.new(min_on: 0, max_on: 2) { true }
          expect(group.dimacs).to include(min_zero_max_two_dimacs)
        end
      end

      context "min_on: 1, max_on: 2" do
        it "produces correct clauses" do
          group = SwitchGroup.new(max_on: 2) { true }
          expect(group.dimacs).to include(min_one_max_two_dimacs)
        end
      end
    end
  end
end
