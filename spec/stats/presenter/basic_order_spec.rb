require 'spec_helper'

module Stats
  describe Presenter do
    describe "no filter, no join, one order" do
      before do
        setup_db_connection
        setup_checks

        Check.create(total: 100)
        Check.create(total: 200)
      end

      after { delete_tables }

      subject do
        Presenter.new({
          metrics: %w[check:total],
          dimensions: %w[check:id],
          filters: %w[],
          pivots: %w[],
          join_filters: %w[],
          orders: %w[check:total:desc]
        })
      end

      its(:base_model) { should eq(Check) }
      its(:select_sql_array) { should eq [
        "sum(`checks`.`total`) AS `check:total`", "`checks`.`id` AS `check:id`"
      ]}
      its(:group_sql_array) { should eq(["`check:id`"]) }
      its(:filters) { should eq([]) }
      its("orders.first.order_sql") { should eq("`checks`.`total` desc") }

      its(:sql_result) { should eq([
          {"check:total"=>200, "check:id"=>2},
          {"check:total"=>100, "check:id"=>1}
      ])}

      its(:sql_query) { should eq <<-SQL.strip.gsub(/\s+/, " ")
        SELECT sum(`checks`.`total`) AS `check:total`, `checks`.`id` AS `check:id` 
        FROM `checks` 
        GROUP BY `check:id` 
        ORDER BY `checks`.`total` desc
        SQL
      }
    end
  end
end
