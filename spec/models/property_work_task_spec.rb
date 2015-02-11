################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe PropertyWorkTask do
  before(:each) do
    @property_work_task = PropertyWorkTask.new
  end

  it { @property_work_task.should belong_to(:property) }
  it { @property_work_task.should belong_to(:work_task) }
  it { @property_work_task.should validate_presence_of(:property) }
  it { @property_work_task.should validate_presence_of(:work_task) }

end
describe PropertyWorkTask do
  describe 'validation' do
    before do
      @property = create(:property)
      @work_task = create(:work_task)

    end
    it 'should require property' do
      property_work_task = PropertyWorkTask.new
      property_work_task.work_task = @work_task
      property_work_task.save
      expect(property_work_task).to_not be_valid
      expect(property_work_task.errors[:property].size).to eq(1)
    end

    it 'should require work task ' do
      property_work_task = PropertyWorkTask.new
      property_work_task.property = @property
      property_work_task.save
      expect(property_work_task).to_not be_valid
      expect(property_work_task.errors[:work_task].size).to eq(1)
    end
  end
end

describe PropertyWorkTask do
  describe "named scope" do
    before do
      @property = create(:property)
      @work_task1 = create(:work_task)
      @work_task2 = create(:work_task)
      @work_task3 = create(:work_task)
    end
    describe ".on_execution" do
      it "should return all on execution work tasks" do
        property_work_task1 = create(:property_work_task, :property => @property, :work_task => @work_task1, :entry_during_step_execution => true)
        property_work_task2 = create(:property_work_task, :property => @property, :work_task => @work_task2, :entry_during_step_execution => false)
        property_work_task3 = create(:property_work_task, :property => @property, :work_task => @work_task3, :entry_during_step_execution => true)

        PropertyWorkTask.on_execution.count.should == 2

        PropertyWorkTask.on_execution.should include(property_work_task1)
        PropertyWorkTask.on_execution.should include(property_work_task3)
        PropertyWorkTask.on_execution.should_not include(property_work_task2)
      end
    end
    describe ".on_creation" do
      it "should return all on creation work tasks" do
        property_work_task1 = create(:property_work_task, :property => @property, :work_task => @work_task1, :entry_during_step_creation => true)
        property_work_task2 = create(:property_work_task, :property => @property, :work_task => @work_task2, :entry_during_step_creation => false)
        property_work_task3 = create(:property_work_task, :property => @property, :work_task => @work_task3, :entry_during_step_creation => true)

        PropertyWorkTask.on_creation.count.should == 2

        PropertyWorkTask.on_creation.should include(property_work_task1)
        PropertyWorkTask.on_creation.should include(property_work_task3)
        PropertyWorkTask.on_creation.should_not include(property_work_task2)
      end
    end
  end
end
