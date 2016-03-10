require 'spec_helper'

module Stats
  describe StringFilter do
    before(:each) do
      StringFilter.send(:public, *StringFilter.private_instance_methods)

      class ::Check < ActiveRecord::Base
        self.table_name = "checks"
      end
    end

    subject { StringFilter.new("check:total:eq(5)") }

    before { Check.stub(:columns).and_return([OpenStruct.new(name: "total", type: :integer)]) }

    its(:where_sql_with_placeholder) { should eq("`checks`.`total` = :operand") }
    its(:operand_hash) { should eq({:operand => "5"}) }
    its(:select_sql) { should eq("`checks`.`total`") }

    describe "#initialize" do
      it "splits datetime filter correctly" do
        @filter = StringFilter.new("a:b:gt(2013-01-01T08:00:00Z)")

        expect(@filter.instance_variable_get(:@model)).to eq("a")
        expect(@filter.instance_variable_get(:@field)).to eq("b")
        expect(@filter.instance_variable_get(:@operator)).to eq("gt")
        expect(@filter.instance_variable_get(:@operand)).to eq("2013-01-01T08:00:00Z")
      end

      it "splits filter with missing operand correctly" do
        @filter = StringFilter.new("a:b:not_null")

        expect(@filter.instance_variable_get(:@model)).to eq("a")
        expect(@filter.instance_variable_get(:@field)).to eq("b")
        expect(@filter.instance_variable_get(:@operator)).to eq("not_null")
        expect(@filter.instance_variable_get(:@operand)).to eq(nil)
      end
    end

    describe "#where_sql_with_placeholder" do
      it "handles IN operator" do
        Check.stub(:columns).and_return([OpenStruct.new(name: "id", type: :integer)])
        filter = StringFilter.new("check:id:in(1,5)")

        expect(filter.where_sql_with_placeholder).to eq("`checks`.`id` IN (:operand)")
      end

      it "handles IN operator with null in operand" do
        Check.stub(:columns).and_return([OpenStruct.new(name: "id", type: :integer)])
        filter = StringFilter.new("check:id:in(1,5,null)")

        expect(filter.where_sql_with_placeholder).to eq("`checks`.`id` IN (:operand) OR `checks`.`id` IS NULL")
      end
    end

    describe "#operand" do
      it "converts datetime correctly" do
        Check.stub(:columns).and_return([OpenStruct.new(name: "created_at", type: :datetime)])
        expect(StringFilter.new("check:created_at:eq(2012-12-12)").operand).to eq(DateTime.parse("2012-12-12"))
      end

      it "converts time correctly" do
        Check.stub(:columns).and_return([OpenStruct.new(name: "created_at", type: :time)])
        expect(StringFilter.new("check:created_at:eq(2012-12-12)").operand).to eq(DateTime.parse("2012-12-12"))
      end

      it "converts date correctly" do
        Check.stub(:columns).and_return([OpenStruct.new(name: "created_at", type: :date)])
        expect(StringFilter.new("check:created_at:eq(2012-12-12)").operand).to eq(Date.parse("2012-12-12"))
      end

      it "converts uuid correctly" do
        Check.stub(:columns).and_return([OpenStruct.new(name: "id", type: :uuid)])
        uuid_object = UUIDTools::UUID.random_create
        uuid_string = uuid_object.to_s.gsub("-", "")
        expect(StringFilter.new("check:id:eq(#{uuid_string})").operand).to eq(uuid_object)
      end

      it "converts integer correctly" do
        Check.stub(:columns).and_return([OpenStruct.new(name: "id", type: :integer)])
        expect(StringFilter.new("check:id:eq(123)").operand).to eq("123")
      end

      it "converts integer array correctly" do
        Check.stub(:columns).and_return([OpenStruct.new(name: "id", type: :integer)])
        expect(StringFilter.new("check:id:in(1,2,3)").operand).to eq(["1", "2", "3"])
      end

      it "converts datetime array correctly" do
        Check.stub(:columns).and_return([OpenStruct.new(name: "created_at", type: :datetime)])
        expect(StringFilter.new("check:created_at:in(2011-01-01,2011-01-02)").operand).
          to eq([DateTime.parse("2011-01-01"), DateTime.parse("2011-01-02")])
      end

      it "converts date array correctly" do
        Check.stub(:columns).and_return([OpenStruct.new(name: "date", type: :date)])
        expect(StringFilter.new("check:date:in(2011-01-01,2011-01-02)").operand).
          to eq([Date.parse("2011-01-01"), Date.parse("2011-01-02")])
      end

      it "converts uuid array correctly" do
        Check.stub(:columns).and_return([OpenStruct.new(name: "id", type: :uuid)])
        uuid_object_1 = UUIDTools::UUID.random_create
        uuid_object_2 = UUIDTools::UUID.random_create
        expect(StringFilter.new("check:id:in(#{uuid_object_1.to_s},#{uuid_object_2})").operand).to eq([uuid_object_1, uuid_object_2])
      end

      it "converts string array correctly" do
        Check.stub(:columns).and_return([OpenStruct.new(name: "name", type: :string)])
        expect(StringFilter.new("check:name:in(one,two,three)").operand).to eq(["one", "two", "three"])
      end

      it "does not touch other types of data" do
        Check.stub(:columns).and_return([OpenStruct.new(name: "name", type: :string)])
        expect(StringFilter.new("check:name:eq(Figs)").operand).to eq("Figs")
      end

      it "returns nil is no operand is specified" do
        Check.stub(:columns).and_return([OpenStruct.new(name: "name", type: :uuid)])
        expect(StringFilter.new("check:name:is_null").operand).to eq(nil)

      end
    end

    describe "#sql_operator" do
      it "gives correct sql operator" do
        expect(StringFilter.new("checks:total:gte(5)").sql_operator).to eq(">=")
        expect(StringFilter.new("checks:total:lte(5)").sql_operator).to eq("<=")
        expect(StringFilter.new("checks:total:gt(5)").sql_operator).to eq(">")
        expect(StringFilter.new("checks:total:lt(5)").sql_operator).to eq("<")
        expect(StringFilter.new("checks:total:eq(5)").sql_operator).to eq("=")
        expect(StringFilter.new("checks:total:ne(5)").sql_operator).to eq("!=")
        expect(StringFilter.new("checks:total:not_null").sql_operator).to eq("IS NOT NULL")
        expect(StringFilter.new("checks:total:is_null").sql_operator).to eq("IS NULL")
      end
    end
  end

  describe HashFilter do
    before(:each) do
      HashFilter.send(:public, *HashFilter.private_instance_methods)

      class ::Check < ActiveRecord::Base
        self.table_name = "checks"
      end
    end

    before { Check.stub(:columns).and_return([OpenStruct.new(name: "amount", type: :integer)]) }

    before do
      @clause ="(`payments`.`amount` != 0 OR `payments`.`amount` IS NULL) OR (`payments`.`tip_amount` != 0 OR `payments`.`tip_amount` IS NULL)"
    end

    subject { HashFilter.new(clause: @clause, params: {operand: "5"}, model: "check", field: "amount") }

    its(:where_sql_with_placeholder) { should eq(@clause) }
    its(:operand_hash) { should eq({operand: "5"}) }
    its(:select_sql) { should eq("`checks`.`amount`") }
  end

  describe FilterFactory do
    before do
      class ::Check < ActiveRecord::Base
        self.table_name = "checks"
      end
    end

    before { Check.stub(:columns).and_return([OpenStruct.new(name: "total", type: :integer)]) }

    it "handles hash input" do
      expect(FilterFactory.filter({a: 1})).to be_kind_of(HashFilter)
    end

    it "handles string input" do
      expect(FilterFactory.filter("check:total:eq(1)")).to be_kind_of(StringFilter)
    end
  end
end
