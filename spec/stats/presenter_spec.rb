require 'spec_helper'

module Stats
  describe Presenter do
    describe "#handle_implicit_input_detectors" do
      before do
        class DetectorA < ImplicitInputDetector
          def detected?
            true
          end

          def modify_presenter
          end
        end

        class DetectorB < ImplicitInputDetector
          def detected?
            false
          end

          def modify_presenter
          end
        end
      end

      it "applies implicit input detectors if correctly" do
        expect_any_instance_of(DetectorA).to receive(:modify_presenter)
        expect_any_instance_of(DetectorB).to_not receive(:modify_presenter)
        Presenter.new
      end
    end

    describe "#is_uuid_value?" do
      it "detects binary uuid string" do
        binary_string = "1234567812345678".force_encoding("ASCII-8BIT")
        expect(subject.is_uuid_value?(binary_string)).to eq(true)
      end

      it "ignores other data type" do
        expect(subject.is_uuid_value?("valid string")).to eq(false)
        expect(subject.is_uuid_value?(1.2)).to eq(false)
      end
    end

    describe "#sql_result" do
      before do
        @presenter = Presenter.new
        @querier = double(:querier)
        binary_string = "1234567812345678".force_encoding("ASCII-8BIT")
        @uuid_string = UUIDTools::UUID.parse_raw(binary_string).to_s

        @presenter.stub(:sql_query).and_return("select foo from bar")
        @querier.stub(:exec_query).and_return([
          {total: BigDecimal.new(123), uuid: binary_string}
        ])
      end

      it "converts big decimal to float" do
        expect(@presenter.sql_result(@querier).first[:total]).to eq(123.0)
      end

      it "converts binary string to uuid string" do
        expect(@presenter.sql_result(@querier).first[:uuid]).to eq(@uuid_string)
      end
    end

    describe "#as_json" do
      before do
        expect(subject).to receive(:sql_result).and_return(:sql_result)
        expect(subject).to receive(:meta_data).and_return(:meta_data)
      end

      its(:as_json) { should eq(data: :sql_result, meta: :meta_data) }
    end

    describe "#meta" do
      before do
        subject.stub(:metrics).and_return([OpenStruct.new(input: :metrics)])
        subject.stub(:filters).and_return([OpenStruct.new(input: :filters)])
        subject.stub(:dimensions).and_return([OpenStruct.new(input: :dimensions)])
        subject.stub(:pivots).and_return([OpenStruct.new(input: :pivots)])
        subject.stub(:orders).and_return([OpenStruct.new(input: :orders)])
        expect(subject).to receive(:sql_query).and_return(:sql_query)
      end

      its(:meta_data) { should eq({
        metrics: [:metrics],
        dimensions: [:dimensions],
        filters: [:filters],
        pivots: [:pivots],
        orders: [:orders],                                    
        sql: :sql_query
      }) }
    end
  end
end
