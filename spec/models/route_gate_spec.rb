################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe RouteGate do


  describe "validations and normalizations" do
    before(:each) do
      @route_gate = create(:route_gate)
    end

    describe "associations" do
      it "should belong to" do
        @route_gate.should belong_to(:route)
        @route_gate.should belong_to(:environment)
      end

      it "should have many" do
        @route_gate.should have_many(:constraints)
      end

    end

    describe "validations" do
      it { @route_gate.should ensure_length_of(:description).is_at_most(255) }
      it { @route_gate.should validate_uniqueness_of(:environment_id).scoped_to(:route_id) }
    end

    describe "attribute normalizations" do
      it { should normalize_attribute(:description).from('  Hello  ').to('Hello') }
    end

  end

  describe "named scopes" do

    describe "#in_order" do
      it "should return all routes in position order" do
        route_gate1 = create(:route_gate, :position => 2)
        route_gate2 = create(:route_gate, :route => route_gate1.route, :position => 3)
        route_gate3 = create(:route_gate, :route => route_gate1.route, :position => 1)
        RouteGate.all.should include(route_gate1, route_gate2, route_gate3)
        RouteGate.in_order.first.should == route_gate3
        RouteGate.in_order.last.should == route_gate2
      end
    end

    describe "#filter_by_route_id" do
      it "should return routes for a particular route_id" do
        route_gate1 = create(:route_gate)
        route_gate2 = create(:route_gate, :route => route_gate1.route)
        route_gate3 = create(:route_gate)
        RouteGate.all.should include(route_gate1, route_gate2, route_gate3)
        route_gates = RouteGate.filter_by_route_id(route_gate1.route.id)
        route_gates.count == 2
        route_gates.should include(route_gate1, route_gate2)
        route_gates.should_not include(route_gate3)
        RouteGate.filter_by_route_id(99999999999).should_not include(route_gate1, route_gate2, route_gate3)
      end
    end

    describe "#filter_by_environment_id" do
      it "should return routes for a particular environment_id" do
        route_gate1 = create(:route_gate)
        route_gate2 = create(:route_gate, :environment => route_gate1.environment)
        route_gate3 = create(:route_gate)
        RouteGate.all.should include(route_gate1, route_gate2, route_gate3)
        route_gates = RouteGate.filter_by_environment_id(route_gate1.environment.id)
        route_gates.count == 2
        route_gates.should include(route_gate1, route_gate2)
        route_gates.should_not include(route_gate3)
        RouteGate.filter_by_environment_id(99999999999).should_not include(route_gate1, route_gate2, route_gate3)
      end
    end

  end

  describe "on destroy" do

    before(:each) do
      @plan = create(:plan)
      @route = create(:route)
      @route.plans << @plan
      @route_gate1 = create(:route_gate, route: @route)
      @route_gate2 = create(:route_gate)
    end

    it "should not allow deletion if route has a plan" do
      current_count = RouteGate.count
      @route_gate1.route.plans.should include(@plan)
      results = @route_gate1.destroy
      results.should be_falsey
      RouteGate.count.should == current_count
    end

    it "should allow deletion if route has no plans" do
      current_count = RouteGate.count
      @route_gate2.route.plans.should_not include(@plan)
      results = @route_gate2.destroy
      results.should be_truthy
      RouteGate.count.should == current_count - 1
    end

  end

  describe "custom methods" do

    before(:each) do
      @route_gate = create(:route_gate)
      5.times { create(:route_gate, :route => @route_gate.route) }
    end


    it "should insert route gate at a particular point" do
      @route_gate.update_attributes(:insertion_point => 3)
      @route_gate.insertion_point.should == 3
    end

    it "should return the position when returning insertion point" do
      @route_gate.insertion_point.should == @route_gate.position
    end

  end

  describe "convenience method for eligible plan stage instances" do

    before(:each) do
      @strict_environment_type = create(:environment_type, :strict => true)
      @strict_environment_type_2 = create(:environment_type, :strict => true)
      @permissive_environment_type = create(:environment_type, :strict => false)
      @plan_stage = create(:plan_stage)
      @plan = create(:plan, plan_template: @plan_stage.plan_template)
      @plan_stage_instance = @plan.plan_stage_instances.try(:first)
      @plan_route = create(:plan_route, :plan => @plan)
      @route_gate = create(:route_gate, :route => @plan_route.route)
    end

    it "should return a list of eligible plan_stage_instances when given a plan_id" do
      @plan_stage.update_attributes(environment_type: @permissive_environment_type)
      @route_gate.environment.update_attributes(environment_type: @permissive_environment_type)
      @route_gate.eligible_plan_stage_instances_for_plan_id(@plan.id).should include(@plan_stage_instance)
    end

    it "should return eligible plan_stage_instances if environment and plan stage have the same strict environment type given a plan_id" do
      @plan_stage.update_attributes(environment_type: @strict_environment_type)
      @route_gate.environment.update_attributes(environment_type: @strict_environment_type)
      @route_gate.eligible_plan_stage_instances_for_plan_id(@plan.id).should include(@plan_stage_instance)
    end

    it "should not return plan_stage_instances if environment_types are both strict but different given a plan_id" do
      @plan_stage.update_attributes(environment_type: @strict_environment_type)
      @route_gate.environment.update_attributes(environment_type: @strict_environment_type_2)
      @route_gate.eligible_plan_stage_instances_for_plan_id(@plan.id).should_not include(@plan_stage_instance)
    end

    it "should not return plan_stage_instances if environment_types are not both strict given a plan_id" do
      @plan_stage.update_attributes(environment_type_id: @permissive_environment_type.id)
      @route_gate.environment.update_attributes(environment_type_id: @strict_environment_type.id)
      @route_gate.eligible_plan_stage_instances_for_plan_id(@plan.id).should_not include(@plan_stage_instance)
    end

    it "should not return plan_stage_instances if a constraint for it already exists for that plan_id" do
      @plan_stage.update_attributes(environment_type: @permissive_environment_type)
      @route_gate.environment.update_attributes(environment_type: @permissive_environment_type)
      constraint = create(:constraint,
                          governable: @plan_stage_instance,
                          constrainable: @route_gate)
      @route_gate.eligible_plan_stage_instances_for_plan_id(@plan.id).should_not include(@plan_stage_instance)
    end

    it "should print out a constrainable label good for UI displays" do
      @route_gate.constrainable_label.should == "#{ @route_gate.try(:route_app).try(:name)} : #{ @route_gate.try(:route).try(:name)} : #{ @route_gate.try(:environment).try(:name)}"
    end

    it 'ignores plan stage instances w/o plan stage' do
      PlanStageInstance.any_instance.stub(:plan_stage).and_return(nil)
      @plan_stage.update_attributes(environment_type: @permissive_environment_type)
      @route_gate.environment.update_attributes(environment_type: @permissive_environment_type)
      @route_gate.eligible_plan_stage_instances_for_plan_id(@plan.id).should_not include(@plan_stage_instance)
    end

  end

  describe '#filtered' do

    before(:all) do
      RouteGate.delete_all
      User.current_user = create(:old_user)
      @route_1 = create(:route)
      @route_2 = create(:route)

      @env_1 = create(:environment)
      @env_2 = create(:environment)

      @rg_11 = create(:route_gate, :environment => @env_1, :route => @route_1)
      @rg_12 = create(:route_gate, :environment => @env_1, :route => @route_2)
      @rg_21 = create(:route_gate, :environment => @env_2, :route => @route_1)
      @rg_22 = create(:route_gate, :environment => @env_2, :route => @route_2)
    end

    after(:all) do
      RouteGate.delete_all
      Route.delete([@route_1, @route_2])
      Environment.delete([@env_1, @env_2])
    end

    describe 'filter by default' do
      subject { described_class.filtered() }
      it { should match_array([@rg_11, @rg_12, @rg_21, @rg_22]) }
    end

    describe 'filter by environment_id' do
      subject { described_class.filtered(:environment_id => @env_1.id) }
      it { should match_array([@rg_11, @rg_12]) }
    end

    describe 'filter by route_id' do
      subject { described_class.filtered(:route_id => @route_2.id) }
      it { should match_array([@rg_12, @rg_22]) }
    end

    describe 'filter by environment_id, route_id' do
      subject { described_class.filtered(:environment_id => @env_2, :route_id => @route_1.id) }
      it { should match_array([@rg_21]) }
    end
  end

end

