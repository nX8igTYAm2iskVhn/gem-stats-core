require 'spec_helper'

module Stats
  describe StringGrouper do
    subject { StringGrouper.new("check:status")}

    before do
      class ::Check < ActiveRecord::Base
        self.table_name = "checks"
      end

      Check.stub(:columns).and_return([OpenStruct.new(name: "status", type: :integer)])
    end


    its(:model) { should eq(Check) }
    its(:select_sql) { should eq("`checks`.`status` AS `check:status`") }
    its(:table_name) { should eq("checks") }
  end

  describe HashGrouper do
    before do
      class ::Check < ActiveRecord::Base
        self.table_name = "checks"
      end
    end

    describe "with as param" do
      subject { HashGrouper.new({sql: "checks.status", as: "check:status", model: "check"})}

      its(:model) { should eq(Check) }
      its(:select_sql) { should eq("checks.status AS `check:status`") }
      its(:group_sql) { should eq("`check:status`") }
    end

    describe "without as param" do
      subject { HashGrouper.new({sql: "checks.status", model: "check"})}

      its(:select_sql) { should eq("checks.status") }
    end
  end

  describe GrouperFactory do
    it "handles hash input" do
      expect(GrouperFactory.grouper({a: 1})).to be_kind_of(HashGrouper)
    end

    it "handles string input" do
      expect(GrouperFactory.grouper("a:b")).to be_kind_of(StringGrouper)
    end
  end
end

