module Stats
  class Order < Base
    SUPPORTED_DIRECTIONS = %w[asc desc]
    NOT_SUPPORT_ERROR_MESSAGE = "We only support #{SUPPORTED_DIRECTIONS.join('|')} directions"
    attr_reader :order_sql

    def initialize(input)
      @input = input
      @model, @field, direction = input.split(%r{(?<!:):(?!:)}, 3)
      raise NOT_SUPPORT_ERROR_MESSAGE unless SUPPORTED_DIRECTIONS.include?(direction)
      @order_sql = "#{table_column} #{direction}"
    end

  end
end
