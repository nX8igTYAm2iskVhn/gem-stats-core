require 'spec_helper'

module Stats
  describe Presenter do
    describe "no filter, single join" do
      before do
        setup_db_connection
        setup_checks
        setup_trading_days

        TradingDay.create(id: 1)
        TradingDay.create(id: 2)
        Check.create(total: 100, trading_day_id: 1)
        Check.create(total: 200, trading_day_id: 1)
        Check.create(total: 300, trading_day_id: 1)
        Check.create(total: 100, trading_day_id: 2)
      end

      after { delete_tables }

      subject do
        Presenter.new({
          metrics: %w[check:total],
          dimensions: %w[trading_day:id],
          filters: %w[],
          pivots: %w[],
          join_filters: %w[]
        })
      end

      its(:base_model) { should eq(Check) }
      its(:join_hash) { should eq({trading_day: {}}) }
      its(:select_sql_array) { should eq [
        "sum(`checks`.`total`) AS `check:total`",
        "`trading_days`.`id` AS `trading_day:id`"
      ]}
      its(:group_sql_array) { should eq(["`trading_day:id`"]) }
      its(:filters) { should eq([]) }

      its(:sql_result) { should eq([
          {"check:total"=>600, "trading_day:id"=>1},
          {"check:total"=>100, "trading_day:id"=>2}
      ])}

      its(:sql_query) { should eq <<-SQL.strip.gsub(/\s+/, " ")
        SELECT sum(`checks`.`total`) AS `check:total`, `trading_days`.`id` AS `trading_day:id`
        FROM `checks` LEFT OUTER JOIN `trading_days` ON `checks`.`trading_day_id` = `trading_days`.`id`
        GROUP BY `trading_day:id`
        SQL
      }
    end
  end
end
