# A Switch represents one key-value mapping in the problem space.
#
# So if your problem is which cat to take on your vacation, and you have
# four cats, and you can only take one, then you have four Switches in
# your problem space:
#
#   1: {:which_cat_to_take=>"Fluffy"}
#   2: {:which_cat_to_take=>"Spot"}
#   3: {:which_cat_to_take=>"Mittens"}
#   4: {:which_cat_to_take=>"Tiger"}
#
class Switch
  def self.next_number
    @@next_number ||= 1
  end

  def self.inc_next_number!
    @@next_number = @@next_number ? @@next_number + 1 : 1
  end

  def self.all
    @@all ||= {}
  end

  def self.find(number)
    all[number]
  end

  def self.add(switch)
    switch.number = next_number
    all[switch.number] = switch
    inc_next_number!
    switch
  end

  def self.each
    all.values.each do |switch|
      yield switch
    end
  end

  extend Enumerable

  def initialize(payload)
    @payload = payload
    Switch.add(self)
  end

  attr_accessor :number, :payload
end
