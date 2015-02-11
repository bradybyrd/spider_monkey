require "spec_helper"

describe RuntimePhase do

  before(:all) do
    @runtime_phase = RuntimePhase.new
  end

  describe "validations" do
    it { @runtime_phase.should validate_presence_of(:name) }
    it { @runtime_phase.should validate_presence_of(:phase) }
  end

  describe "associations" do
    it { @runtime_phase.should belong_to(:phase) }
    it { @runtime_phase.should have_many(:step_execution_conditions) }
  end

  describe "named scopes" do
    #it { @runtime_phase.should respond_to :in_order }
  end

  describe "callbacks" do
    it "should run a proper callback before destroying" do
      runtime_phase = create(:runtime_phase)
      runtime_phase.should respond_to :destroyable?
      runtime_phase.send :destroy
    end
  end

  it "should have insertion point" do
    @runtime_phase.insertion_point.should == @runtime_phase.position
  end

end



