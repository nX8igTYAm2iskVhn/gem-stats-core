module Stats
  class GrouperFactory
    def self.grouper(input)
      if input.is_a?(String)
        StringGrouper.new(input)
      else
        HashGrouper.new(input)
      end
    end
  end
end
