require "spec_helper"

describe BladelogicScriptArgument do
  before(:each) do
    @bladelogic_scr_arg = BladelogicScriptArgument.new
  end

  let(:BladelogicScriptArgument_with_SharedScriptArgument) {
    BladelogicScriptArgument.new do
      include BladelogicScriptArgument::SharedScriptArgument
    end
  }

  describe "validations" do
    it { @bladelogic_scr_arg.should validate_presence_of(:name) }
    it { @bladelogic_scr_arg.should validate_presence_of(:argument) }
  end

  context "associations" do
    describe "should belong to" do
      it { @bladelogic_scr_arg.should belong_to(:script) }
    end

    describe "should have many" do
      it { @bladelogic_scr_arg.should have_many(:step_script_arguments) }
    end
  end

  describe "should have argument type #in-text" do
    bladelogic_scr_arg = BladelogicScriptArgument.new
    bladelogic_scr_arg.argument_type.should == 'in-text'
  end

  describe "should serialize data" do
    it { should serialize(:choices).as(Array) }
  end
end
