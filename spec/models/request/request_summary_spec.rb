require 'spec_helper'

describe Request do
  before(:each) do
    @dest_mock = mock("destination")
    @dest_mock.stub(:publish).and_return(true)
    EventableStompletBinder.stub(:fetch).and_return(@dest_mock)
  end

  describe "#step_modification_prefix" do
    it 'returns modification prefix' do
      request = build :request
      step = build :step
      step_prefix = "Step prefix"

      allow_any_instance_of(RequestActivity::StepActivityInfo).to receive(:modification_prefix).and_return(step_prefix)

      expect(request.step_modification_prefix(step)).to eq step_prefix
    end
  end
end
