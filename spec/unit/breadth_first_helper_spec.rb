require 'spec_helper'

describe BreadthFirstHelper do
  describe "#find_shortest_path" do
    describe "simple_case" do
      before do
        class A1 < ActiveRecord::Base
          belongs_to :b1
        end

        class B1 < ActiveRecord::Base
          belongs_to :c1
        end

        class C1 < ActiveRecord::Base
        end
      end

      it "handles two model link" do
        shortest_path = BreadthFirstHelper.find_shortest_path(A1, B1, [])
        expect(shortest_path).to eq(b1: {})
      end

      it "handles three model link" do
        shortest_path = BreadthFirstHelper.find_shortest_path(A1, C1, [])
        expect(shortest_path).to eq(b1: {c1: {}})
      end
    end

    describe "select shorter path" do
      before do
        class A2 < ActiveRecord::Base
          belongs_to :b2
          belongs_to :c2
        end

        class B2 < ActiveRecord::Base
          belongs_to :c2
        end

        class C2 < ActiveRecord::Base
        end
      end

      it "selects shorter path" do
        shortest_path = BreadthFirstHelper.find_shortest_path(A2, C2, [])
        expect(shortest_path).to eq(c2: {})
      end
    end

    describe "skipping associations" do
      before do
        class A3 < ActiveRecord::Base
          belongs_to :b3
          belongs_to :c3_1, class_name: "C3"
          belongs_to :c3_2, class_name: "C3"

          def self.associations_to_ignore_for_join
            [:c3_1]
          end
        end

        class B3 < ActiveRecord::Base
          belongs_to :c3
        end

        class C3 < ActiveRecord::Base
        end
      end

      it "skips ignored associations" do
        shortest_path = BreadthFirstHelper.find_shortest_path(A3, C3, [])
        expect(shortest_path).to eq(c3_2: {})
      end
    end
  end

  describe ".should_ignore_association" do
    before do
      class A4 < ActiveRecord::Base
        belongs_to :b4
        belongs_to :c4
      end

      class B4 < ActiveRecord::Base
        belongs_to :x
        belongs_to :y

        def self.associations_to_ignore_for_join
          [:x]
        end
      end

      class C4 < ActiveRecord::Base
        belongs_to :z
      end
    end

    describe "when associations_to_ignore_for_join is defined" do
      let!(:klass) { A4.reflect_on_all_associations.first }
      let!(:x_assoc) { B4.reflect_on_all_associations.first }
      let!(:y_assoc) { B4.reflect_on_all_associations.last }

      it "returns true for blacklisted assoc" do
        expect(BreadthFirstHelper.should_ignore_association(klass, x_assoc)).to be_true
      end

      it "returns false for non-blacklisted assoc" do
        expect(BreadthFirstHelper.should_ignore_association(klass, y_assoc)).to be_false
      end
    end

    describe "when associations_to_ignore_for_join is not defined" do
      let!(:klass) { A4.reflect_on_all_associations.last }
      let!(:z_assoc) { C4.reflect_on_all_associations.first }

      it "returns false" do
        expect(BreadthFirstHelper.should_ignore_association(klass, z_assoc)).to be_false
      end
    end
  end

  describe ".hash_path" do
    before do
      class A5 < ActiveRecord::Base
        belongs_to :b5
      end

      class B5 < ActiveRecord::Base
        belongs_to :c5
        def self.join_condition
          :arel_node
        end
      end

      class C5 < ActiveRecord::Base
      end
    end

    it "adds join_condition if present" do
      fullpath = [A5] + A5.reflect_on_all_associations
      expect(BreadthFirstHelper.hash_path(fullpath)).to eq({:b5 => {:__and_on=>:arel_node}})
    end

    it "does not add join_condition if not present" do
      fullpath = [B5] + B5.reflect_on_all_associations
      expect(BreadthFirstHelper.hash_path(fullpath)).to eq({:c5 => {}})
    end
  end

  describe ".associations" do
    before do
      class A6 < ActiveRecord::Base
        belongs_to :b6
      end

      class B6 < ActiveRecord::Base
        has_many :c6s, through: :d
        has_many :d6s
        has_many :e6s
        has_many :f6s
        has_many :g6s
      end

      class F6 < ActiveRecord::Base
      end
    end

    it "finds correct associations without join_filters" do
      assoc = A6.reflect_on_all_associations.first
      associations = B6.reflect_on_all_associations
      BreadthFirstHelper.stub(:should_ignore_association).and_call_original
      BreadthFirstHelper.stub(:should_ignore_association).with(assoc, associations[2]).and_return(true)

      expect(BreadthFirstHelper.associations(assoc).count).to eq(3)
      expect(BreadthFirstHelper.associations(assoc)[0].name).to eq(:d6s)
      expect(BreadthFirstHelper.associations(assoc)[1].name).to eq(:f6s)
      expect(BreadthFirstHelper.associations(assoc)[2].name).to eq(:g6s)
    end

    it "finds correct associations with join_filters" do
      assoc = A6.reflect_on_all_associations.first
      associations = B6.reflect_on_all_associations
      BreadthFirstHelper.stub(:should_ignore_association).and_call_original
      BreadthFirstHelper.stub(:should_ignore_association).with(assoc, associations[2]).and_return(true)

      expect(BreadthFirstHelper.associations(assoc, join_filters: [F6]).count).to eq(2)
      expect(BreadthFirstHelper.associations(assoc, join_filters: [F6])[0].name).to eq(:d6s)
      expect(BreadthFirstHelper.associations(assoc, join_filters: [F6])[1].name).to eq(:g6s)
    end
  end
end
