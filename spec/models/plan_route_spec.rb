################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe PlanRoute do

  describe "validations and normalizations" do
    before(:each) do
      @plan_route = create(:plan_route)
    end

    describe "associations" do
      it "should belong to" do
        @plan_route.should belong_to(:plan)
        @plan_route.should belong_to(:route)
      end

    end

    describe "validations" do
      it { @plan_route.should validate_presence_of(:plan_id) }
      it { @plan_route.should validate_presence_of(:route_id) }
      it { @plan_route.should validate_numericality_of(:plan_id).only_integer }
      it { @plan_route.should validate_numericality_of(:plan_id).only_integer }
      it { @plan_route.should validate_uniqueness_of(:route_id).scoped_to(:plan_id) }
    end

    describe 'custom validations' do

      it 'should not be valid if application already has a route for this plan' do
        route = create(:route, :app_id => @plan_route.route_app_id)
        bad_plan_route = build(:plan_route, :plan => @plan_route.plan, :route => route)
        bad_plan_route.should_not be_valid
        bad_plan_route.errors.full_messages.should include('Route for app already assigned to plan')
      end
    end

  end

  describe "named scopes" do

    describe "#in_route_name_order" do
      it "should return all plan_routes in route name order" do
        route1 = create(:route, :name => 'PPPPP')
        route2 = create(:route, :name => 'ZZZZZ')
        route3 = create(:route, :name => 'AAAAA')
        plan_route1 = create(:plan_route, :route => route1)
        plan_route2 = create(:plan_route, :route => route2)
        plan_route3 = create(:plan_route, :route => route3)
        PlanRoute.all.should include(plan_route1, plan_route2, plan_route3)
        results = PlanRoute.in_route_name_order
        results.first.should == plan_route3
        results.last.should == plan_route2
      end
    end

    describe "#in_app_name_order" do
      it "should return all plan_routes in app name order" do
        app1 = create(:app, :name => 'PPPPP')
        app2 = create(:app, :name => 'ZZZZZ')
        app3 = create(:app, :name => 'AAAAA')
        route1 = create(:route, :app => app1)
        route2 = create(:route, :app => app2)
        route3 = create(:route, :app => app3)
        plan_route1 = create(:plan_route, :route => route1)
        plan_route2 = create(:plan_route, :route => route2)
        plan_route3 = create(:plan_route, :route => route3)
        PlanRoute.all.should include(plan_route1, plan_route2, plan_route3)
        results = PlanRoute.in_app_name_order
        results.first.should == plan_route3
        results.last.should == plan_route2
      end
    end

    describe "#filter_by_route_id" do

      it "should return routes for a particular route_id" do
        plan_route1 = create(:plan_route)
        plan_route2 = create(:plan_route, :route => plan_route1.route)
        plan_route3 = create(:plan_route)
        PlanRoute.all.should include(plan_route1, plan_route2, plan_route3)
        plan_routes = PlanRoute.filter_by_route_id(plan_route1.route.id)
        plan_routes.count == 2
        plan_routes.should include(plan_route1, plan_route2)
        plan_routes.should_not include(plan_route3)
        PlanRoute.filter_by_route_id(99999999999).should_not include(plan_route1, plan_route2, plan_route3)
      end
    end

    describe "#filter_by_plan_id" do
      it "should return routes for a particular plan_id" do
        plan_route1 = create(:plan_route)
        plan_route2 = create(:plan_route, :plan => plan_route1.plan)
        plan_route3 = create(:plan_route)
        PlanRoute.all.should include(plan_route1, plan_route2, plan_route3)
        plan_routes = PlanRoute.filter_by_plan_id(plan_route1.plan.id)
        plan_routes.count == 2
        plan_routes.should include(plan_route1, plan_route2)
        plan_routes.should_not include(plan_route3)
        PlanRoute.filter_by_plan_id(99999999999).should_not include(plan_route1, plan_route2, plan_route3)
      end
    end

  end

  describe '#filtered' do

    before(:all) do
      User.current_user = create(:old_user)
      @plan_1 = create(:plan)
      @plan_2 = create(:plan)

      @route_1 = create(:route)
      @route_2 = create(:route)

      @pr_11 = create(:plan_route, :plan => @plan_1, :route => @route_1)
      @pr_12 = create(:plan_route, :plan => @plan_1, :route => @route_2)
      @pr_21 = create(:plan_route, :plan => @plan_2, :route => @route_1)
      @pr_22 = create(:plan_route, :plan => @plan_2, :route => @route_2)
    end

    describe 'filter by default' do
      subject { described_class.filtered() }
      it { should match_array([@pr_11, @pr_12, @pr_21, @pr_22]) }
    end

    describe 'filter by plan_id' do
      subject { described_class.filtered(:plan_id => @plan_1.id) }
      it { should match_array([@pr_11, @pr_12]) }
    end

    describe 'filter by route_id' do
      subject { described_class.filtered(:route_id => @route_2.id) }
      it { should match_array([@pr_12, @pr_22]) }
    end

    describe 'filter by plan_id, route_id' do
      subject { described_class.filtered(:plan_id => @plan_2, :route_id => @route_1.id) }
      it { should match_array([@pr_21]) }
    end
  end

  describe "has post-create hooks that" do

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

      # finally create the plan route and let the hooks fly
      @plan_route = create(:plan_route, :plan => @plan, :route => @route)
    end

    it "finds or creates constraints for all plan_stage instances and with matching route_gates by environment type" do
      psi1 = @plan.plan_stage_instances.filter_by_plan_stage_id(@stage1.id).first
      psi1.constraints.count.should == 1
      psi1.constraints.first.constrainable_type.should == 'RouteGate'
      psi1.constraints.first.constrainable_id.should == @route_gate1.id
      psi2 = @plan.plan_stage_instances.filter_by_plan_stage_id(@stage2.id).first
      psi2.constraints.count.should == 1
      psi2.constraints.first.constrainable_type.should == 'RouteGate'
      psi2.constraints.first.constrainable_id.should == @route_gate2.id
    end

    it "should not create constraints for route gates with non-matching route_gates by environment type" do
      Constraint.filter_by_constraint(:id => @non_matching_gate.id, :type => 'RouteGate').should be_empty
    end

    it "should not create constraints for plan_stages with non-matching route_gates by environment type" do
      psi = PlanStageInstance.filter_by_plan_stage_id(@non_matching_stage.id).first
      Constraint.filter_by_governor(:id => psi.id, :type => 'PlanStageInstance').should be_empty
    end

  end

  describe "should provide convenience methods" do

    before(:each) do
      @plan_route = build(:plan_route)
    end

    it "should provide the application name from routes" do
      @plan_route.route_app_name.should == @plan_route.route.app.name
    end

    it "should provide the route name from routes" do
      @plan_route.route_name.should == @plan_route.route.name
    end

    it "should provide the environments list from routes" do
      @plan_route.route_environments_list.should == @plan_route.route.environments_list
    end

    describe 'should provide convenience methods for plans' do

      before(:each) do
        @plan_route1 = create(:plan_route, :route => @plan_route.route)
        @plan_route2 = create(:plan_route, :route => @plan_route.route)
        @plan_route3 = create(:plan_route)
        @plan = @plan_route.plan
        @other_plan1 = @plan_route1.plan
        @other_plan2 = @plan_route2.plan
        @not_included_plan = @plan_route3.plan
      end

      it 'should provide a string listing of other active plans collection when passed a plan' do
        results = @plan_route.other_active_plans_list
        results.should == [@other_plan1.name, @other_plan2.name].sort.to_sentence
      end

      it 'should return an empty string when a route has not plans' do
        results = @plan_route3.other_active_plans_list
        results.should == 'None'
      end
    end

    describe 'should provide convenience methods for unassigned route gates' do

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

        # finally create the plan route and let the hooks fly
        @plan_route = create(:plan_route, :plan => @plan, :route => @route)
      end

      it 'should provide a list of non_matching gates' do
        results = @plan_route.unassigned_route_gates
        results.should include @non_matching_gate
        results.should_not include(@route_gate1, @route_gate2)
      end

    end
  end

end
