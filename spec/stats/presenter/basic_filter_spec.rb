require 'spec_helper'

module Stats
  describe Presenter do
    describe "no filter, single join" do
      before do
        setup_db_connection
        setup_checks
        setup_trading_days

        @before_range = TradingDay.create(date: "2012-02-02")
        @in_range = TradingDay.create(date: "2013-02-02")
        @after_range = TradingDay.create(date: "2014-01-01")

        @restaurant_id = UUIDTools::UUID.random_create

        Check.create(total: 100, trading_day: @before_range, restaurant_id: @restaurant_id.raw)
        Check.create(total: 200, trading_day: @in_range, restaurant_id: @restaurant_id.raw)
        Check.create(total: 300, trading_day: @after_range, restaurant_id: @restaurant_id.raw)
      end

      after { delete_tables }

      describe "string input" do
        subject do
          Presenter.new({
            metrics: %w[check:total],
            dimensions: %w[trading_day:id],
            filters: ["trading_day:date:gte(2013-01-01)",
                        "trading_day:date:lte(2013-12-12)",
                        "check:restaurant_id:eq(#{@restaurant_id.to_s})"],
            pivots: %w[],
            join_filters: %w[]
          })
        end

        its(:sql_result) { should eq([
            {"check:total"=>200, "trading_day:id"=>@in_range.id}
        ])}

        its(:sql_query) { should eq <<-SQL.strip.gsub(/\s+/, " ")
          SELECT sum(`checks`.`total`) AS `check:total`, `trading_days`.`id` AS `trading_day:id`
          FROM `checks` LEFT OUTER JOIN `trading_days` ON `checks`.`trading_day_id` = `trading_days`.`id`
          WHERE (`trading_days`.`date` >= '2013-01-01')
          AND (`trading_days`.`date` <= '2013-12-12')
          AND (`checks`.`restaurant_id` = x'#{@restaurant_id.to_s.gsub("-", "")}')
          GROUP BY `trading_day:id`
          SQL
        }
      end

      describe "string input with null in in filter" do
        subject do
          Presenter.new({
            metrics: %w[check:total],
            dimensions: %w[trading_day:id],
            filters: ["trading_day:date:gte(2013-01-01)",
                        "trading_day:date:lte(2013-12-12)",
                        "check:restaurant_id:in(#{@restaurant_id.to_s},null)"],
            pivots: %w[],
            join_filters: %w[]
          })
        end

        its(:sql_result) { should eq([
            {"check:total"=>200, "trading_day:id"=>@in_range.id}
        ])}

        its(:sql_query) { should eq <<-SQL.strip.gsub(/\s+/, " ")
          SELECT sum(`checks`.`total`) AS `check:total`, `trading_days`.`id` AS `trading_day:id`
          FROM `checks` LEFT OUTER JOIN `trading_days` ON `checks`.`trading_day_id` = `trading_days`.`id`
          WHERE (`trading_days`.`date` >= '2013-01-01')
          AND (`trading_days`.`date` <= '2013-12-12')
          AND (`checks`.`restaurant_id` IN (x'#{@restaurant_id.to_s.gsub("-", "")}') OR `checks`.`restaurant_id` IS NULL)
          GROUP BY `trading_day:id`
          SQL
        }
      end


      describe "hash input" do
        subject do
          Presenter.new({
            metrics: %w[check:total],
            dimensions: [{sql:"`trading_days`.`id`" , as: "trading_day:id", model: "check"}],
            filters: [{clause: "`trading_days`.`date` >= '2013-01-01' AND `trading_days`.`date` <= '2013-12-12'", params: {}, model: "trading_day"}],
            pivots: %w[],
          })
        end

        its(:sql_result) { should eq([
            {"check:total"=>200, "trading_day:id"=>@in_range.id}
        ])}

        its(:sql_query) { should eq <<-SQL.strip.gsub(/\s+/, " ")
          SELECT sum(`checks`.`total`) AS `check:total`, `trading_days`.`id` AS `trading_day:id`
          FROM `checks` LEFT OUTER JOIN `trading_days` ON `checks`.`trading_day_id` = `trading_days`.`id`
          WHERE (`trading_days`.`date` >= '2013-01-01' AND `trading_days`.`date` <= '2013-12-12')
          GROUP BY `trading_day:id`
          SQL
        }
      end
    end
  end
end
