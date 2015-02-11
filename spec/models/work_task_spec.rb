################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require File.dirname(__FILE__) + '/../spec_helper'


describe WorkTask do

  describe "associations" do
    before(:each) do
      @work_task = WorkTask.new
    end
    it { @work_task.should have_many(:steps) }
    it { @work_task.should validate_presence_of(:name) }
  end

  describe "validations" do

    before(:each) do
      @work_task = WorkTask.new
      @sample_attributes = {
        :name => "Work Task"
      }
    end

    it "should create a new instance given valid attributes" do
      @work_task.update_attributes(@sample_attributes)
      @work_task.should be_valid
    end

    it "should require a name" do
      @sample_attributes[:name] = nil
      @work_task.update_attributes(@sample_attributes)
      @work_task.should_not be_valid
      @work_task.attributes = @sample_attributes
      @work_task.should_not be_valid
    end

    it "should require a unique name" do
      @work_task.update_attributes(@sample_attributes)
      @duplicate_work_task = WorkTask.new(@sample_attributes)
      @duplicate_work_task.should_not be_valid
    end
  end

  describe "named scopes" do
    describe "#in_order" do
      it "should return all work_tasks with their request templates included" do
        work_task1 = create(:work_task, :position => 3)
        work_task2 = create(:work_task, :position => 1)
        work_task3 = create(:work_task, :position => 2)
        WorkTask.all.should include(work_task1, work_task2, work_task3)
        WorkTask.in_order.first.should == work_task2
        WorkTask.in_order.second.should == work_task3
      end
    end
    describe 'filtered' do
      before(:each) {
        @wt1 = create(:work_task)
        @wt2 = create(:work_task) do |w|
          w.toggle_archive
        end
      }
      specify { WorkTask.filtered(archived: true).should == [@wt2] }
      specify { WorkTask.filtered(unarchived: true).should == [@wt1] }
      specify { WorkTask.filtered(archived: true, unarchived: true).should == [@wt1, @wt2] }
    end
  end

  describe "attribute normalizations" do
    it { should normalize_attribute(:name).from('  Hello  ').to('Hello') }
  end

  describe "acts as list management" do
    before(:each) do
      @work_task = WorkTask.new
    end

    describe "when setting the insertion_point" do
      it "should insert the appliction component at that point" do
        @work_task.should_receive(:insert_at).with(42)
        @work_task.insertion_point = 42
      end
    end

    describe "when reading the insertion point" do
      it "should return the position" do
        @work_task.position = 42
        @work_task.insertion_point.should == @work_task.position
      end
    end

    # These methods do not exist, you can delete tests

    # describe "#activate_with_position" do
    #   pending "activate_without_position method missing" do
    #   before do
    #     @work_task.stub(:activate_without_position!)
    #     @work_task.stub(:insert_at)
    #   end

    #   it "should insert the work_task at the end of the active work_tasks" do
    #     @work_task.should_receive(:insert_at).with(WorkTask.active.count + 1)
    #     @work_task.activate_with_position!
    #   end

    #   it "should call #activate_without_position!" do
    #     @work_task.should_receive(:activate_without_position!)
    #     @work_task.activate_with_position!
    #   end
    #   end
    # end

    # describe "#deactivate_with_position" do
    #   pending "deactivate_without_position method missing" do
    #   before do
    #     @work_task.stub(:deactivate_without_position!)
    #     @work_task.stub(:insert_at)
    #   end

    #   it "should insert the work_task at the end of the work_tasks" do
    #     @work_task.should_receive(:insert_at).with(WorkTask.count)
    #     @work_task.deactivate_with_position!
    #   end

    #   it "should call #deactivate_without_position!" do
    #     @work_task.should_receive(:deactivate_without_position!)
    #     @work_task.deactivate_with_position!
    #   end
    #   end
    # end

    # describe "#insert_at_correct_position" do
    #   it "should insert the work_task at the end of the active work_tasks if it's active" do
    #     pending "active method missing" do
    #       @work_task.should_receive(:insert_at).with(WorkTask.active.count)
    #       @work_task.send(:insert_at_correct_position)
    #     end
    #   end
    # end
  end

  describe '#filtered' do

    before(:all) do
      WorkTask.delete_all
      @task1 = create_work_task()
      @task2 = create_work_task(:name => 'SuperTask')
      @task2.archive
      @task2.reload # Name has been changed during archivation
      @archived_name = @task2.name
      @task3 = create_work_task(:name => 'Task1')
      @active = [@task1, @task3]
      @inactive = [@task2]
    end

    after(:all) do
      WorkTask.delete_all
    end

    it_behaves_like 'active/inactive filter' do

      it 'cumulative filter active by default' do
        result = described_class.filtered(:name => 'Task1')
        result.should match_array([@task3])
      end

      it 'empty cumulative filter active by default' do
        result = described_class.filtered(:name => @task2.name)
        result.should be_empty
      end

      it 'cumulative filter inactive' do
        result = described_class.filtered(:archived => true, :name => @task2.name)
        result.should =~ [@task2]
      end
    end

  end

  protected

  def create_work_task(options = nil)
    create(:work_task, options)
  end
end

