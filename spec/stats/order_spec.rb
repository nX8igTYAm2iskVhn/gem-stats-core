require 'spec_helper'

module Stats
  describe Order do

    before do
      class ::Check < ActiveRecord::Base
        self.table_name = "checks"
      end

      Check.stub(:columns).and_return([OpenStruct.new(name: "created_at", type: :string)])
    end

    it "should parse the input correctly" do
      order = Order.new("check:created_at:asc")
      
      expect(order.model).to        eq(Check)
      expect(order.order_sql).to    eq("`checks`.`created_at` asc")
      expect(order.table_name).to   eq("checks")
    end

    it "should raise error if the order is not right" do
      expect {Order.new("check:created_at:ddsc")}.to raise_error Order::NOT_SUPPORT_ERROR_MESSAGE
    end
  end
end
