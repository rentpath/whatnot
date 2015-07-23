class SwitchInterpreter
  class NameCollisionError < ::RuntimeError
    def initialize(info="")
      super("Already using name #{info}")
    end
  end

  attr_accessor :set_groups, :slot_groups, :non_interpreted_groups

  def initialize
    Switch.class_variable_set(:@@all, {})
    Switch.class_variable_set(:@@next_number, 1)
    @slot_groups = {}
    @set_groups  = {}
    @non_interpreted_groups = {}
  end

  def interpreted_groups
    groups = {}
    groups.merge! @slot_groups
    groups.merge! @set_groups
    groups
  end

  def dimacs
    d = "c SwitchInterpreter\np cnf 1 1\n"
    d << "\n"

    interpreted_groups.to_a.each do |key, group|
      d << "c ---------------------------\n"
      d << "c INTERPRETED\n"
      d << "c #{group.class} => \n"
      d << "c   #{key}\n"
      d << "c \n"
      d << group.dimacs
    end

    @non_interpreted_groups.to_a.each do |key, group|
      d << "c ---------------------------\n"
      d << "c NON-INTERPRETED\n"
      d << "c #{group.class} => \n"
      d << "c   #{key}\n"
      d << "c \n"
      d << group.dimacs
    end

    d
  end

  def merge_payload!(for_num: nil, to_hash: nil)
    if for_num.nil? || to_hash.nil?
      raise "left off required kwargs #{"for_num, " unless for_num}#{"to_hash" unless to_hash}" 
    end

    payload = Switch.find(for_num).payload
    payload_key, payload_val = *payload.to_a[0]

    # manage sets vs. slots
    if @set_groups[payload_key]
      payload_val = [payload_val] unless payload_val.is_a?(Array)

      if to_hash[payload_key]
        to_hash[payload_key] += payload_val
      else
        to_hash[payload_key] = payload_val
      end

      return to_hash
    end

    to_hash.merge!(payload)
  end

  def create_slot(slotname, slotvalues, allow_empty: true)
    if interpreted_groups[slotname]
      raise NameCollisionError.new(slotname)
    end

    numbers = []

    [slotname].product(slotvalues).each do |name, value|
      s = Switch.new({name => value})
      numbers << s.number
    end

    min_on = allow_empty ? 0 : 1

    @slot_groups[slotname] = SwitchGroup.new(numbers, min_on: min_on, max_on: 1)
  end

  def create_set(setname, setvalues, allow_empty: true, max_values: 2)
    if interpreted_groups[setname]
      raise NameCollisionError.new(setname)
    end

    numbers = []

    [setname].product(setvalues).each do |name, value|
      s = Switch.new({name => value})
      numbers << s.number
    end

    min_on = allow_empty ? 0 : 1

    @set_groups[setname] = SwitchGroup.new(numbers, min_on: min_on, max_on: max_values)
  end

  def create_mutually_exclusive_slots(slotnames, slotvalues, allow_empty: false)
    begin
      slotnames.each do |slotname|
        create_slot(slotname, slotvalues, allow_empty: allow_empty)
      end
    rescue NameCollisionError
    end

    slotvalues.each do |slotvalue|
      mutual_exclusion = SwitchGroup.new(nil, min_on: 0, max_on: 1) do |payload|
        k, v = *payload.to_a[0]
        slotnames.include?(k) && slotvalue == v
      end

      @non_interpreted_groups[slotvalue] = mutual_exclusion
    end
  end

  def create_mutually_exclusive_sets(slotnames, slotvalues, allow_empty: true, require_complete: true, max_values: 2)
    begin
      slotnames.each do |slotname|
        create_set(slotname, slotvalues, allow_empty: allow_empty, max_values: max_values)
      end
    rescue NameCollisionError
    end

    slotvalues.each do |slotvalue|
      min_on = require_complete ? 1 : 0

      mutual_exclusion = SwitchGroup.new(nil, min_on: min_on, max_on: 1) do |payload|
        k, v = *payload.to_a[0]
        slotnames.include?(k) && slotvalue == v
      end

      @non_interpreted_groups[slotvalue] = mutual_exclusion
    end
  end

  def create_constraint(*slotnames)
    solutions_to_try = nil

    slotnames.each do |groupname|
      group = interpreted_groups[groupname]

      if group.nil?
        group = @non_interpreted_groups[groupname]
      end

      raise "can't find group #{groupname}" if group.nil?

      # get possible solutions for each group
      group_solutions = group.possibilities

      merge_possibilities = -> (p1, p2) do
        Hash[p1.to_a.product(p2.to_a).map { |prod| [prod.map(&:first).inject(&:merge), prod.map(&:last).inject("") { |memo, d| memo + d[0..-2] } + "0"] }]
      end

      if solutions_to_try
        solutions_to_try = merge_possibilities.call(solutions_to_try, group_solutions)
      else
        solutions_to_try = group_solutions
      end
    end

    # get source of constraint in user code
    trace = Thread.current.backtrace
    interpreter_lines = []
    trace.each.with_index do |line, ix|
      if line.match(/switch_interpreter.rb/)
        interpreter_lines << ix
      end
    end
    line_of_caller = trace[interpreter_lines.max + 1].split("/").last
    failed_solution_strings = []

    solutions_to_try.each do |solution, solution_str|
      result = yield(**solution)

      if !result
        failed_solution_strings << solution_str
      end
    end

    if constraint_group = @non_interpreted_groups[line_of_caller]
      constraint_group.failed_solutions += failed_solution_strings
    else
      @non_interpreted_groups[line_of_caller] = FailedSolutionSwitchGroup.new(failed_solution_strings)
    end
  end

  def interpret(solution)
    out = {}

    solution.split(" ").each do |num|
      num = num.to_i

      if num > 0
        merge_payload!(for_num: num, to_hash: out)
      end
    end

    out
  end
end
