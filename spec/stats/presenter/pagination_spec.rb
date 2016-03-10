require 'spec_helper'

module Stats
  describe Presenter do
    before do
      setup_db_connection
      setup_checks
      setup_trading_days

      @restaurant_id = UUIDTools::UUID.random_create

      base_date = Date.parse("2012-01-01")

      100.times do |num|
        Check.create(total: 100, trading_day: TradingDay.create(date: base_date + num.days), restaurant_id: @restaurant_id.raw)
      end
    end

    after { delete_tables }

    describe "with no pagination" do
      subject do
        Presenter.new({
          metrics: %w[check:total],
          dimensions: %w[trading_day:id],
          filters: ["check:restaurant_id:eq(#{@restaurant_id.to_s})"],
          pivots: %w[],
          join_filters: %w[]
        })
      end

      it "returns the correct number of results" do
        expect(subject.sql_result.count).to eq(100)
      end

      its(:sql_query) { should eq <<-SQL.strip.gsub(/\s+/, " ")
          SELECT sum(`checks`.`total`) AS `check:total`, `trading_days`.`id` AS `trading_day:id`
          FROM `checks` LEFT OUTER JOIN `trading_days` ON `checks`.`trading_day_id` = `trading_days`.`id`
          WHERE (`checks`.`restaurant_id` = x'#{@restaurant_id.to_s.gsub("-", "")}')
          GROUP BY `trading_day:id`
        SQL
      }
    end

    describe "with explicit page and implicit per_page" do
      subject do
        Presenter.new({
          metrics: %w[check:total],
          dimensions: %w[trading_day:id],
          filters: ["check:restaurant_id:eq(#{@restaurant_id.to_s})"],
          pivots: %w[],
          join_filters: %w[],
          page: 1
        })
      end

      it "returns the correct number of results" do
        expect(subject.sql_result.count).to eq(20)
      end

      its(:sql_query) { should eq <<-SQL.strip.gsub(/\s+/, " ")
          SELECT sum(`checks`.`total`) AS `check:total`, `trading_days`.`id` AS `trading_day:id`
          FROM `checks` LEFT OUTER JOIN `trading_days` ON `checks`.`trading_day_id` = `trading_days`.`id`
          WHERE (`checks`.`restaurant_id` = x'#{@restaurant_id.to_s.gsub("-", "")}')
          GROUP BY `trading_day:id`
          LIMIT 20 OFFSET 0
        SQL
      }
    end

    describe "with explicit page and explicit per_page" do
      subject do
        Presenter.new({
          metrics: %w[check:total],
          dimensions: %w[trading_day:id],
          filters: ["check:restaurant_id:eq(#{@restaurant_id.to_s})"],
          pivots: %w[],
          join_filters: %w[],
          page: 3,
          per_page: 40
        })
      end

      it "returns the correct number of results" do
        expect(subject.sql_result.count).to eq(20)
      end

      its(:sql_query) { should eq <<-SQL.strip.gsub(/\s+/, " ")
          SELECT sum(`checks`.`total`) AS `check:total`, `trading_days`.`id` AS `trading_day:id`
          FROM `checks` LEFT OUTER JOIN `trading_days` ON `checks`.`trading_day_id` = `trading_days`.`id`
          WHERE (`checks`.`restaurant_id` = x'#{@restaurant_id.to_s.gsub("-", "")}')
          GROUP BY `trading_day:id`
          LIMIT 40 OFFSET 80
        SQL
      }
    end

    describe "global config" do
      subject do
        Stats.configure do |config|
          config.per_page = 40
        end

        Presenter.new({
          metrics: %w[check:total],
          dimensions: %w[trading_day:id],
          filters: ["check:restaurant_id:eq(#{@restaurant_id.to_s})"],
          pivots: %w[],
          join_filters: %w[],
          page: 3
        })
      end

      it "returns the correct number of results" do
        expect(subject.sql_result.count).to eq(20)
      end
    end
  end
end

