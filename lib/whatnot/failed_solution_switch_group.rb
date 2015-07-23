# a simple object that represents a failed constraint. acts as SwitchGroup.
class FailedSolutionSwitchGroup
  attr_accessor :failed_solutions

  def initialize(failed_solution_dimacs_strings)
    @failed_solutions = failed_solution_dimacs_strings
  end

  def dimacs
    @failed_solutions.map { |str| inverse_of(str) }.join
  end

  def switches
    []
  end

  private

  def inverse_of(solution_string)
    solution_string.
      split(" ").
      map { |num| (num.to_i * -1).to_s }.
      join(" ") + "\n"
  end
end
