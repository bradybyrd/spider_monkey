require "spec_helper"

describe StepExecutionCondition do

  before(:all) do
    @step_exec_con = StepExecutionCondition.new
  end

  describe "validations" do
    it { @step_exec_con.should validate_presence_of(:step_id) }
    it { @step_exec_con.should validate_presence_of(:referenced_step_id) }

    describe 'property' do
      before(:each) do
        @step_exec_con.condition_type = 'property'
      end
      it { @step_exec_con.should validate_presence_of(:property_id) }
      it { @step_exec_con.should validate_presence_of(:value) }
      it { @step_exec_con.should_not validate_presence_of(:runtime_phase_id) }
    end

    describe 'runtime_phase' do
      before(:each) do
        @step_exec_con.condition_type = 'runtime_phase'
      end
      it { @step_exec_con.should_not validate_presence_of(:property_id) }
      it { @step_exec_con.should_not validate_presence_of(:value) }
      it { @step_exec_con.should validate_presence_of(:runtime_phase_id) }
    end

    describe 'environment' do
      before(:each) do
        @step_exec_con.condition_type = 'environment'
      end
      it { @step_exec_con.should_not validate_presence_of(:property_id) }
      it { @step_exec_con.should_not validate_presence_of(:value) }
      it { @step_exec_con.should_not validate_presence_of(:runtime_phase_id) }
    end

    describe 'environment_type' do
      before(:each) do
        @step_exec_con.condition_type = 'environment_type'
      end
      it { @step_exec_con.should_not validate_presence_of(:property_id) }
      it { @step_exec_con.should_not validate_presence_of(:value) }
      it { @step_exec_con.should_not validate_presence_of(:runtime_phase_id) }
    end
  end

  describe "associations" do
    it { @step_exec_con.should belong_to(:referenced_step) }
    it { @step_exec_con.should belong_to(:property) }
    it { @step_exec_con.should belong_to(:runtime_phase) }
    it { @step_exec_con.should belong_to(:step) }

    it { @step_exec_con.should have_many(:constraints) }
    it { @step_exec_con.should have_many(:environments) }
    it { @step_exec_con.should have_many(:environment_types) }
  end

  describe "named scopes" do
    it "should have a proper return" do
      StepExecutionCondition.get_by_referenced_step(1..4).size.should_not be > 1
    end
  end

end




