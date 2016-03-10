module Stats
  class FilterFactory
    def self.filter(input)
     if input.is_a?(String)
       StringFilter.new(input)
     else
       HashFilter.new(input)
     end
    end
  end
end
