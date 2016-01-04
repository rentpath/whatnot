# A Switch represents one key-value mapping in the problem space.
#
# The Switch class also exposes a simple API for interacting with a
# global collection of Switches
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
# Implementation note: the global collection of all Switches is
# implemented as a class variable holding a Hash, keyed on the number of
# the Switch.
#
class Switch
  # @return [Fixnum] the global Switch count
  def self.next_number
    @@next_number ||= 1
  end

  # Increment the global Switch count.
  def self.inc_next_number!
    @@next_number = @@next_number ? @@next_number + 1 : 1
  end

  # @return [Hash] global collection of Switches as a Hash.
  def self.all
    @@all ||= {}
  end

  # Find a Switch by its number.
  #
  # @param [Fixnum] Switch number
  # @return [Switch] the Switch
  def self.find(number)
    all[number]
  end

  # Add a Switch to the global collection.
  #
  # @param [Switch] the Switch you added.
  # @return [Switch] the Switch you added.
  def self.add(switch)
    switch.number = next_number
    all[switch.number] = switch
    inc_next_number!
    switch
  end

  # Iterate over all Switches.
  def self.each
    all.values.each do |switch|
      yield switch
    end
  end

  extend Enumerable

  # Creates a Switch object and adds it to the global collection of
  # Switches.
  def initialize(payload)
    @payload = payload
    Switch.add(self)
  end

  attr_accessor :number, :payload
end
