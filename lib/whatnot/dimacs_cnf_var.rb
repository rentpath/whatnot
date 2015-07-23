module Whatnot
  class DimacsCNFVar
    def self.names
      @@names ||= {}
    end

    def self.keys
      @@keys ||= {}
    end

    def value_name_from_pair(name, value)
      "#{name}=#{value.to_json}"
    end

    def self.interpret(solution)
      keys = solution.split(" ").map(&:to_i).select { |k| k > 0 }
      values = DimacsCNFVar.names.values_at(*keys)

      values = values.map do |val|
        key, v = *val.match(/\A([^=]+)=(.*)\Z/)[1..2]
        [key.to_sym, JSON.parse(v)]
      end

      Hash[values]
    end

    attr_reader :all_keys_as_array, :key_iter

    def initialize(name, domain, key_iter: 1)
      @name = name
      @domain = domain
      @key_iter = key_iter

      generate_keys
    end

    def matching_pairs(var2)
      (self.keys_by_value.keys & var2.keys_by_value.keys).map do |value|
        [self.keys_by_value[value], var2.keys_by_value[value]]
      end
    end

    def argument_set
      keys_by_value.to_a
    end

    protected

    def generate_keys
      all_val_keys = []

      @domain.each do |value|
        value_name = value_name_from_pair(@name, value)
        all_val_keys << @key_iter

        DimacsCNFVar.names[@key_iter] = value_name
        DimacsCNFVar.keys[value_name] = @key_iter
        @key_iter += 1
      end

      @all_keys_as_array = all_val_keys
    end

    def keys_by_value
      @keys_by_value ||=
        begin
          arr = DimacsCNFVar.keys.select { |k,v| k.start_with?(@name.to_s) }
          arr = arr.map { |k,v| [JSON.parse(k[(@name.to_s.size+1)..-1], symbolize_names: true), v] }
          Hash[arr]
        end
    end
  end
end
