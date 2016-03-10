require 'spec_helper'

module Stats
  describe ImplicitInputDetector do
    subject { ImplicitInputDetector.new(Presenter.new) }

    its(:detected?) { should eq(false) }

    describe "#modify_presenter" do
      it "errors when called directly" do
        expect { subject.modify_presenter }.to raise_error(RuntimeError, "implement in subclass")
      end
    end
  end
end
