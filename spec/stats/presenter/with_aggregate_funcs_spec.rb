require 'spec_helper'

module Stats
  describe Presenter do
    describe "filter by time range, single join, with a count aggregate function" do
      before do
        setup_db_connection
        setup_checks
        setup_trading_days

        @before_range = TradingDay.create(date: "2012-02-02")
        @in_range_1 = TradingDay.create(date: "2013-02-02")
        @in_range_2 = TradingDay.create(date: "2013-02-03")
        @after_range = TradingDay.create(date: "2014-01-01")

        Check.create(total: 100, trading_day: @before_range)
        Check.create(total: 200, trading_day: @in_range_1)
        Check.create(total: 300, trading_day: @in_range_2)
        Check.create(total: 400, trading_day: @in_range_2)
        Check.create(total: 300, trading_day: @after_range)
      end

      after { delete_tables }

      subject do
        Presenter.new({
          metrics: %w[count(check:total)],
          dimensions: %w[trading_day:id],
          filters: %w[trading_day:date:gte(2013-01-01) trading_day:date:lte(2013-12-12)],
          pivots: %w[],
          join_filters: %w[]
        })
      end

      its(:sql_result) { should eq([
          {"count(check:total)"=>1, "trading_day:id"=>@in_range_1.id},
          {"count(check:total)"=>2, "trading_day:id"=>@in_range_2.id}
      ])}

      its(:sql_query) { should eq <<-SQL.strip.gsub(/\s+/, " ")
        SELECT count(`checks`.`total`) AS `count(check:total)`, `trading_days`.`id` AS `trading_day:id`
        FROM `checks` LEFT OUTER JOIN `trading_days` ON `checks`.`trading_day_id` = `trading_days`.`id`
        WHERE (`trading_days`.`date` >= '2013-01-01') AND (`trading_days`.`date` <= '2013-12-12')
        GROUP BY `trading_day:id`
        SQL
      }
    end

    describe "filter by time range, single join, with a dayofweek aggregate function" do
      before do
        setup_db_connection
        setup_checks
        setup_trading_days

        @before_range = TradingDay.create(date: "2012-02-02")
        @in_range_1 = TradingDay.create(date: "2013-02-02")
        @in_range_2 = TradingDay.create(date: "2013-02-03")
        @after_range = TradingDay.create(date: "2014-01-01")

        Check.create(total: 100, trading_day: @before_range)
        Check.create(total: 200, trading_day: @in_range_1, created_at: @in_range_1.date)
        Check.create(total: 300, trading_day: @in_range_2, created_at: @in_range_2.date)
        Check.create(total: 400, trading_day: @in_range_2, created_at: @in_range_2.date)
        Check.create(total: 300, trading_day: @after_range)
      end

      after { delete_tables }

      subject do
        Presenter.new({
          metrics: %w[check:total],
          dimensions: %w[dayofweek(check:created_at)],
          filters: %w[trading_day:date:gte(2013-01-01) trading_day:date:lte(2013-12-12)],
          pivots: %w[],
          join_filters: %w[]
        })
      end

      its(:sql_result) { should eq([
                                    {"check:total"=>700, "dayofweek(check:created_at)"=>1},
                                    {"check:total"=>200, "dayofweek(check:created_at)"=>7}]
                                   )}

      its(:sql_query) { should eq <<-SQL.strip.gsub(/\s+/, " ")
        SELECT sum(`checks`.`total`) AS `check:total`,
        dayofweek(`checks`.`created_at`) AS `dayofweek(check:created_at)`
        FROM `checks` LEFT OUTER JOIN `trading_days` ON `checks`.`trading_day_id` = `trading_days`.`id`
        WHERE (`trading_days`.`date` >= '2013-01-01') AND (`trading_days`.`date` <= '2013-12-12')
        GROUP BY `dayofweek(check:created_at)`
        SQL
      }
    end
  end
end
