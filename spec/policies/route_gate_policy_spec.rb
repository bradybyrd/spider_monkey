################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe RouteGatePolicy do

  before :each do

    @double_phase = double('Phase')
    @double_phase.stub(:class) { Phase }

    @double_constraint = double('Constraint')
    @double_constraint.stub(:constrainable_type) { 'RouteGate' }
    @double_constraint.stub(:constrainable) { @double_route_gate }

    @app = double('App')
    @app.stub(:id) { 1 }
    @app.stub(:name) { 'Mocked App' }

    @environment = double('Environment')
    @environment.stub(:id) { 1 }
    @environment.stub(:name) { 'Mocked Environment' }

    @double_request = double('Request')
    @double_request.stub(:id) { true }
    @double_request.stub(:apps) { [@app] }
    @double_request.stub(:app_ids) { [@app.id] }
    @double_request.stub(:app_name) { [@app.name] }
    @double_request.stub(:environment) { @environment }
    @double_request.stub(:environment_id) { @environment.id }
    @double_request.stub(:environment_name) { @environment.name }
    @double_request.stub(:number) { 100001 }

    @double_governable = double('PlanStageInstance')
    @double_governable.stub(:class) { PlanStageInstance }
    @double_governable.stub(:requests) { [@double_request] }

    @invalid_constraint = double('Constraint')
    @invalid_constraint.stub(:constrainable_type) { 'Phase' }
    @invalid_constraint.stub(:constrainable) { @double_phase }


    @double_route_gate = double('RouteGate')
    @double_route_gate.stub(:route_app_id) { @app.id }
    @double_route_gate.stub(:route_app_name) { @app.name }
    @double_route_gate.stub(:environment_id) { @environment.id }
    @double_route_gate.stub(:environment) { @environment }
    # start with relaxed strictness
    @double_route_gate.stub(:strict?) { false }
    @double_governable.stub(:strict?) { false }

    @rgp = RouteGatePolicy.new(@double_governable, [@double_constraint])
    @invalid_governable_rgp = RouteGatePolicy.new(@double_phase, [@double_constraint])
    @invalid_constraint_rgp = RouteGatePolicy.new(@double_governable, [@invalid_constraint])

  end

  it 'should provide access to the governable object' do
    @rgp.governable.should == @double_governable
  end

  it 'should provide access to the constraints object' do
    @rgp.constraints.should == [@double_constraint]
  end

  it 'should reject unsupported governable objects' do
    actual_outcome = @invalid_governable_rgp.validate
    actual_outcome.map(&:passed).first.should == false
    actual_outcome.map(&:message).first.should == 'Route Gate policy cannot be applied to objects of type Phase'
  end

  it 'should reject unsupported constraint objects' do
    actual_outcome = @invalid_constraint_rgp.validate
    actual_outcome.map(&:passed).first.should == false
    actual_outcome.map(&:message).first.should == 'Route Gate policy cannot enforce constraints of type Phase'
  end

  it 'should reject strict environment mismatches' do
    @double_route_gate.stub(:strict?) { true }
    @double_governable.stub(:strict?) { false }
    @double_route_gate.stub(:environment_type) { build(:environment_type) }
    @double_governable.stub(:environment_type) { build(:environment_type) }
    actual_outcome = @rgp.validate
    actual_outcome.map(&:passed).first.should == false
    actual_outcome.map(&:message).first.should == 'Governable and constrainable environment types must match if one is strict'
  end

  it 'should return an empty array when all requests are valid' do
    @rgp.validate.should be_empty
  end

  it 'should return an error message if non-matching request environment is in plan stage instance' do
    @bad_environment = double('Environment')
    @bad_environment.stub(:id) { 2 }
    @bad_environment.stub(:name) { 'Bad Environment' }
    @double_request.stub(:environment) { @bad_environment }
    @double_request.stub(:environment_id) { @bad_environment.id }
    @double_request.stub(:environment_name) { @bad_environment.name }

    actual_outcome = @rgp.validate
    actual_outcome.map(&:passed).first.should == false
    actual_outcome.map(&:message).first.should == 'Bad Environment for Request 100001 is not among routed environments for Mocked App: Mocked Environment'
  end

  it 'should return an error message if non-matching request application is in plan stage instance' do
    @bad_app = double('App')
    @bad_app.stub(:id) { 2 }
    @bad_app.stub(:name) { 'Bad App' }
    @double_request.stub(:apps) { [@bad_app] }
    @double_request.stub(:app_ids) { [@bad_app.id] }
    @double_request.stub(:app_name) { [@bad_app.name] }

    actual_outcome = @rgp.validate
    actual_outcome.map(&:passed).first.should == false
    actual_outcome.map(&:message).first.should == 'Mocked Environment for Request 100001 is not among routed environments for Bad App: None'
  end

  it 'should return an error message if non-matching request application and environment is in plan stage instance' do
    @bad_app = double('App')
    @bad_app.stub(:id) { 2 }
    @bad_app.stub(:name) { 'Bad App' }
    @double_request.stub(:apps) { [@bad_app] }
    @double_request.stub(:app_ids) { [@bad_app.id] }
    @double_request.stub(:app_name) { [@bad_app.name] }
    @bad_environment = double('Environment')
    @bad_environment.stub(:id) { 2 }
    @bad_environment.stub(:name) { 'Bad Environment' }
    @double_request.stub(:environment) { @bad_environment }
    @double_request.stub(:environment_id) { @bad_environment.id }
    @double_request.stub(:environment_name) { @bad_environment.name }

    actual_outcome = @rgp.validate
    actual_outcome.map(&:passed).first.should == false
    actual_outcome.map(&:message).first.should == 'Bad Environment for Request 100001 is not among routed environments for Bad App: None'
  end


  it 'should handle multiple violations at once' do
    @bad_app = double('App')
    @bad_app.stub(:id) { 2 }
    @bad_app.stub(:name) { 'Bad App' }
    @double_request.stub(:apps) { [@bad_app] }
    @double_request.stub(:app_ids) { [@bad_app.id] }
    @double_request.stub(:app_name) { [@bad_app.name] }
    @bad_environment = double('Environment')
    @bad_environment.stub(:id) { 2 }
    @bad_environment.stub(:name) { 'Bad Environment' }
    @double_request.stub(:environment) { @bad_environment }
    @double_request.stub(:environment_id) { @bad_environment.id }
    @double_request.stub(:environment_name) { @bad_environment.name }

    @double_request2 = double('Request')
    @double_request2.stub(:id) { true }
    @double_request2.stub(:apps) { [@bad_app] }
    @double_request2.stub(:app_ids) { [@bad_app.id] }
    @double_request2.stub(:app_name) { [@bad_app.name] }
    @double_request2.stub(:environment) { @environment }
    @double_request2.stub(:environment_id) { @environment.id }
    @double_request2.stub(:environment_name) { @environment.name }
    @double_request2.stub(:number) { 100002 }


    @double_governable.stub(:requests) { [@double_request,@double_request2] }

    actual_outcome = @rgp.validate
    actual_outcome.map(&:passed).first.should == false
    actual_outcome.map(&:passed).last.should == false
    actual_outcome.map(&:message).first.should == 'Bad Environment for Request 100001 is not among routed environments for Bad App: None'
    actual_outcome.map(&:message).last.should == 'Mocked Environment for Request 100002 is not among routed environments for Bad App: None'
  end
end

