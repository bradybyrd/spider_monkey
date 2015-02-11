################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe Constraint do
  before(:each) { User.current_user = create(:old_user)}

  describe "validations and normalizations" do
    before(:each) do
      @constraint = create(:constraint)
    end

    describe "associations" do
      it "should belong to" do
        @constraint.should belong_to(:constrainable)
        @constraint.should belong_to(:governable)
      end
    end

    describe "validations" do
      it { @constraint.should validate_numericality_of(:constrainable_id).only_integer }
      it { @constraint.should validate_numericality_of(:governable_id).only_integer }
      it { @constraint.should validate_presence_of(:constrainable_id) }
      it { @constraint.should validate_presence_of(:constrainable_type) }
      it { @constraint.should validate_presence_of(:governable_id) }
      it { @constraint.should validate_presence_of(:governable_type) }
    end

    describe "custom validation" do

      before(:each) do
        # without this, it is difficult to get a plan assigned without two copies
        # of the plan stage instance
        Plan.skip_callback(:create, :after, :build_plan_stage_instances)
      end

      after(:each) do
        # without this, it is difficult to get a plan assigned without two copies
        # of the plan stage instance
        Plan.set_callback(:create, :after, :build_plan_stage_instances)
      end

      it "should prevent illegal constraints on a plan stage instance" do
        @plan_stage_instance = create(:plan_stage_instance)
        @phase = create(:phase)
        @constraint.governable = @plan_stage_instance
        @constraint.constrainable = @phase
        @constraint.should_not be_valid
        @constraint.errors.full_messages.should include("Governable plan stage instance cannot be constrained by a Phase")
      end

      it "should prevent non-matching route gates on a plan stage instances with strict environment types" do
        @environment_type = create(:environment_type, strict: true)
        @plan_stage = create(:plan_stage, :environment_type_id => @environment_type.id)
        @plan_stage_instance = create(:plan_stage_instance, :plan_stage => @plan_stage)
        @route_gate = create(:route_gate)
        @constraint.governable = @plan_stage_instance
        @constraint.constrainable =  @route_gate
        @constraint.should_not be_valid
        @constraint.errors.full_messages.should include("Governable plan stage instance of STRICT environment \
type #{ @plan_stage_instance.environment_type.name } cannot be constrained by a RouteGate of environment \
type #{ @route_gate.try(:environment_type).try(:name) || 'None' }")
      end

      it "should allow non-matching route gates on a plan stage instances with non-strict environment types" do
        @environment_type = create(:environment_type, strict: false)
        @plan_stage = create(:plan_stage, :environment_type_id => @environment_type.id)
        @plan_stage_instance = create(:plan_stage_instance, :plan_stage => @plan_stage)
        @route_gate = create(:route_gate)
        @constraint.governable = @plan_stage_instance
        @constraint.constrainable =  @route_gate
        @constraint.should be_valid
      end

    end

  end

  describe "named scopes" do

    describe "#filter_by_governor" do
      it "should return constraints for a particular governor id and type" do
        constraint1 = create(:constraint)
        constraint2 = create(:constraint, :governable => constraint1.governable)
        constraint3 = create(:constraint)
        Constraint.all.should include(constraint1, constraint2, constraint3)
        constraints = Constraint.filter_by_governor({:id => constraint1.governable.id, :type => 'PlanStage'})
        constraints.count == 2
        constraints.should include(constraint1, constraint2)
        constraints.should_not include(constraint3)
        Constraint.filter_by_governor({:id => 99999999999, :type => 'PlanStage'}).should_not include(constraint1, constraint2, constraint3)
      end
    end

    describe "#filter_by_constraint" do
      it "should return constraints for a particular constraint id and type" do
        constraint1 = create(:constraint)
        constraint2 = create(:constraint, :constrainable => constraint1.constrainable)
        constraint3 = create(:constraint)
        Constraint.all.should include(constraint1, constraint2, constraint3)
        constraints = Constraint.filter_by_constraint({:id => constraint1.constrainable.id, :type => 'RouteGate'})
        constraints.count == 2
        constraints.should include(constraint1, constraint2)
        constraints.should_not include(constraint3)
        Constraint.filter_by_constraint({:id => 99999999999, :type => 'RouteGate'}).should_not include(constraint1, constraint2, constraint3)
      end
    end

    describe "#filter_by_route_id" do
      it "should return constraints for a particular route_id" do
        route_gate = create(:route_gate)
        route_gate2 = create(:route_gate, :route => route_gate.route)
        constraint1 = create(:constraint, :constrainable => route_gate)
        constraint2 = create(:constraint, :constrainable => route_gate2)
        constraint3 = create(:constraint)
        Constraint.all.should include(constraint1, constraint2, constraint3)
        constraints = Constraint.filter_by_route_id(route_gate.route_id)
        constraints.count == 2
        constraints.should include(constraint1, constraint2)
        constraints.should_not include(constraint3)
        Constraint.filter_by_route_id(99999999999).should_not include(constraint1, constraint2, constraint3)
      end
    end

    describe '#filter_by_constrainable_type' do
      it 'should return constraints for a particular constrainable type' do
        # create a dummy object to use as a constraint (non-matching)
        @phase = create(:phase)
        route_gate = create(:route_gate)
        route_gate2 = create(:route_gate, :route => route_gate.route)
        constraint1 = create(:constraint, :constrainable => route_gate)
        constraint2 = create(:constraint, :constrainable => route_gate2)
        # just mock up a non-matching constraint for now since none have been added to the real system
        constraint3 = create(:constraint, :constrainable => @phase)
        Constraint.all.should include(constraint1, constraint2, constraint3)
        constraints = Constraint.filter_by_constrainable_type('RouteGate')
        constraints.count == 2
        constraints.should include(constraint1, constraint2)
        constraints.should_not include(constraint3)
        Constraint.filter_by_constrainable_type('99999999999').should_not include(constraint1, constraint2, constraint3)
      end
    end

  end

  describe '#filtered' do

    before(:all) do
      # without this, it is difficult to get a plan assigned without two copies
      # of the plan stage instance
      Plan.skip_callback(:create, :after, :build_plan_stage_instances)

      Constraint.delete_all
      User.current_user = create(:old_user)

      @p_s_i_1 = create(:plan_stage_instance)
      @p_s_i_2 = create(:plan_stage_instance)
      @p_s_i_3 = create(:plan_stage_instance)

      @rg_1 = create(:route_gate)
      @rg_2 = create(:route_gate)

      @c_11 = create(:constraint, :constrainable => @rg_1, :governable => @p_s_i_1)
      @c_12 = create(:constraint, :constrainable => @rg_1, :governable => @p_s_i_2)
      @c_13 = create(:constraint, :constrainable => @rg_1, :governable => @p_s_i_3, :active => false)

      @c_21 = create(:constraint, :constrainable => @rg_2, :governable => @p_s_i_1, :active => false)
      @c_22 = create(:constraint, :constrainable => @rg_2, :governable => @p_s_i_2)
      @c_23 = create(:constraint, :constrainable => @rg_2, :governable => @p_s_i_3)

      @active = [@c_11, @c_12, @c_22, @c_23]
      @inactive = [@c_13, @c_21]
      @filter_flags = [:active, :inactive]
    end

    after(:all) do
      Constraint.delete_all
      PlanStageInstance.delete([@p_s_i_1, @p_s_i_2, @p_s_i_3])
      RouteGate.delete([@rg_1, @rg_2])
      # without this, it is difficult to get a plan assigned without two copies
      # of the plan stage instance
      Plan.set_callback(:create, :after, :build_plan_stage_instances)
    end

    it_behaves_like 'active/inactive filter'

    describe 'filter by constrainable' do
      subject { described_class.filtered({:constraint => {:id => @rg_1.id, :type => 'RouteGate'}}) }
      it { should match_array([@c_11, @c_12]) }
    end

    describe 'filter by governable' do
      subject { described_class.filtered({:governor => {:id => @p_s_i_2.id, :type => 'PlanStageInstance'}}) }
      it { should match_array([@c_12, @c_22]) }
    end

    describe 'filter with empty result' do
      subject { described_class.filtered({:constraint => {:id => @rg_1.id, :type => 'RouteGate'},
                                          :governor => {:id => @p_s_i_3.id, :type => 'PlanStageInstance'}}) }
      it { should be_empty }
    end

    describe 'filter by constrainable, governable' do
      subject { described_class.filtered({:constraint => {:id => @rg_1.id, :type => 'RouteGate'},
                                          :governor => {:id => @p_s_i_3.id, :type => 'PlanStageInstance'},
                                          :inactive => true}) }
      it { should match_array([@c_13]) }
    end
  end

end
