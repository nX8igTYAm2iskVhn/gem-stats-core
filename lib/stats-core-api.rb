require_relative "stats/base"
require_relative "breadth_first_helper"
require_relative "stats/presenter"

require_relative "stats/selector_factory"
require_relative "stats/string_selector"
require_relative "stats/hash_selector"

require_relative "stats/grouper_factory"
require_relative "stats/string_grouper"
require_relative "stats/hash_grouper"

require_relative "stats/joiner"

require_relative "stats/filter_factory"
require_relative "stats/string_filter"
require_relative "stats/hash_filter"

require_relative "stats/implicit_input_detector"
require_relative "stats/order"

require 'active_support/configurable'

module Stats
  def self.configure(&block)
    yield @config ||= Stats::Configuration.new
  end

  def self.config
    @config
  end

  class Configuration
    include ActiveSupport::Configurable
    config_accessor :per_page do 20 end
  end

  self.configure {}
end
