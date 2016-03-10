module Stats
  class Joiner
    attr_accessor :join_models, :base_model, :join_filters

    # TODO: transfer join_filters form metrics format to
    # Payment.arel_table[:amount].not_eq(0).or(Payment.arel_table[:tip_amount].not_eq(0)
    def initialize(join_models, base_model, join_filters=[])
      @join_models = join_models
      @base_model = base_model
      @join_filters = join_filters
    end

    def associations
      joins_hash = {}

      keystone_model = join_models.detect { |model| model.respond_to?(:keystone?) && model.keystone? == true }

      join_models.each do |join_model|
        next if join_model == base_model

        join_filters = (keystone_model && keystone_model != join_model) ? [keystone_model] : []

        if (assoc = BreadthFirstHelper.find_shortest_path(base_model, join_model, join_filters))
          joins_hash.deep_merge!(assoc)
        elsif defined?(Rails)
          Rails.logger.info("unable to find association for #{join_model.name} in #{base_model.name}")
        end
      end

      joins_hash
    end
  end
end
