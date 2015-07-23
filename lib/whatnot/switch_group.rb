class SwitchGroup
  attr_accessor :switches, :possibilities

  def initialize(nums=[], min_on: 1, max_on: 1)
    @min_on = min_on
    @max_on = max_on
    @switches = []
    @possibilities = []

    if block_given?
      Switch.each do |switch|
        @switches << switch if yield(switch.payload)
      end
    else
      @switches = Switch.all.values_at(*nums)
    end

    find_all_possibilities!
  end

  def find_all_possibilities!
    switchmap = Hash[@switches.each_with_index.map { |s, ix| [s.number, ix+1] }]

    groupdimacs = dimacs.lines.map do |line|
      next if line.start_with?("c") || line.lstrip == ""

      nums = line.split(" ").map(&:to_i)

      newnums = []
      nums.each do |n|
        if n > 0
          newnums << switchmap[n]
        elsif n < 0
          newnums << switchmap[n*-1] * -1
        else
          newnums << n
        end
      end

      newnums.map(&:to_s).join(" ")
    end

    groupdimacs = groupdimacs.compact.join("\n")

    groupinterpreter = -> (str) do
      nums = str.split(" ").map(&:to_i)

      newnums = []
      nums.each do |n|
        if n > 0
          newnums << @switches[n-1].number
        elsif n == 0
          newnums << n
        else
          newnums << @switches[(-1*n)-1].number * -1
        end
      end

      solution = newnums.map(&:to_s).join(" ")

      [group_interpret(solution), solution]
    end

    if groupdimacs.empty?
      # all solutions are possible, so iterate all.
      # can't use minisat here (it won't know how many vars there are).
      possibilities = {}

      switch_combos = switches.map do |switch|
        n = switch.number
        [n, -1 * n]
      end

      switch_combos.inject(&:product).each do |product|
        product = product.is_a?(Array) ? product.flatten : [product]
        solution = product.map(&:to_s).join(" ") + " 0"
        possibilities[group_interpret(solution)] = solution
      end

      @possibilities = possibilities
    else
      @possibilities = Hash[SolutionEnumerator.new(groupinterpreter, groupdimacs).entries]
    end
  end

  def group_interpret(solution)
    out = {}

    solution.split(" ").each do |num|
      num = num.to_i

      if num > 0
        merge_payload!(for_num: num, to_hash: out)
      end
    end

    out
  end

  def merge_payload!(for_num: nil, to_hash: nil)
    if for_num.nil? || to_hash.nil?
      raise "left off required kwargs #{"for_num, " unless for_num}#{"to_hash" unless to_hash}" 
    end

    payload = Switch.find(for_num).payload
    payload_key, payload_val = *payload.to_a[0]

    # manage sets vs. slots
    if @max_on > 1
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

  def dimacs
    r = ""

    r << "c Switches:\n"
    @switches.each do |switch|
      switch_pp = switch.payload.pretty_inspect.lines
      r << "c   #{switch.number}: #{switch_pp[0]}"
      switch_pp[1..-1].each do |line|
        r << "c     #{line}"
      end
    end

    if @min_on > 0
      @switches.combination(@switches.size - (@min_on-1)).each do |combo|
        r << combo.map(&:number).map(&:to_s).join(" ") + " 0\n"
      end
    end

    if @max_on < @switches.size
      @switches.combination(@max_on+1).each do |combo|
        r << combo.map(&:number).map { |s| "-#{s}" }.join(" ") + " 0\n"
      end
    end

    r << "\n\n"
    r
  end
end
