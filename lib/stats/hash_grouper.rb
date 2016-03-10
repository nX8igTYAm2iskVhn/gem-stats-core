module Stats
  class HashGrouper < Base
    def initialize(input)
      @input = input

      @select = input[:sql]
      @as = input[:as]
      @model = input[:model]
    end

    def select_sql
      if @as
        "#{@select} AS `#{@as}`"
      else
        @select
      end
    end

    def group_sql
      "`#{@as}`"
    end
  end
end
