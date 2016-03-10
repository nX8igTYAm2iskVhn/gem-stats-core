module Stats
  class StringFilter < Base
    def initialize(input)
      @input = input

      @model, @field, filter = input.split(%r{(?<!:):(?!:)}, 3)
      @operator, @operand = filter.split(/[()]/)
    end

    def where_sql_with_placeholder
      if @operator == 'in'
        "#{table_column} IN (:operand)" << (operand.include?('null') ? " OR #{table_column} IS NULL" : "")
      else
        "#{table_column} #{sql_operator} #{operand ? ':operand' : ''}"
      end
    end

    def column_type_is_uuid
      [:uuid, :binary].include?(column_type)
    end

    def operand_hash
      operands = operand
      {operand: operands.kind_of?(Array) ? operands - ['null'] : operands}
    end

    def select_sql
      table_column
    end

    def operand
      return nil if @operand.nil?

      if @operator == "in"
        CGI.unescape(@operand).split(",").map do |single_operand|
          single_operand == 'null' ? 'null' : parse_single_operand(single_operand)
        end
      else
        parse_single_operand(@operand)
      end
    end

    private

    def parse_single_operand(single_operand)
      case column_type
      when :datetime, :time
        DateTime.parse(single_operand)
      when :date
        Date.parse(single_operand)
      when :uuid, :binary
        single_operand = single_operand.gsub("-", "")
        UUIDTools::UUID.parse_hexdigest(single_operand)
      else
        single_operand
      end
    end

    def sql_operator
      {
        gte: ">=",
        lte: "<=",
        gt: ">",
        lt: "<",
        eq: "=",
        ne: "!=",
        is_null: "IS NULL",
        not_null: "IS NOT NULL"
      }.with_indifferent_access[@operator]
    end
  end
end
