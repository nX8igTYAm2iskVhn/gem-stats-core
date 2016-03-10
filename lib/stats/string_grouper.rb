module Stats
  class StringGrouper < Base
    def initialize(input)
      @input = input

      @function, @model, @field = parse_input
    end

    def select_sql
      if @function
        "#{@function}(#{table_column}) AS `#{@input}`"
      else
        "#{table_column} AS `#{@input}`"
      end
    end

    def group_sql
      "`#{@input}`"
    end
  end
end
