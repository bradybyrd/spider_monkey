################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2015
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe Environment do
  let(:env) { build :environment }

  context '' do
    it{ should have_many(:deployment_window_events).class_name(DeploymentWindow::Event).with_foreign_key(:environment_id) }

    before(:each) do
      @environment = create(:environment, name: 'name1')
    end

    describe 'associations' do
      it 'should have many' do
        expect(@environment).to have_many(:requests)
        expect(@environment).to have_many(:application_environments)
        expect(@environment).to have_many(:installed_components)
        expect(@environment).to have_many(:apps)
        expect(@environment).to have_many(:environment_servers)
        expect(@environment).to have_many(:environment_server_groups)
        expect(@environment).to have_many(:servers)
        expect(@environment).to have_many(:server_groups)
        expect(@environment).to have_many(:assigned_apps)
        expect(@environment).to have_many(:packages)
        expect(@environment).to have_many(:references)
      end

      it 'should belong to' do
        expect(@environment).to belong_to(:environment_type)
        expect(@environment).to belong_to(:default_server_group)
      end

    end

    describe 'validations' do
      it { expect(@environment).to validate_presence_of(:name) }
      it { expect(@environment).to validate_uniqueness_of(:name) }
      it { should ensure_length_of(:name).is_at_most(255) }
    end

    describe 'attribute normalizations' do
      it { should normalize_attribute(:name).from('  Hello  ').to('Hello') }
    end
  end

  describe '#filtered' do

    before(:all) do
      Environment.delete_all
      @env_type = create(:environment_type)
      @env1 = create_environment(active: true)
      @env2 = create_environment(active: false, name: 'Un-used Environment', environment_type: @env_type)
      @env3 = create_environment(active: true, name: 'Default Environment', environment_type: @env_type)
      @active = [@env1, @env3]
      @inactive = [@env2]
    end

    after(:all) do
      Environment.delete_all
    end

    it_behaves_like 'active/inactive filter' do

      it 'cumulative filter by `name`, active by default' do
        result = described_class.filtered(name: 'Default Environment')
        expect(result).to match_array([@env3])
      end

      it 'empty cumulative filter by `name`, active by default' do
        result = described_class.filtered(name: 'Un-used Environment')
        expect(result).to be_empty
      end

      it 'cumulative filter by `name`, inactive' do
        result = described_class.filtered(inactive: true, name: 'Un-used Environment')
        expect(result).to match_array([@env2])
      end

      it 'cumulative filter by `environment type`, active by default' do
        result = described_class.filtered(environment_type_id: @env_type.id)
        expect(result).to match_array([@env3])
      end

      it 'cumulative filter by `environment type`, inactive' do
        result = described_class.filtered(inactive: true, environment_type_id: @env_type.id)
        expect(result).to match_array([@env2])
      end

      it 'cumulative filter by `environment type`, both active and inactive' do
        result = described_class.filtered(active: true, inactive: true, environment_type_id: @env_type.id)
        expect(result).to match_array([@env2, @env3])
      end
    end
  end

  describe 'should provide convenience methods' do

    before(:each) do
      @environment = create(:environment)
    end

    it 'should provide a list of routes in alphabetical order and sentence format' do
      # it should not throw an error if there are none
      expect(@environment.routes_list).to eq ''
      # now add some and see if the list is sorted and matches
      route1 = create(:route, name: 'Z Route')
      create(:route_gate, route: route1, environment: @environment)
      route2 = create(:route, name: 'A Route')
      create(:route_gate, route: route2, environment: @environment)
      route3 = create(:route, name: 'M Route')
      create(:route_gate, route: route3, environment: @environment)
      expect(@environment.route_gates.count).to eq 3
      expect(@environment.routes.count).to eq 3
      # reloading the model is required to freshen the values for route_gates and routes
      @environment.reload
      expect(@environment.routes_list).to eq "#{route2.app.name}: #{route2.name}, #{route3.app.name}: #{route3.name}, and #{route1.app.name}: #{route1.name}"
    end
  end

  describe 'when removing from an app' do

    before(:each) do
      @environment = create(:environment)
      @app = create(:app)
      @app.environments << @environment
      @app.reload
    end


    it 'should allow removal from application with no requests' do
      expect(@environment.can_be_removed_from_app?(@app)).to be_truthy
    end

    it 'should prevent removal from application with active requests' do
      AssignedEnvironment.create!(environment_id: @environment.id, assigned_app_id: @app.assigned_apps.first.id, role: @user.roles.first)
      Request.any_instance.stub(:check_if_able_to_create_request).and_return(true)
      create(:request, app_ids: [@app.id], environment: @environment)
      expect(@environment.can_be_removed_from_app?(@app)).to be_falsey
    end

    it 'should prevent removal from application with route gates' do
      route1 = create(:route, app: @app)
      create(:route_gate, route: route1, environment: @environment)
      @environment.reload
      expect(@environment.routes.count).to eq 2
      expect(@environment.can_be_removed_from_app?(@app)).to be_falsey
    end

    it 'should prevent removal from application whose default route is in use by an active plan' do
      default_route = @app.default_route
      create(:plan_route, route: default_route)
      @environment.reload
      expect(@environment.routes.count).to eq 1
      expect(@environment.can_be_removed_from_app?(@app)).to be_falsey
    end

  end

  describe 'convenience accessors' do
    before(:each) do
      @strict_environment_type = create(:environment_type, strict: true)
      @permissive_environment_type = create(:environment_type, strict: false)

      @environment1 = create(:environment, environment_type: @strict_environment_type)
      @environment2 = create(:environment, environment_type: @permissive_environment_type)
      @environment3 = create(:environment)
    end

    it 'should provide a full label with environment type with strict quality' do
      expect(@environment1.full_label).to eq "#{ @environment1.name } (#{ @environment1.environment_type.name } - Strict)"
    end

    it 'should provide a full label with environment type' do
      expect(@environment2.full_label).to eq "#{ @environment2.name } (#{ @environment2.environment_type.name })"
    end

    it 'should provide a full label with untyped message when environment type is nil' do
      expect(@environment3.full_label).to eq "#{ @environment3.name } (Untyped)"
    end
  end

  describe '#server_groups_with_default_first' do
    let(:last_server_group) { create(:server_group, name: 'Z') }
    let(:middle_server_group) { create(:server_group, name: 'J') }
    let(:first_server_group) { create(:server_group, name: 'A') }
    let(:environment) { create(:environment, server_groups: [last_server_group, first_server_group, middle_server_group]) }

    it 'returns sorted server groups' do
      expect(environment.server_groups_with_default_first).to eq [first_server_group, middle_server_group, last_server_group]
    end

    it 'returns sorted server groups with first default one' do
      environment.update_attribute(:default_server_group_id, last_server_group.id)
      expect(environment.server_groups_with_default_first).to eq [last_server_group, first_server_group, middle_server_group]
    end
  end

  describe 'changing deployment policy' do
    let(:active_dws) do
      create :deployment_window_series, :with_occurrences, environment_ids: [env.id]
    end

    let(:passed_in_time_dws) do
      dws = build :deployment_window_series, :passed_in_time, environment_ids: [env.id]
      dws.save validate: false

      dwo = build :deployment_window_occurrence, :passed_in_time, series_id: dws.id, environment_ids: [env.id]
      dwo.save validate: false

      dwe = build :deployment_window_event, :passed_in_time, environment: env, occurrence_id: dwo.id
      dwe.save validate: false

      dws
    end

    let(:env) { create :environment }

    describe 'association with deployment window events' do

      let(:env_with_active_dws) { env.deployment_window_events = active_dws.events; env }
      let(:env_with_passed_dws) { env.deployment_window_events = passed_in_time_dws.events; env }

      it 'should call #remove_deployment_windows' do
        expect(env).to receive(:remove_deployment_window_events)
        env.update_attribute :deployment_policy, 'closed'
      end

      it 'should unassociate from deployment windows series related to the future' do
        expect{
          env_with_active_dws.update_attribute :deployment_policy, 'closed'
        }.to change{
          env_with_active_dws.deployment_window_events.count
        }.from(1).to(0)
      end

      it 'should not affect association with deployment windows from the past' do
        expect{
          env_with_passed_dws.update_attribute :deployment_policy, 'closed'
        }.to_not change{
          env_with_passed_dws.deployment_window_events.count
        }
      end
    end

    describe 'with requests on opened environment' do
      requests_successful_states = %W(created planned hold complete deleted)

      let(:env) { create :environment, deployment_policy: 'opened' }

      it 'should check if #can_change_to_closed? if deployment_policy was changed' do
        expect(env).to receive(:can_change_to_closed?)
        env.update_attributes deployment_policy: 'closed'
      end

      requests_successful_states.each do |state|
        it "should be successfully if request is in #{state} state" do
          r   = create_request_with_env_in_state state
          env = r.environment
          env.update_attributes deployment_policy: 'closed'

          expect(env).to be_valid
          expect(env.reload.deployment_policy).to eq 'closed'
        end
      end
      Environment::ENV_TO_CLOSED.each do |state|
        it "should not be successfully if request is in #{state} state" do
          r   = create_request_with_env_in_state state
          env = r.environment
          env.update_attributes deployment_policy: 'closed'

          expect(env).to_not be_valid
          expect(env.reload.deployment_policy).to eq 'opened'
        end
      end
    end

    describe 'with requests on closed env' do
      let(:env) { create :environment, deployment_policy: 'closed' }

      let(:requests_with_active_dw) do
        Environment::ENV_TO_OPENED.map do |state|
          active_dwe  = active_dws.events.first
          estimate    = (active_dwe.finish_at - active_dwe.start_at - 1.second) / 3600
          r           = create :request, environment: env, deployment_window_event_id: active_dwe.id,
                               scheduled_at: active_dwe.start_at, estimate: estimate
          r.update_attribute :aasm_state, state #bypasssing state machine validations
          r
        end
      end

      let(:requests_with_passed_in_time_dw) do
        Environment::ENV_TO_OPENED.map do |state|
          passed_in_time_dwe  = passed_in_time_dws.events.first
          estimate            = (passed_in_time_dwe.finish_at - passed_in_time_dwe.start_at - 1.second) / 3600
          r = create :request, environment: env, deployment_window_event_id: passed_in_time_dwe.id,
                     scheduled_at: passed_in_time_dwe.start_at, estimate: estimate
          r.update_attribute :aasm_state, state #bypasssing state machine validations
          r
        end
      end

      it 'should check if #can_change_to_opened? if deployment_policy was changed' do
        expect(env).to receive(:can_change_to_opened?)
        env.update_attributes deployment_policy: 'opened'
      end

      it 'should find #request_ids_with_active_dw_in_states' do
        expect(requests_with_active_dw.count).to eq Environment::ENV_TO_OPENED.count
        expect(requests_with_passed_in_time_dw.count).to eq Environment::ENV_TO_OPENED.count
        expect(env.requests.count).to eq Environment::ENV_TO_OPENED.count * 2

        expected_result = requests_with_active_dw.collect{ |r| r.number }
        expect(env.request_ids_with_active_dw_in_states(Environment::ENV_TO_OPENED)).to match_array(expected_result)
      end

      it 'should not be successful with warning present if request has active deployment window' do
        expect(requests_with_active_dw.count).to eq Environment::ENV_TO_OPENED.count

        env.update_attributes deployment_policy: 'opened'
        expect(env).to_not be_valid
        expect(env.reload.deployment_policy).to eq 'closed'
      end

      it 'should be successful if request has deployment window passed in time' do
        expect(requests_with_passed_in_time_dw.count).to eq Environment::ENV_TO_OPENED.count

        env.update_attributes deployment_policy: 'opened'
        expect(env).to be_valid
        expect(env.reload.deployment_policy).to eq 'opened'
      end
    end
  end

  describe '#used?' do
    it 'should return true if env is used by dwe' do
      env.deployment_window_events = [build(:deployment_window_event)]
      expect(env.used?).to be_truthy
    end

    it 'should return true if env is used by app' do
      env.apps = [build(:app)]
      expect(env.used?).to be_truthy
    end

    it 'should return false if env is not usd by app or dwe' do
      expect(env.used?).to be_falsey
    end
  end

  describe '#validate_deactivate' do
    let (:env) { create :environment, active: true }

    it 'adds errors for environment that could not be deactivated' do
      env.active = false
      env.stub(:can_deactivate?).and_return(false)
      expect(env.valid?).to be_falsey
      expect(env.errors.full_messages).to include('Environment which is in use cannot be deactivated.')
    end
  end

  describe '#can_deactivate?' do
    it 'returns false if environment is default' do
      env.stub(:default?).and_return(true)
      expect(env.can_deactivate?).to be_falsey
    end

    it 'returns false if environment in use' do
      env.stub(:used?).and_return(true)
      expect(env.can_deactivate?).to be_falsey
    end

    it 'returns true if environment is not default and not in use' do
      env.stub(:default?).and_return(false)
      env.stub(:used?).and_return(false)
      expect(env.can_deactivate?).to be_truthy
    end
  end

  describe 'when removing association with a server' do

    before(:each) do
      @server = create(:server)
      @environment = create(:environment)
      @app = create(:app)
      @app.environments << @environment
      @app.reload
    end

    it 'should allow removal of server with no package references' do
      expect(@environment.can_remove_server_association?(@server.id)).to be_truthy
    end

    it 'should prevent removal from server with package reference' do
      package = create(:package)
      create(:reference, package: package, server: @server)
      @app.packages << package
      expect(@environment.can_remove_server_association?(@server.id)).to be_falsey
    end
  end

  protected

  def create_environment(options = nil)
    create(:environment, options)
  end

  def create_request_with_env_in_state(state)
    e = create(:environment, deployment_policy: 'opened')
    r = create(:request, environment: e)
    r.update_attribute :aasm_state, state #bypassing state machine validations
    r
  end
end

