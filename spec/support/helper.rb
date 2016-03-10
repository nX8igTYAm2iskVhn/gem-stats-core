def create_database
  require 'mysql2'

  @db_host = "localhost"
  @db_user = "root"
  @db_name = "test_stats"

  client = Mysql2::Client.new(:host => @db_host, :username => @db_user)
  client.query("CREATE DATABASE IF NOT EXISTS #{@db_name}")
  client.close
end

def execute(sql)
  ActiveRecord::Base.connection.execute(sql)
end

def setup_db_connection
  eval <<-CODE
    class ::ActiveRecord::Base
      establish_connection adapter: "mysql2", database: "test_stats", username: "root"
    end
  CODE

  @tables = []
end

def setup_checks
  execute "DROP TABLE IF EXISTS `checks`"
  execute <<-SQL
    CREATE TABLE `checks` (
      `id` int(11) AUTO_INCREMENT,
      `total` int(11) DEFAULT NULL,
      `trading_day_id` int(11),
      `restaurant_id` binary(16),
      `created_at` datetime,
    PRIMARY KEY (`id`)
    );
  SQL

  eval <<-CODE
    class ::Check < ActiveRecord::Base
      include ::ActiveUUID::UUID
      belongs_to :trading_day
    end
  CODE

  @tables << "checks"
end

def setup_trading_days
  execute "DROP TABLE IF EXISTS `trading_days`"
  execute <<-SQL
    CREATE TABLE `trading_days` (
      `id` int(11) AUTO_INCREMENT,
      `date` date,
    PRIMARY KEY (`id`)
    );
  SQL

  eval <<-CODE
    class ::TradingDay < ActiveRecord::Base
      include ::ActiveUUID::UUID
      has_many :checks
    end
  CODE

  @tables << "trading_days"
end

def delete_tables
  @tables.each { |table| execute "drop table #{table}" }
end
