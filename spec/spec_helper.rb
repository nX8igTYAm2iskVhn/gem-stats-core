require 'simplecov'
SimpleCov.start

require 'lib/stats-core-api'
require 'active_record'
require 'activeuuid'
require 'uuidtools'
require 'ar_outer_joins'
require 'active_support/core_ext/string/inflections.rb'
require 'active_support/core_ext/hash/indifferent_access.rb'
require 'support/helper.rb'
require 'ostruct'
require 'pry'

create_database
