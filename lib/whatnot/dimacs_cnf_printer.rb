require 'json'

module Whatnot
  class DimacsCNFPrinter
    def initialize(*args)
      @vars = {}
      @vars_total = 1
      @file = File.open("solver-out.txt", "w+")
    end

    attr_reader :file

    def puts(str="")
      @file << str.chomp + "\n"
    end

    def value_name_from_pair(name, value)
      "#{name}=#{value.to_json}"
    end

    def vars(names, domain)
      names.each do |name|
        var(name, domain)
      end
    end

    def var(name, domain)
      puts "c -------------"
      puts "c uniquifying..."
      puts "c var:    #{name.inspect}"

      iter1 = true
      JSON.pretty_generate(domain).each_line do |slice|
        prefix = iter1 ? "c domain: " : "c         "
        iter1 = false
        puts "#{prefix}#{slice}"
      end

      new_var = DimacsCNFVar.new(name, domain, key_iter: @vars_total)
      @vars_total = new_var.key_iter()

      # it must be at least one of the possible values
      puts "#{new_var.all_keys_as_array().join(" ")} 0"

      # it can't be two values
      new_var.all_keys_as_array().combination(2).each do |key1, key2|
        puts "-#{key1} -#{key2} 0"
      end

      @vars[name] = new_var

      puts "c -------------"
      puts
    end

    def all_different(varnames)
      puts "c -------------"
      puts "c all_different..."
      puts "c varnames: #{varnames.inspect}"

      varnames.combination(2).each do |varname1, varname2|
        var1 = @vars[varname1]
        var2 = @vars[varname2]

        var1.matching_pairs(var2).each do |key1, key2|
          puts "-#{key1} -#{key2} 0"
        end
      end
      puts "c -------------"

    end

    def constrain(*varnames)
      puts "c -------------"
      puts "c constraining..."
      puts "c varnames: #{varnames.inspect}"

      argument_sets = nil
      varnames.each do |varname|
        argument_set = @vars[varname].argument_set()

        if argument_sets.nil?
          argument_sets ||= argument_set
        else
          argument_sets = argument_sets.product(argument_set).map(&:flatten)
        end
      end

      argument_sets.each do |argument_set|
        arguments_to_constraint = argument_set.values_at(* argument_set.each_index.select {|i| i.even?})
        key_set =                 argument_set.values_at(* argument_set.each_index.select {|i| i.odd?})

        result = yield(*arguments_to_constraint)

        if !result
          puts "#{key_set.map { |k| "-" + k.to_s }.join(" ")} 0"
        end
      end

      puts "c -------------"
    end

    def all_pairs(vars, &block)
      vars.combination(2).each do |var1, var2|
        constrain(var1, var2, &block)
      end
    end

    def solve
      `minisat solver-out.txt minisat-out.txt`

      solution = File.read("minisat-out.txt").lines[1]
      DimacsCNFVar.interpret(solution)
    end
  end
end
