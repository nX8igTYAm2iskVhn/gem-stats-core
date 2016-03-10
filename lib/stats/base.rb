module Stats
  class Base
    attr_reader :input, :name, :model, :sql, :as, :column, :aggregate_fun, :field

    def self.model(model_name)
      model_name.split("::").map(&:camelize).join("::").constantize
    end

    def model
      self.class.model(@model)
    end

    def table_name
      model.table_name
    end

    def table_column
      "`#{table_name}`.`#{field}`"
    end

    def parse_input
      function = (match = input.match(/^(.*)\(.*\)$/)) && match[1]
      model, field = input.split(/[()]/)[-1].split(%r{(?<!:):(?!:)})
      return function, model, field
    end

    def column_type
      @column_type ||= model.columns.find {|c| c.name == field }.type
    end
  end
end
