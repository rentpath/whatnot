require './lib/whatnot'

def sums_benchmark_1(lastletter="Z")
  i = SwitchInterpreter.new
  ("A"..lastletter).map(&:to_sym).each { |letter| i.create_slot letter, [:on, :off], allow_empty: false }
  ("Sum1".."Sum3").to_a.map(&:to_sym).each { |num| i.create_slot num, (0..6).to_a, allow_empty: false }
  i.create_constraint(*(("A"..lastletter).to_a.map(&:to_sym) + ("Sum1".."Sum3").to_a.map(&:to_sym))) do |**solution|
    sum_on = ("A"..lastletter).to_a.map(&:to_sym).reduce(0) { |m, n| solution[n] == :on ? m + 1 : m }
    sum_i  = ("Sum1".."Sum3").to_a.map(&:to_sym).reduce(0) { |m, n| m + solution[n] }
    sum_i == sum_on
  end
  i
end

def sums_benchmark_2(lastletter="Z")
  i = SwitchInterpreter.new
  ("A"..lastletter).map(&:to_sym).each { |letter| i.create_slot letter, [:on, :off], allow_empty: false }
  ("Sum1".."Sum3").to_a.map(&:to_sym).each { |num| i.create_slot num, (0..6).to_a, allow_empty: false }
  i.create_slot(:SumAll, (0..18).to_a, allow_empty: false)
  i.create_constraint(*(("A"..lastletter).to_a.map(&:to_sym) + [:SumAll])) do |**solution|
    sum_on = ("A"..lastletter).to_a.map(&:to_sym).reduce(0) { |m, n| solution[n] == :on ? m + 1 : m }
    sum_on == solution[:SumAll]
  end
  i.create_constraint(*([:SumAll] + ("Sum1".."Sum3").to_a.map(&:to_sym))) do |**solution|
    sum_i  = ("Sum1".."Sum3").to_a.map(&:to_sym).reduce(0) { |m, n| m + solution[n] }
    sum_i == solution[:SumAll]
  end
  i
end

module Whatnot
  describe "Benchmarks" do
    it "can combine 6 switches without an intermediate var" do
      t1 = Time.now
      i = sums_benchmark_1("E")
      s = i.enumerator.first
      t2 = Time.now
    end

    it "can combine 9 switches with an intermediate var" do
      t1 = Time.now
      i = sums_benchmark_2("H")
      s = i.enumerator.first
      t2 = Time.now
    end
  end
end
