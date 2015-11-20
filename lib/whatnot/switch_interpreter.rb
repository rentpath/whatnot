# SwitchInterpreter is the main class used to interact with the Whatnot library.
#
# == Role
#
# Minisat understands a constraint in terms like this:
#
#   100 101 102 103 0
#   -100 -101 0
#   -100 -102 0
#   -100 -103 0
#   -101 -102 0
#   -101 -103 0
#   -102 -103 0
#
# Humans understand a constraint more like this:
#
#   {which_cat_to_take_on_my_vacation: 'Fluffy'} or
#   {which_cat_to_take_on_my_vacation: 'Spot'} or
#   {which_cat_to_take_on_my_vacation: 'Tiger'} or
#   {which_cat_to_take_on_my_vacation: 'Mittens'}
#
# It's the SwitchInterpreter's job to translate one into the other.
#
# == Usage
#
# 1. Call #new.
# 2. Create your constraints using the #create_* instance methods on SwitchInterpreter.
# 3. To iterate through solutions, pass the #interpret method of this object into a
#    SolutionEnumerator instance.
#
# == Architecture notes
#
# - The #interpret method can be overridden in a subclass of SwitchInterpreter if you
#   want to produce some output other than a hash from the DIMACS output.
#
class SwitchInterpreter

  # For when you try to register a switch in a SwitchInterpreter by a name that's taken
  class NameCollisionError < ::RuntimeError

    # @param info The name of the switch that's already taken.
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

  ##
  # Create a slot. A "slot" is a SwitchGroup that represents a key that can contain only
  # one of a set of possible values that you specify.
  #
  # @param [#to_s] slotname The name of the slot.
  # @param [Array] slotvalues The set of possible values.
  # @param allow_empty [Boolean] Whether the slot can be empty (defaults to true).
  #
  # ==== Usage
  #
  # To create a slot called "A", with possible values (foo, bar, baz):
  #
  #   i.create_slot(:A, [:foo, :bar, :baz], allow_empty: false)
  #
  # This slot will appear in the DIMACS output like this:
  #
  #   c ---------------------------
  #   c INTERPRETED
  #   c SwitchGroup =>
  #   c   A
  #   c
  #   c Switches:
  #   c   1: {:A=>:foo}
  #   c   2: {:A=>:bar}
  #   c   3: {:A=>:baz}
  #   1 2 3 0
  #   -1 -2 0
  #   -1 -3 0
  #   -2 -3 0
  #
  # Valid solutions:
  #
  #   {:A=>:baz}
  #   {:A=>:foo}
  #   {:A=>:bar}
  #
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

  ##
  # Create a set. A "set" is a SwitchGroup that represents a key that can contain more
  # than one of a set of possible values. This value appears in the solution as an
  # Array if it is non-empty, and if it is empty, it doesn't appear at all.
  #
  # @param [#to_s] setname The name of the set.
  # @param [Array] setvalues The set of possible values.
  # @param allow_empty [Boolean] Whether the set can be empty (defaults to true).
  # @param max_values [Integer] Maximum number of values (defaults to 2).
  #
  # ==== Usage
  #
  # To create a set called "A", with possible values (foo, bar, baz):
  #
  #   i.create_set(:A, [:foo, :bar, :baz], allow_empty: false)
  #
  # This set will appear in the DIMACS output like this:
  #
  #   c ---------------------------
  #   c INTERPRETED
  #   c SwitchGroup =>
  #   c   A
  #   c
  #   c Switches:
  #   c   1: {:A=>:foo}
  #   c   2: {:A=>:bar}
  #   c   3: {:A=>:baz}
  #   1 2 3 0
  #   -1 -2 -3 0
  #
  # Valid solutions:
  #
  #   {:A=>[:baz]}
  #   {:A=>[:foo]}
  #   {:A=>[:bar]}
  #   {:A=>[:foo, :bar]}
  #   {:A=>[:bar, :baz]}
  #   {:A=>[:foo, :baz]}
  #
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

  ##
  # Create a series of mutually exclusive slots. Each slot can only hold one of a set
  # of possible values, and each possible value can only appear once across all of the
  # slots. You can visualize this as a table with chairs (slots) and guests (values).
  # Each chair can only seat one guest, and each guest can only sit in one chair.
  #
  # @param [Array] slotname The names of the slot.
  # @param [Array] slotvalues The set of possible values.
  # @param allow_empty [Boolean] Whether a slot can be empty (defaults to true).
  #
  # ==== Usage
  #
  # To create mutually exclusive slots:
  #
  #   i.create_mutually_exclusive_slots([:A, :B, :C], [:foo, :bar, :baz], allow_empty: false)
  #
  # Valid solutions:
  #
  #   {:A=>:baz, :B=>:foo, :C=>:bar}
  #   {:A=>:bar, :B=>:foo, :C=>:baz}
  #   {:A=>:foo, :B=>:bar, :C=>:baz}
  #   {:A=>:baz, :B=>:bar, :C=>:foo}
  #   {:A=>:foo, :B=>:baz, :C=>:bar}
  #   {:A=>:bar, :B=>:baz, :C=>:foo}
  #
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

      @non_interpreted_groups["Slots [#{slotnames}] mutually exclusive, value: #{slotvalue}"] = mutual_exclusion
    end
  end

  ##
  # Create a series of mutually exclusive sets. A set can hold multiple values, but each
  # value can only go into one set. Imagine you have a bunch of fish and a number of buckets
  # to put them in. Each fish can only go in one bucket, but each bucket can hold a number
  # of fish. You can specify the max size of a bucket with max_values.
  #
  # @param [Array] slotname The names of the slot.
  # @param [Array] slotvalues The set of possible values.
  # @param allow_empty [Boolean] Whether a slot can be empty (defaults to true).
  # @param max_values [Boolean] Max number of values a bucket can hold (defaults to 2).
  #
  # ==== Usage
  #
  # To create mutually exclusive sets:
  #
  #   i.create_mutually_exclusive_sets([:A, :B], [:foo, :bar], allow_empty: true)
  #
  # Valid solutions:
  #
  #   {:B=>[:foo, :bar]}
  #   {:A=>[:foo], :B=>[:bar]}
  #   {:A=>[:foo, :bar]}
  #   {:A=>[:bar], :B=>[:foo]}
  #
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

      @non_interpreted_groups["Sets [#{slotnames}] mutually exclusive, value: #{slotvalue}"] = mutual_exclusion
    end
  end

  ##
  # Create a constraint you can define yourself with a block. The block must return false when
  # the solution does not meet the constraint. It works like this:
  #
  # 1. First, all possible combinations of values for the given variables are found.
  # 2. The combinations are made into hashes, iterated, and passed into the block one by one.
  # 3. If a combination of values does not meet the constraint, all solutions with this combination
  #    are ruled out.
  #
  # It's important to remember that the hash passed into the block is a partial solution that
  # only contains values for the variables you passed into the method.
  #
  # @param [Array] slotnames The slot or set names.
  # @yield [Hash] solution The partial solution.
  #
  # ==== Example (ride sharing in 3 vehicles)
  #
  #   1.upto(3).each do |n|
  #
  #     # number of passengers per vehicle
  #     i.create_constraint("vehicle_#{n}", "vehicle_#{n}_passengers") do |**solution|
  #       if is_van?(solution["vehicle_1"])
  #         solution["vehicle_1_passengers"].size <= 6
  #       else
  #         solution["vehicle_1_passengers"].size <= 4
  #       end
  #     end
  #   end
  #
  #   # all vehicles full (or all except 1)
  #   i.create_constraint("vehicle_1_passengers",
  #                       "vehicle_2_passengers",
  #                       "vehicle_3_passengers") do |**solution|
  #
  #     (vehicle_is_full?(solution["vehicle_1"]) &&
  #      vehicle_is_full?(solution["vehicle_2"]) &&
  #      vehicle_is_full?(solution["vehicle_3"])) ||
  #
  #     ((vehicle_is_full?(solution["vehicle_1"]) && vehicle_is_full?(solution["vehicle_2"])) ||
  #      (vehicle_is_full?(solution["vehicle_2"]) && vehicle_is_full?(solution["vehicle_3"])) ||
  #      (vehicle_is_full?(solution["vehicle_1"]) && vehicle_is_full?(solution["vehicle_3"])))
  #   end
  #
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

  private

  def interpreted_groups
    groups = {}
    groups.merge! @slot_groups
    groups.merge! @set_groups
    groups
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
