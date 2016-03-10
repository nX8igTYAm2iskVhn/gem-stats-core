require 'spec_helper'

module Stats
  describe StringSelector do
    describe "simple case" do
      subject { StringSelector.new("check:amount")}

      before do
        class ::Check < ActiveRecord::Base
          self.table_name = "checks"
        end
      end

      its(:model) { should eq(Check) }
      its(:select_sql) { should eq("sum(`checks`.`amount`) AS `check:amount`") }
      its(:table_name) { should eq("checks") }
      its(:parse_input) { should eq([nil, "check", "amount"]) }
    end

    describe "simple case with namespaced model" do
      subject { StringSelector.new("gpos::order:amount")}

      before do
        module ::Gpos
          class Order < ActiveRecord::Base
            self.table_name = "gpos_orders"
          end
        end
      end

      its(:model) { should eq(Gpos::Order) }
      its(:select_sql) { should eq("sum(`gpos_orders`.`amount`) AS `gpos::order:amount`") }
      its(:table_name) { should eq("gpos_orders") }
      its(:parse_input) { should eq([nil, "gpos::order", "amount"]) }
    end

    describe "specified function" do
      subject { StringSelector.new("avg(check:amount)")}

      before do
        class ::Check < ActiveRecord::Base
          self.table_name = "checks"
        end
      end

      its(:model) { should eq(Check) }
      its(:select_sql) { should eq("avg(`checks`.`amount`) AS `avg(check:amount)`") }
      its(:table_name) { should eq("checks") }
      its(:parse_input) { should eq(["avg", "check", "amount"]) }
    end

    describe "check_function" do
      it "errors out for invalid aggregate function" do
        expect { StringSelector.new("random(check:total)") }.to raise_error(RuntimeError, "Aggregation function random is not supported")
      end
    end
  end

  describe HashSelector do
    before do
      class ::Check < ActiveRecord::Base
        self.table_name = "checks"
      end
    end

    describe "with as param" do
      subject { HashSelector.new({sql: "checks.status", as: "check:status", model: "check"})}

      its(:model) { should eq(Check) }
      its(:select_sql) { should eq("checks.status AS `check:status`") }
    end
  end

  describe SelectorFactory do
    it "handles hash input" do
      expect(SelectorFactory.selector({a: 1})).to be_kind_of(HashSelector)
    end

    it "handles string input" do
      expect(SelectorFactory.selector("a:b")).to be_kind_of(StringSelector)
    end

  end
end
