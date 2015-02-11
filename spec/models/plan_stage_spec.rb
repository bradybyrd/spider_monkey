################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2015
# All Rights Reserved.
################################################################################
require 'spec_helper'

describe PlanStage do

  before(:each) do
    @user = create(:user)
    User.stub(:current_user).and_return(@user)
  end
  describe 'validations' do

    before(:each) do
      @plan_stage = create(:plan_stage)
    end

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:plan_template_id) }
    it { should validate_uniqueness_of(:name).scoped_to(:plan_template_id).case_insensitive }
    it { should ensure_length_of(:name).is_at_most(255) }

    it 'should not allow deletion if it has requests' do
      @request = create(:request)
      @plan_member = create(:plan_member, request: @request, stage: @plan_stage)
      @plan_stage.requests.count.should == 1
      PlanStage.count.should == 2
      @plan_stage.destroy
      PlanStage.count.should == 2
      @plan_stage.errors[:requests].should_not be_empty
    end

    it 'should allow deletion if it has no requests' do
      @plan_stage.requests.count.should == 0
      PlanStage.count.should == 1
      @plan_stage.destroy
      PlanStage.count.should == 0
      @plan_stage.errors[:requests].should be_empty
    end

  end

  describe 'associations' do

    before(:each) do
      @plan_stage = create(:plan_stage)
    end

    it 'should have many' do
      @plan_stage.should have_many(:statuses)
      @plan_stage.should have_many(:members)
      @plan_stage.should have_many(:requests)
      @plan_stage.should have_many(:plan_stage_dates)
      @plan_stage.should have_many(:plan_stages_request_templates)
      @plan_stage.should have_many(:request_templates)
      @plan_stage.should have_many(:runs)
      @plan_stage.should have_many(:plan_stage_instances)
    end

    it 'should belong to' do
      @plan_stage.should belong_to(:plan_template)
      @plan_stage.should belong_to(:environment_type)
    end
  end

  describe 'callbacks' do
    describe '#update_plan_stage_instances_for_existing_plans' do
      let(:plan_stage) { create(:plan_stage) }

      specify 'on destroy' do
        PlanStage.any_instance.should_not_receive(:update_plan_stage_instances_for_existing_plans)
        plan_stage.destroy
      end
    end
  end

  describe 'attribute normalizations' do
    it { should normalize_attribute(:name).from('  Hello  ').to('Hello') }
  end

  describe 'named scopes' do
    describe '#with_request_template' do
      it 'should return all plan stages with request templates' do
        request_template = create(:request_template)
        plan_stage = create(:plan_stage)
        plan_stage.request_templates << request_template
        plan_stage2 = create(:plan_stage)
        PlanStage.with_request_template.count.should == 1
        PlanStage.count.should > 1
      end
    end
    describe '#index_order' do
      it 'should return all plan stages in name order' do
        plan_stage1 = create(:plan_stage, name: 'Zebra')
        plan_stage2 = create(:plan_stage, name: 'Alligator')
        PlanStage.first.should == plan_stage1
        PlanStage.index_order.first.should == plan_stage2
        PlanStage.index_order.second.should == plan_stage1
      end
    end
  end

  describe 'custom accessors' do

    describe 'self#default_stage' do
      it 'should return a plan stage with the name Unassigned' do
        PlanStage.default_stage.try(:name).should == 'Unassigned'
      end
    end

    describe 'insertion_point' do
      before (:each) do
        @plan_stage1 = create(:plan_stage, name: 'Original 1', position: 1)
        @plan_stage2 = create(:plan_stage, name: 'Original 2', position: 2)
        @plan_stage3 = create(:plan_stage, name: 'Original 3', position: 3)
      end
      it 'should return the current position when asked for insertion point' do
        @plan_stage3.insertion_point.should == 3
      end
      it 'should use acts as list to insert into the new position when insertion point is set' do
        expect(@plan_stage3.insertion_point).to eq(3)
        expect(@plan_stage2.insertion_point).to eq(2)
        @plan_stage3.insertion_point = 1
        expect(@plan_stage3.position).to eq(1)
        expect(PlanStage.order('position ASC').last.name).to eq('Original 2')
      end
    end
  end

  describe 'request related functions' do
    before (:each) do
      @plan_template = create(:plan_template)
      @plan_stage = create(:plan_stage, plan_template: @plan_template)
      @plan = create(:plan, plan_template: @plan_template)
      @plan_member = create(:plan_member, stage: @plan_stage, plan: @plan)
      @plan_member2 = create(:plan_member, stage: @plan_stage, plan: @plan)
      @plan_member3 = create(:plan_member, stage: @plan_stage, plan: @plan)
      @request1 = create(:request, plan_member: @plan_member, requestor: @user, deployment_coordinator: @user)
      @request2 = create(:request, plan_member: @plan_member2, requestor: @user, deployment_coordinator: @user)
      @request3 = create(:request, plan_member: @plan_member3, requestor: @user, deployment_coordinator: @user)
    end
    it 'should return the last request' do
      @plan_stage.last_request_of_stage(@plan).should == @request3
    end
    it 'should reassign all requests when sent an array of request ids' do
      @plan_stage2 = create(:plan_stage, plan_template: @plan_template)
      @plan_stage2.add_requests!([@request2.id, @request3.id])
      @plan_stage2.last_request_of_stage(@plan).should be == @request3
      @plan_stage.last_request_of_stage(@plan).should == @request1
    end
    it 'should update to unassigned when passed a single request id' do
      @plan_stage.unassign_request!(@request3.id)
      results = @plan_stage.members(true)
      results.length.should be == 2
      @plan_stage.last_request_of_stage(@plan).should == @request2
    end
  end

  describe 'plan member creation for new plans' do
    before(:each) do
      @request_template_1 = create(:request_template)
      @request_template_2 = create(:request_template)
      @plan_template = create(:plan_template)
      @plan_stage = create(:plan_stage, plan_template: @plan_template)
      @plan_stage.request_templates << [@request_template_1, @request_template_2]
      RequestTemplate.any_instance.stub(:create_request_for).and_return(create(:request))
      @plan = create(:plan, plan_template: @plan_template)
    end
    it 'should have the right number of members created through callbacks' do
      results = @plan_stage.members
      results.length.should be == 2
    end
  end


  describe 'should provide convenience methods' do

    before(:each) do
      @strict_environment_type = build(:environment_type, strict: true)
      @open_environment_type = build(:environment_type, strict: false)
      @plan_stage_strict = build(:plan_stage, environment_type: @strict_environment_type)
      @plan_stage_open = build(:plan_stage, environment_type: @open_environment_type)
      @plan_stage_untyped = build(:plan_stage, environment_type_id: nil)
    end

    it 'should provide a truncated short name' do
      @plan_stage_untyped.environment_type_label.should == 'None'
    end

    it 'should provide a label qualified with strict if environment type exists and is strict' do
      @plan_stage_strict.environment_type_label.should == @strict_environment_type.name.truncate(30) + ' (Strict)'
    end

    it 'should provide a label unqualified if environment type exists and is not strict' do
      @plan_stage_open.environment_type_label.should == @open_environment_type.name.truncate(30)
    end
  end
end
