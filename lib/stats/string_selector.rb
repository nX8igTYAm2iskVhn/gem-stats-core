module Stats
  class StringSelector < Base
    SUPPORTED_AGGREGATE_FUNCTIONS = %w(count dayofweek min max avg variance)

    def initialize(input)
      @input = input
      @function, @model, @field = parse_input

      check_function
    end


    def check_function
      if @function && !SUPPORTED_AGGREGATE_FUNCTIONS.include?(@function)
        raise "Aggregation function #{@function} is not supported"
      end
    end

    def select_sql
      @function ||= "sum"

      "#{@function}(#{table_column}) AS `#{@input}`"
    end

    def table_name
      model.table_name
    end
  end
end

