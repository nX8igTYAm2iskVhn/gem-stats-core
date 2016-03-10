require 'spec_helper'

module Stats
  describe Presenter do
    describe "test inner join options" do
      before do
        setup_db_connection
        setup_checks
        setup_trading_days

        @trading_day = TradingDay.create(date: "2012-02-02")
        @restaurant_id = UUIDTools::UUID.random_create

        Check.create(total: 100, trading_day: @trading_day, restaurant_id: @restaurant_id.raw)
        Check.create(total: 200, trading_day: nil, restaurant_id: @restaurant_id.raw)
        Check.create(total: 300, trading_day: nil, restaurant_id: @restaurant_id.raw)
      end

      after { delete_tables }

      describe "no inner join option, we should use let outer join" do
        subject do
          Presenter.new({
                          metrics: %w[check:total],
                          dimensions: %w[trading_day:id],
                          filters: ["check:restaurant_id:eq(#{@restaurant_id.to_s})"],
                          pivots: %w[],
                          join_filters: %w[]
                        })
        end

        its(:sql_result) { should eq([{"check:total"=>500, "trading_day:id"=> nil},
                                      {"check:total"=>100, "trading_day:id"=>1}])}

        its(:sql_query) { should eq <<-SQL.strip.gsub(/\s+/, " ")
          SELECT sum(`checks`.`total`) AS `check:total`, `trading_days`.`id` AS `trading_day:id`
          FROM `checks` LEFT OUTER JOIN `trading_days` ON `checks`.`trading_day_id` = `trading_days`.`id`
          WHERE (`checks`.`restaurant_id` = x'#{@restaurant_id.to_s.gsub("-", "")}')
          GROUP BY `trading_day:id`
          SQL
        }
      end

      describe "inner join option equals to false, we should use let outer join" do
        subject do
          Presenter.new({
                          metrics: %w[check:total],
                          dimensions: %w[trading_day:id],
                          filters: ["check:restaurant_id:eq(#{@restaurant_id.to_s})"],
                          pivots: %w[],
                          join_filters: %w[],
                          inner_join: false
                        })
        end

        its(:sql_result) { should eq([{"check:total"=>500, "trading_day:id"=> nil},
                                      {"check:total"=>100, "trading_day:id"=>1}])}

        its(:sql_query) { should eq <<-SQL.strip.gsub(/\s+/, " ")
          SELECT sum(`checks`.`total`) AS `check:total`, `trading_days`.`id` AS `trading_day:id`
          FROM `checks` LEFT OUTER JOIN `trading_days` ON `checks`.`trading_day_id` = `trading_days`.`id`
          WHERE (`checks`.`restaurant_id` = x'#{@restaurant_id.to_s.gsub("-", "")}')
          GROUP BY `trading_day:id`
          SQL
        }
      end

      describe "inner join option equals to true, we should use inner join" do
        subject do
          Presenter.new({
                          metrics: %w[check:total],
                          dimensions: %w[trading_day:id],
                          filters: ["check:restaurant_id:eq(#{@restaurant_id.to_s})"],
                          pivots: %w[],
                          join_filters: %w[],
                          inner_join: true
                        })
        end

        its(:sql_result) { should eq([
                                      {"check:total"=>100, "trading_day:id"=>@trading_day.id}
                                     ])}

        its(:sql_query) { should eq <<-SQL.strip.gsub(/\s+/, " ")
          SELECT sum(`checks`.`total`) AS `check:total`, `trading_days`.`id` AS `trading_day:id`
          FROM `checks` INNER JOIN `trading_days` ON `trading_days`.`id` = `checks`.`trading_day_id`
          WHERE (`checks`.`restaurant_id` = x'#{@restaurant_id.to_s.gsub("-", "")}')
          GROUP BY `trading_day:id`
          SQL
        }
      end

    end
  end
end
