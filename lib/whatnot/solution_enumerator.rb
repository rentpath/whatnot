class SolutionEnumerator
  include Enumerable

  def initialize(solution_interpreter, dimacs="")
    @dimacs = dimacs
    @solution_interpreter = solution_interpreter
  end

  def next_solution
    infile   = "/tmp/SolutionEnumerator-in.txt"
    outfile  = "/tmp/SolutionEnumerator-out.txt"

    File.open(infile, "w+") do |file|
      file << @dimacs
    end

    `minisat -rnd-init -rnd-seed=#{Time.now.to_i} #{infile} #{outfile} 2>&1 >/dev/null`

    File.read(outfile)
  end

  def each
    solution = next_solution()

    while solution.start_with?("SAT") do
      clean_up_solution!(solution)

      yield @solution_interpreter.call(solution)

      @dimacs += ("\n" + inverse_of(solution))

      solution = next_solution()
    end
  end

  private

  def clean_up_solution!(solution_string)
    solution_string.gsub!(/\A(UN)?SAT\s/, "")
    solution_string.gsub!(/\n\Z/, "")
  end

  def inverse_of(solution_string)
    solution_string.
      split(" ").
      map { |num| (num.to_i * -1).to_s }.
      join(" ")
  end
end
