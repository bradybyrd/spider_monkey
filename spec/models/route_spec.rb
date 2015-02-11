################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe Route do

  describe "validations and normalizations" do
    before(:each) do
      @app = create(:app)
      @route = create(:route, app: @app)
    end

    describe "associations" do
      it "should have many" do
        @route.should have_many(:route_gates)
        @route.should have_many(:environments)
        @route.should have_many(:plan_routes)
        @route.should have_many(:plans)
      end
      it "should belong to" do
        @route.should belong_to(:app)
      end
    end

    describe "validations" do
      it { @route.should validate_presence_of(:name) }
      it do
        pending "validate_uniqueness_of create route without scoped_to app"
        @route.should validate_uniqueness_of(:name).scoped_to(:app_id)
      end
      it { @route.should ensure_length_of(:name).is_at_least(2) }
      it { @route.should ensure_length_of(:name).is_at_most(255) }
      it { @route.should ensure_length_of(:description).is_at_most(255) }
      it { @route.should ensure_inclusion_of(:route_type).in_array(Route::ROUTE_TYPES) }
    end

    describe "attribute normalizations" do
      it { should normalize_attribute(:name).from('  Hello  ').to('Hello') }
      it { should normalize_attribute(:description).from('  Hello  ').to('Hello') }
    end

    describe "custom validations" do
      it "should not allow editing of the default route" do
        @default_route = Route.where(:name => '[default]').first
        @default_route.description = 'Hello kitty'
        @default_route.should_not be_valid
        @default_route.errors.messages[:name].should include('is [default]. This system route cannot be modified.')
      end
    end

  end

  describe "named scopes" do

    describe "#not_default" do
      it "should return all routes except the deault route" do
        route1 = create(:route, :name => 'PPPPP')
        Route.all.count.should == 2
        Route.not_default.should match_array([route1])
      end
    end

    describe "#in_name_order" do
      it "should return all routes in name order" do
        route1 = create(:route, :name => 'PPPPP')
        route2 = create(:route, :name => 'ZZZZZ')
        route3 = create(:route, :name => 'AAAAA')
        Route.all.should include(route1, route2, route3)
        Route.not_default.in_name_order.first.should == route3
        Route.not_default.in_name_order.last.should == route2
      end
    end

    describe "#filter_by_name" do
      it "should return routes for a particular name case insensitive" do
        route1 = create(:route, :name => 'PPPPP')
        route2 = create(:route, :name => 'ZZZZZ')
        Route.all.should include(route1, route2)
        routes = Route.filter_by_name('PPPPP')
        routes.count == 1
        routes.should include(route1)
        routes.should_not include(route2)
        # now try lower case which SHOULD NOT work because the names are case sensitive
        Route.filter_by_name('ppppp').should_not include(route1)
        Route.filter_by_name('TOTALLY NOT INCLUDED').should_not include(route1, route2)
      end
    end

    describe "#filter_by_app_id" do
      it "should return routes for a particular app_id" do
        app = create(:app)
        route1 = create(:route, :app => app)
        route2 = create(:route)
        Route.all.should include(route1, route2)
        routes = Route.filter_by_app_id(app.id)
        routes.count == 1
        routes.should include(route1)
        routes.should_not include(route2)
        Route.filter_by_app_id(99999999999).should_not include(route1, route2)
      end
    end

    describe "#filter_by_environment_id" do
      it "should return routes for a particular environment_id" do
        route1 = create(:route)
        route2 = create(:route)
        route3 = create(:route)
        route_gate1 = create(:route_gate, route_id: route1.id)
        route_gate2 = create(:route_gate, route_id: route2.id)
        route_gate3 = create(:route_gate, route_id: route3.id, environment_id: route_gate1.environment.id)

        Route.all.should include(route1, route2, route3)
        routes = Route.filter_by_environment_id(route_gate1.environment.id)
        routes.count == 2
        routes.should include(route1, route3)
        routes.should_not include(route2)
        Route.filter_by_environment_id(99999999999).should_not exist
      end
    end

    describe "#filter_by_route_type" do
      it "should return routes for a particular route_type" do
        route1 = create(:route, :route_type => 'mixed')
        route2 = create(:route, :route_type => 'open')
        Route.all.should include(route1, route2)
        routes = Route.filter_by_route_type('mixed')
        routes.count == 1
        routes.should include(route1)
        routes.should_not include(route2)
        Route.filter_by_route_type('TOTALLY NOT A ROUTE TYPE').should_not include(route1, route2)
      end
    end

  end

  describe "acts_as_archival" do
    describe "should be archivable" do
      before(:each) do
        @route = create(:route)
      end
      it "should archive" do
        @route.archived?.should be_falsey
        @route.archive
        @route.archived?.should be_truthy
      end

      it "should be immutable when archived" do
        @route.archive
        @route.name = 'Test Mutability'
        @route.save.should be_falsey
      end

      it "should unarchive" do
        @route.archive
        @route.archived?.should be_truthy
        @route.unarchive
        @route.archived?.should be_falsey
        @route.name = 'Test Mutability'
        @route.save.should be_truthy
      end

      it "should have archival scopes" do
        @route2 = create(:route)
        @route2.archive
        current_count = Route.count
        Route.archived.count.should == 1
        Route.unarchived.count.should == current_count - 1
      end

      it "should not archive if has active plan assignments" do
        @plan = create(:plan)
        @route.plans << @plan
        @route.plans.count.should == 1
        @route.plans.running.count.should == 1
        current_count = Route.unarchived.count
        results = @route.archive
        results.should be_falsey
        Route.unarchived.count.should == current_count
      end

      it "should archive if has in-active plan assignments" do
        @plan = create(:plan)
        @route.plans << @plan
        @route.plans.count.should == 1
        @route.plans.running.count.should == 1
        @plan.delete!
        current_count = Route.unarchived.count
        results = @route.archive
        results.should be_truthy
        Route.archived.count.should == 1
        Route.unarchived.count.should == current_count - 1
      end

    end
  end

  describe "should not be destroyable unless archived and free of associations" do

    before(:each) do
      @route = create(:route)
    end

    it "should not allow deletion if not archived" do
      current_count = Route.count
      @route.archived?.should be_falsey
      results = @route.destroy
      results.should be_falsey
      Route.count.should == current_count
    end

    it "should not allow deletion if archived but has development" do
      current_count = Route.count
      @route.archived?.should be_falsey
      results = @route.destroy
      results.should be_falsey
      Route.count.should == current_count
    end

    it "should allow deletion if archived" do
      current_count = Route.count
      @route.archive
      @route.archived?.should be_truthy
      results = @route.destroy
      results.should be_truthy
      Route.count.should == current_count - 1
    end

  end

  describe 'should provide convenience methods' do

    before(:each) do
      @route = create(:route)
    end

    it 'should provide the application name from app' do
      @route.app_name.should == @route.app.name
    end

    it 'should provide a list of environments in route gate order and sentence format' do
      route_gate1 = create(:route_gate, :route => @route, :position => 1)
      route_gate2 = create(:route_gate, :route => @route, :position => 2)
      route_gate3 = create(:route_gate, :route => @route, :position => 3)
      route_gate3.move_to_top
      route_gate1.reload
      route_gate2.reload
      route_gate3.reload
      @route.environments_list.should == "#{route_gate3.environment.name}, #{route_gate1.environment.name}, and #{route_gate2.environment.name}"
    end

    it 'should provide None when asked for the environments list of a route with no route gates' do
      route_without_gates = create(:route)
      route_without_gates.environments_list.should == 'None'
    end

    it 'should provide a grouped route gate list by level for reordering' do
      route_gate1 = create(:route_gate, :route => @route)
      route_gate2 = create(:route_gate, :route => @route, :different_level_from_previous => false)
      route_gate3 = create(:route_gate, :route => @route)
      results = []
      @route.each_route_gate_level do |route_gate, level|
        results << [route_gate, level]
      end
      # the resulting array should have two elements for levels 1 and 2
      # that reflect route_gates grouped by level
      results.length.should == 2
      results[0].should == [[route_gate1, route_gate2], 1]
      results[1].should == [[route_gate3], 2]
    end

    it "should indicate that it is a default route" do
      @route.name = '[default]'
      @route.default?.should be_truthy
    end

    describe 'should provide convenience methods for plans' do

      before(:each) do
        @plan_route1 = create(:plan_route, :route => @route)
        @plan_route2 = create(:plan_route, :route => @route)
        @plan_route3 = create(:plan_route, :route => @route)
        @plan = @plan_route1.plan
        @other_plan1 = @plan_route2.plan
        @other_plan2 = @plan_route3.plan
      end

      it 'should provide active plans collection' do
        results = @route.active_plans
        results.length.should == 3
        results.should include(@plan, @other_plan1, @other_plan2)
      end

      it 'should provide active plans list without archived plans' do
        results = @route.active_plans_list
        results.should == [@plan.name, @other_plan1.name, @other_plan2.name].sort.to_sentence + ' / None'
      end

      it 'should provide active plans list with archived plans' do
        plan_route4 = create(:plan_route, :route => @route)
        plan_route4.plan.aasm_state = :archived
        plan_route4.plan.save
        results = @route.active_plans_list(@route.plans.archived)
        results.should == [@plan.name, @other_plan1.name, @other_plan2.name].sort.to_sentence + ' / ' + plan_route4.plan.name
      end

      it 'should return None when a route has no plans for active_plans_list' do
        route_with_no_plans = create(:route)
        results = route_with_no_plans.active_plans_list
        results.should == 'None / None'
      end

      it 'should provide other active plans collection when passed a plan' do
        results = @route.other_active_plans(@plan)
        results.length.should == 2
        results.should include(@other_plan1, @other_plan2)
      end

      it 'should provide a string listing of other active plans collection when passed a plan' do
        results = @route.other_active_plans_list(@plan)
        results.should == [@other_plan1.name, @other_plan2.name].sort.to_sentence
      end

      it 'should return None when a route has no plans for other_active_plans_list' do
        route_with_no_plans = create(:route)
        results = route_with_no_plans.other_active_plans_list(@plan)
        results.should == 'None'
      end
    end

  end

  describe "should allow for easy addition of environments as stage gates" do

    before(:each) do
      @route = create(:route)
    end

    it "should allow creation of route gates by passing new environment ids" do
      environment1 = create(:environment)
      environment2 = create(:environment)
      app = @route.app
      app.environments << environment1
      app.environments << environment2
      @route.route_gates.count.should == 0
      @route.update_attributes(:new_environment_ids => [environment1.id, environment2.id])
      @route.route_gates.count.should == 2
      @route.environments.count.should == 2
    end

    it "should gracefully handle a blank array of ids" do
      @route.route_gates.count.should == 0
      @route.update_attributes(:new_environment_ids => [])
      @route.route_gates.count.should == 0
      @route.environments.count.should == 0
    end

    it "should gracefully handle non-existent ids" do
      @route.route_gates.count.should == 0
      @route.update_attributes(:new_environment_ids => [9999999, 9999992])
      @route.errors.count > 0
      @route.route_gates.count.should == 0
      @route.environments.count.should == 0
    end

    it "should gracefully ignore ids that already exist in the route" do
      environment1 = create(:environment)
      environment2 = create(:environment)
      app = @route.app
      app.environments << environment1
      app.environments << environment2
      @route.route_gates.count.should == 0
      @route.update_attributes(:new_environment_ids => [environment1.id])
      @route.route_gates.count.should == 1
      @route.environments.count.should == 1
      @route.update_attributes(:new_environment_ids => [environment1.id, environment2.id])
      @route.route_gates.count.should == 2
      @route.environments.count.should == 2
    end
  end

  describe '#filtered' do

    before(:all) do
      Route.delete_all
      @route_1 = create(:route, :name => 'Route #1')
      @route_2 = create(:route, :name => 'Route #2', :route_type => 'strict', :app_id => @route_1.app_id)
      @route_3 = create(:route, :name => 'Route #3', :route_type => 'mixed', :app_id => @route_1.app_id)
      @route_2.archive
      @route_2.reload # Name has been changed during archiving
      @archived_name = @route_2.name
      @default = Route.default_route_for_app_id(@route_1.app_id)
      @active = [@default, @route_1, @route_3]
      @inactive = [@route_2]

    end

    after(:all) do
      Route.delete_all
    end

    it_behaves_like 'active/inactive filter' do

      it 'cumulative filter active by default' do
        result = described_class.filtered(:name => 'Route #1')
        result.should match_array([@route_1])
      end

      it 'empty cumulative filter active by default' do
        result = described_class.filtered(:name => @archived_name)
        result.should be_empty
      end

      it 'cumulative filter inactive' do
        result = described_class.filtered(:archived => true, :name => @archived_name)
        result.should match_array [@route_2]
      end

      it 'filter by name, app_id, route_type' do
        result = described_class.filtered(:archived => true, :name => @archived_name, :app_id => @route_2.app.id, :route_type => 'strict')
        result.should match_array [@route_2]
      end
    end
  end

end
  