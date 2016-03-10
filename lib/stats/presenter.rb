module Stats
  class Presenter

    attr_accessor :metrics, :dimensions, :filters, :pivots, :orders

    def initialize(options={})
      @metrics       = options[:metrics].to_a.map { |metric| SelectorFactory.selector(metric) }
      @dimensions    = options[:dimensions].to_a.map { |dimension| GrouperFactory.grouper(dimension) }
      @filters       = options[:filters].to_a.map { |filter| FilterFactory.filter(filter) }
      @pivots        = options[:pivots].to_a.map { |pivot| SelectorFactory.selector(pivot) }
      @orders        = options[:orders].to_a.map { |order| Order.new(order) }
      @page          = options[:page] && options[:page].to_i
      @per_page      = (options[:per_page] && options[:per_page].to_i) || Stats.config.per_page
      @inner_join    = options[:inner_join]
      @skip_tables_for_join  = options[:join_filters].to_a

      handle_implicit_input_detectors
    end

    def handle_implicit_input_detectors
      ImplicitInputDetector.detectors.each do |klass|
        detector = klass.new(self)
        detector.modify_presenter if detector.detected?
      end
    end

    def as_json(options = {})
      { data: sql_result, meta: meta_data }
    end

    def sql_result(querier=ActiveRecord::Base.connection)
      querier.exec_query(sql_query).map do |rec|
        rec.delete("id")

        # TODO - do we need to look at each row as if it isnt structured the same as previous?
        rec.each do |k, v|
          if v.is_a?(BigDecimal)
            rec[k] = v.to_f
          elsif is_uuid_value?(v)
            # TODO - can we do this in the database for performance?
            rec[k] = UUIDTools::UUID.parse_raw(v).to_s
          end
        end

        rec
      end
    end

    def meta_data
      {
        metrics:     metrics.map(&:input),
        dimensions:  dimensions.map(&:input),
        filters:     filters.map(&:input),
        pivots:      pivots.map(&:input),
        orders:      orders.map(&:input),
        sql:         sql_query
      }
    end

    def sql_query
      arel_query.to_sql.force_encoding('BINARY').encode('UTF-8', invalid: :replace, undef: :replace).squeeze(" ")
    end

    def arel_query
      return @arel_query if @arel_query

      @arel_query = @inner_join ? base_model.joins(join_hash) : base_model.outer_joins(join_hash)
      @arel_query = @arel_query.select(select_sql_array).group(group_sql_array)

      filters.each do |filter|
        @arel_query = @arel_query.where(filter.where_sql_with_placeholder, filter.operand_hash)
      end

      orders.each do |order|
        @arel_query = @arel_query.order(order.order_sql)
      end

      @arel_query = @arel_query.limit(@per_page).offset(pagination_offset) if @page

      @arel_query
    end

    def base_model
      @pivots.empty? ? @metrics.first.model : @pivots.first.model
    end

    def join_hash
      Stats::Joiner.new(all_models, base_model).associations
    end

    def all_models
      all_models = (metrics + dimensions + filters).map(&:model).uniq
      all_models -= @skip_tables_for_join.map { |table| Stats::Base.model(table) }
    end

    def select_sql_array
      (metrics + dimensions).map(&:select_sql).compact
    end

    def group_sql_array
      dimensions.map(&:group_sql).compact
    end

    def is_uuid_value?(value)
      value && value.is_a?(String) && value.encoding.to_s == "ASCII-8BIT" && value.size == 16
    end

    def pagination_offset
      (@page - 1) * @per_page
    end
  end
end
