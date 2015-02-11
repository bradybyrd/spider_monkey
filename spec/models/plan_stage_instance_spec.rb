################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe PlanStageInstance do

  describe "with automatic creation turned off in plan" do

    before(:all) do
      # without this, it is difficult to get a plan assigned without two copies
      # of the plan stage instance
      Plan.skip_callback(:create, :after, :build_plan_stage_instances)
    end

    after(:all) do
      # without this, it is difficult to get a plan assigned without two copies
      # of the plan stage instance
      Plan.set_callback(:create, :after, :build_plan_stage_instances)
    end

    describe "validations and associations" do
      before(:each) do
        @plan_stage_instance = create(:plan_stage_instance)
      end

      describe "associations" do
        it "should belong to" do
          @plan_stage_instance.should belong_to(:plan)
          @plan_stage_instance.should belong_to(:plan_stage)
        end

        it "should have many" do
          @plan_stage_instance.should have_many(:constraints)
        end

      end

      describe "validations" do
        it { @plan_stage_instance.should validate_presence_of(:plan_id) }
        it { @plan_stage_instance.should validate_presence_of(:plan_stage_id) }
        it { @plan_stage_instance.should validate_numericality_of(:plan_id).only_integer }
        it { @plan_stage_instance.should validate_numericality_of(:plan_stage_id).only_integer }
        it { @plan_stage_instance.should validate_uniqueness_of(:plan_stage_id).scoped_to(:plan_id) }
      end

      describe "delegations" do
        it { @plan_stage_instance.environment_type.should == @plan_stage_instance.plan_stage.environment_type }
      end

    end

    describe "named scopes" do

      describe "#filter_by_plan_id" do
        it "should return plan_stage_instances for a particular plan_id" do
          plan_stage_instance1 = create(:plan_stage_instance)
          plan_stage_instance2 = create(:plan_stage_instance, :plan_id => plan_stage_instance1.plan_id)
          plan_stage_instance3 = create(:plan_stage_instance)
          PlanStageInstance.all.should include(plan_stage_instance1, plan_stage_instance2, plan_stage_instance3)
          plan_stage_instances = PlanStageInstance.filter_by_plan_id(plan_stage_instance1.plan_id)
          plan_stage_instances.count == 2
          plan_stage_instances.should include(plan_stage_instance1, plan_stage_instance2)
          plan_stage_instances.should_not include(plan_stage_instance3)
          PlanStageInstance.filter_by_plan_id(99999999999).should_not include(plan_stage_instance1, plan_stage_instance2, plan_stage_instance3)
        end
      end

      describe "#filter_by_plan_stage_id" do
        it "should return plan_stage_instances for a particular plan_stage_id" do
          plan_stage_instance1 = create(:plan_stage_instance)
          plan_stage_instance2 = create(:plan_stage_instance, :plan_stage_id => plan_stage_instance1.plan_stage_id)
          plan_stage_instance3 = create(:plan_stage_instance)
          PlanStageInstance.all.should include(plan_stage_instance1, plan_stage_instance2, plan_stage_instance3)
          plan_stage_instances = PlanStageInstance.filter_by_plan_stage_id(plan_stage_instance1.plan_stage_id)
          plan_stage_instances.count == 2
          plan_stage_instances.should include(plan_stage_instance1, plan_stage_instance2)
          plan_stage_instances.should_not include(plan_stage_instance3)
          PlanStageInstance.filter_by_plan_stage_id(99999999999).should_not include(plan_stage_instance1, plan_stage_instance2, plan_stage_instance3)
        end
      end

    end

    describe "should be destroyable if archived and even if not archived" do

      before(:each) do
        @plan_stage_instance = create(:plan_stage_instance)
      end

      it "should allow deletion if archived" do
        current_count = PlanStageInstance.count
        @plan_stage_instance.archive
        @plan_stage_instance.archived?.should be_truthy
        results = @plan_stage_instance.destroy
        results.should be_truthy
        PlanStageInstance.count.should == current_count - 1
      end

      it "should allow deletion if not archived" do
        current_count = PlanStageInstance.count
        @plan_stage_instance.archived?.should be_falsey
        results = @plan_stage_instance.destroy
        results.should be_truthy
        PlanStageInstance.count.should == current_count - 1
      end

    end

  end

  describe "with automatic creation turned on in plan" do

    describe '#filtered' do

      before(:all) do
        PlanStageInstance.delete_all

        @plan_template1 = create(:plan_template)
        @plan_stage1 = create(:plan_stage, :plan_template => @plan_template1)
        @plan_stage2 = create(:plan_stage, :plan_template => @plan_template1)
        @plan_template2 = create(:plan_template)
        @plan_stage3 = create(:plan_stage, :plan_template => @plan_template2)
        @plan1 = create(:plan, :plan_template => @plan_template1)
        @plan2 = create(:plan, :plan_template => @plan_template1)
        @plan3 = create(:plan, :plan_template => @plan_template2)

        @plan_stage_instance1 = @plan1.plan_stage_instances.first
        @plan_stage_instance2 = @plan2.plan_stage_instances.first
        @plan_stage_instance2.archive
        @plan_stage_instance3 = @plan3.plan_stage_instances.first

        @active = PlanStageInstance.unarchived.all
        @inactive = [@plan_stage_instance2]
      end

      after(:all) do
        PlanStageInstance.delete_all
      end

      it_behaves_like 'active/inactive filter'

      describe 'filter by default' do
        subject { described_class.filtered() }
        results = described_class.unarchived
        it { should match_array(results) }
      end

      describe 'filter by plan_id' do
        subject { described_class.filtered(:plan_id => @plan1.id) }
        it { should include(@plan_stage_instance1) }
      end

      describe 'filter by plan_stage_id' do
        subject { described_class.filtered(:plan_stage_id => @plan_stage3.id) }
        it { should include(@plan_stage_instance3) }
      end

    end

    describe "should create constraints" do

      before(:each) do

        # set up environment types
        @environment_type1 = create(:environment_type)
        @environment_type2 = create(:environment_type)
        @environment_type3 = create(:environment_type)
        @environment_type4 = create(:environment_type)

        # set up environments
        @environment1 = create(:environment, :environment_type_id => @environment_type1.id)
        @environment2 = create(:environment, :environment_type_id => @environment_type2.id)
        @environment3 = create(:environment, :environment_type_id => @environment_type3.id)

        # set up the plan with two stages
        @plan_template = create(:plan_template)
        @stage1 = create(:plan_stage, :plan_template => @plan_template, :environment_type_id => @environment_type1.id)
        @stage2 = create(:plan_stage, :plan_template => @plan_template, :environment_type_id => @environment_type2.id)
        @non_matching_stage = create(:plan_stage, :plan_template => @plan_template, :environment_type_id => @environment_type4.id)

        @plan = create(:plan, :plan_template => @plan_template)

        # set up the route with route gates
        @route = create(:route)
        @route_gate1 = create(:route_gate, :route => @route, :environment => @environment1)
        @route_gate2 = create(:route_gate, :route => @route, :environment => @environment2)
        @non_matching_gate = create(:route_gate, :route => @route, :environment => @environment3)

        #create assigned environment
        AssignedEnvironment.create!(:environment_id => @environment1.id, :assigned_app_id => @route.app.assigned_apps.first.id, :role => @user.roles.first)
        AssignedEnvironment.create!(:environment_id => @environment2.id, :assigned_app_id => @route.app.assigned_apps.first.id, :role => @user.roles.first)
        AssignedEnvironment.create!(:environment_id => @environment3.id, :assigned_app_id => @route.app.assigned_apps.first.id, :role => @user.roles.first)

        # create some requests
        @route.app.environments << [@environment1, @environment2, @environment3]
        @request1 = create(:request, apps: [@route.app], environment_id: @environment1.id)
        @request2 = create(:request, apps: [@route.app], environment_id: @environment2.id)
        @request3 = create(:request, apps: [@route.app], environment_id: @environment3.id)

        # and assign them to a plan, and let the validations begin
        @plan_member1 = create(:plan_member, plan: @plan, stage: @stage1, request: @request1)
        @plan_member2 = create(:plan_member, plan: @plan, stage: @stage2, request: @request2)
        @plan_member3 = create(:plan_member, plan: @plan, stage: @stage2, request: @request3)

      end

      it "finds or creates constraints for all plan_stage instances and with matching route_gates by environment type" do
        psi1 = @plan.plan_stage_instances.filter_by_plan_stage_id(@stage1.id).first
        expect { psi1.create_constraints_for_route_id(@route.id) }.to change { Constraint.count }.by(1)
        psi1.constraints.count.should == 1
        psi1.constraints.first.constrainable_type.should == 'RouteGate'
        psi1.constraints.first.constrainable_id.should == @route_gate1.id
        psi2 = @plan.plan_stage_instances.filter_by_plan_stage_id(@stage2.id).first
        expect { psi2.create_constraints_for_route_id(@route.id) }.to change { Constraint.count }.by(1)
        psi2.constraints.count.should == 1
        psi2.constraints.first.constrainable_type.should == 'RouteGate'
        psi2.constraints.first.constrainable_id.should == @route_gate2.id
      end

      it "should not create constraints for route gates with non-matching route_gates by environment type" do
        psi1 = @plan.plan_stage_instances.filter_by_plan_stage_id(@stage1.id).first
        expect { psi1.create_constraints_for_route_id(@non_matching_gate.id) }.to_not change { Constraint.count }.by(1)
        Constraint.filter_by_constraint(:id => @non_matching_gate.id, :type => 'RouteGate').should be_empty
      end

      it "should not create constraints for plan_stages with non-matching route_gates by environment type" do
        psi = PlanStageInstance.filter_by_plan_stage_id(@non_matching_stage.id).first
        expect { psi.create_constraints_for_route_id(@non_matching_gate.id) }.to_not change { Constraint.count }.by(1)
        Constraint.filter_by_governor(:id => psi.id, :type => 'PlanStageInstance').should be_empty
      end

      it "should not create constraints for a route with no gates" do

        @route_with_no_gates = create(:route)

        psi1 = @plan.plan_stage_instances.filter_by_plan_stage_id(@stage1.id).first

        expect { psi1.create_constraints_for_route_id(@route_with_no_gates.id) }.to_not change { Constraint.count }.by(1)
        # expect { create(:plan_route, :plan => @plan, :route => @route_with_no_gates) }.to_not change{ Constraint.count }.by(1)

      end

      it "should return requests that match its plan and plan_stage" do
        psi1 = @plan.plan_stage_instances.filter_by_plan_stage_id(@stage1.id).first
        requests = psi1.requests
        requests.should include(@request1)
        requests.should_not include(@request2, @request3)
      end

      it "should return available environments for a request by constraint" do
        @plan.plan_routes.create(:route_id => @route.id)
        psi2 = @plan.plan_stage_instances.filter_by_plan_stage_id(@stage2.id).first
        environments = psi2.allowable_environments_for_request(@request1)
        environments.should include(@environment2)
      end

    end
  end
end
