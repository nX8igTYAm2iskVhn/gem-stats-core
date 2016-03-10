module Stats
  class SelectorFactory
    def self.selector(input)
     if input.is_a?(String)
       StringSelector.new(input)
     else
       HashSelector.new(input)
     end
    end
  end
end

