module Stats
  class HashFilter < Base
    attr_reader :where_sql_with_placeholder, :operand_hash

    def initialize(input)
      @input = input

      @where_sql_with_placeholder = input[:clause]
      @operand_hash = input[:params]
      @model = input[:model]
      @field = input[:field]
    end

    def select_sql
      @field ? table_column : nil
    end
  end
end
