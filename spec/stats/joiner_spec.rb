require 'spec_helper'

module Stats
  describe Joiner do
    before do
      class ::ModelTwo < ActiveRecord::Base
        belongs_to :model_three
        has_many :model_fours
      end

      class ::ModelThree < ActiveRecord::Base
        has_many :model_twos
      end

      class ::ModelFour < ActiveRecord::Base
        belongs_to :model_two
        has_many   :model_fives, class_name: "ModelFive"
      end

      class ::ModelFive < ActiveRecord::Base
        belongs_to :model_four
      end

      class ::ModelSix < ActiveRecord::Base
      end
    end

    describe "#associations" do
      it "should handle the simple belongs to associations correctly" do
        joiner = Joiner.new([ModelTwo, ModelThree], ModelTwo)
        associations = joiner.associations

        expect(associations).to eq({:model_three=>{}})
      end

      it "should handle the simple has many association correctly" do
        joiner = Joiner.new([ModelTwo, ModelFour], ModelTwo)
        associations = joiner.associations

        expect(associations).to eq({:model_fours=>{}})
      end

      it "should handle path length 2 association correctly" do
        joiner = Joiner.new([ModelTwo, ModelFive], ModelTwo)
        associations = joiner.associations

        expect(associations).to eq({:model_fours=>{:model_fives=>{}}})
      end

      it "should handle failure gracefully" do
        class Rails; end
        logger = double(:logger)
        expect(Rails).to receive(:logger).and_return(logger)

        expect(logger).to receive(:info).with("unable to find association for ModelSix in ModelTwo")

        joiner = Joiner.new([ModelTwo, ModelSix], ModelTwo)
        joiner.associations
      end

      it "should handle several targets correctly" do
        joiner = Joiner.new([ModelTwo, ModelThree, ModelFive], ModelTwo)
        associations = joiner.associations

        expect(associations).to eq({:model_three=>{}, :model_fours=>{:model_fives=>{}}})
      end

      it "handles keystone model" do
        class FakeCheckItem;end

        class FakeCheck;end

        class FakeRestaurant
          def self.keystone?
            true
          end
        end

        joiner = Joiner.new([FakeCheck, FakeRestaurant], FakeCheckItem)

        expect(BreadthFirstHelper).to receive(:find_shortest_path).
          with(FakeCheckItem, FakeCheck, [FakeRestaurant]).and_return({})
        expect(BreadthFirstHelper).to receive(:find_shortest_path).
          with(FakeCheckItem, FakeRestaurant, []).and_return({})
        joiner.associations
      end
    end
  end
end
