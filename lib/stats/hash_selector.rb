module Stats
  class HashSelector < Base
    def initialize(input)
      @input = input

      @select_sql = input[:sql]
      @as = input[:as]
      @model = input[:model]
    end

    def select_sql
      "#{@select_sql} AS `#{@as}`"
    end
  end
end
