require "spec_helper"
require "cancan/matchers"
require "permissions/permission_manager"

class AbilityTest
  include CanCan::Ability
end

class PermissionManagerTest < PermissionManager
  RESTRICTIONS = {
      :global => %w(main_tab Category EnvironmentType),
      :application => %w(Plan),
      :environment => %w(Server)
  }
end

describe PermissionManagerTest do

  it "initialize should register granters and set ability" do
    ability = AbilityTest.new
    instance = PermissionManagerTest.new(ability)
    granters = instance.instance_variable_get(:@granters)
    PermissionManagerTest::RESTRICTIONS.keys.each do |key|
      granters.keys.should include(key)
      granters[key].should be_kind_of(PermissionGranter)
    end
    instance.instance_variable_get(:@ability).should == ability
    instance.instance_variable_get(:@user).should_not be_nil
  end


  describe "instance" do
    before(:each) do
      @ability = AbilityTest.new
      @instance = PermissionManagerTest.new(@ability)
      @user = User.current_user
    end

    it "permission_granter should return valid PermissionGranter by the key" do
      PermissionManagerTest::RESTRICTIONS.values.flatten.each do |key|
        @instance.permission_granter(key).should be_kind_of(PermissionGranter)
      end
    end

    it "permission_granter should raise ArgumentError for invalid key" do
      lambda { @instance.permission_granter("wrong_key") }.should raise_error(ArgumentError)
    end

    describe '#apply_permissions' do
      before { @instance.stub(:user_permissions).and_return create_permissions(perm_hash).group_by(&:subject) }

      describe 'model permissions' do
        let(:perm_hash) do
          {
              Category => [:create],
              Plan => [:view, :create],
              Server => [:create, :view, :delete]
          }
        end

        it 'receives register_model_action' do
          perm_hash.each do |subj, actions|
            actions.each { |action| allow(@instance).to receive(:register_model_action).with(action, subj) }
          end

          @instance.apply_permissions
        end
      end

      describe 'non model permissions' do
        let(:perm_hash) do
          {
              main_tab: [:view_dashboard]
          }
        end

        it 'receives register_global_action' do
          allow(@instance).to receive(:register_global_action).with(:view_dashboard, 'MainTab')

          @instance.apply_permissions
        end

      end
    end

    it "register_global_action should call appropriate method in appropriate class" do
      module Permissions
        module GlobalPermissions
          class MainMenu
  #          def view_dashboard?(user); true; end
  #          def view_environment?(user); false; end
          end
        end
      end

      Permissions::GlobalPermissions::MainMenu.any_instance.should_receive(:view_dashboard?).with(@user).and_return true
      Permissions::GlobalPermissions::MainMenu.any_instance.should_receive(:view_environment?).with(@user).and_return false
      @instance.should_not_receive(:permission_granter).with(:any)
      @instance.register_global_action(:view_dashboard, :main_menu)
      @instance.register_global_action(:view_environment, :main_menu)
      @ability.should be_able_to(:view_dashboard, :main_menu)
      @ability.should_not be_able_to(:view_environment, :main_menu)
    end

    it "register_global_action should call grant method in appropriate granter" do
      #assume that PermissionManagerTest::RESTRICTIONS has key :global with "MainTab"
      key = "OtherMenu"
      PermissionManagerTest::RESTRICTIONS[:global] << key

      global_perm_granter = mock "GlobalPermissionGranter instance"
      global_perm_granter.should_receive(:grant?).with(:view_dashboard, key).and_return true
      global_perm_granter.should_receive(:grant?).with(:view_environment, key).and_return false
      @instance.should_receive(:permission_granter).twice.with(key).and_return global_perm_granter

      @instance.register_global_action(:view_dashboard, key)
      @instance.register_global_action(:view_environment, key)

      @ability.should be_able_to(:view_dashboard, key.to_sym)
      @ability.should_not be_able_to(:view_environment, key.to_sym)

      PermissionManagerTest::RESTRICTIONS[:global].pop # remove 'OtherMenu'
    end

    it "register_model_action should call appropriate method in appropriate class" do
      module Permissions
        module Model
          class CategoryPermissions
    #        def view?(obj, user); true; end
    #        def create?(obj, user); false; end
          end
        end
      end

      obj = Category.new
      Permissions::Model::CategoryPermissions.any_instance.should_receive(:view?).with(obj, @user).and_return true
      Permissions::Model::CategoryPermissions.any_instance.should_receive(:create?).with(obj, @user).and_return false

      @instance.should_not_receive(:permission_granter).with(:any)
      @instance.register_model_action(:view, Category)
      @instance.register_model_action(:create, Category)
      @ability.should be_able_to(:view, obj)
      @ability.should_not be_able_to(:create, obj)
    end

    it "register_model_action should call grant method in global granter" do
      #assume that PermissionManagerTest::RESTRICTIONS has key :global with "EnvironmentType"
      global_perm_granter = mock "GlobalPermissionGranter instance"
      env_type = EnvironmentType.new

      @instance.should_receive(:permission_granter).twice.with(env_type.class).and_return global_perm_granter

      global_perm_granter.should_receive(:grant?).with(:view, env_type).and_return true
      global_perm_granter.should_receive(:grant?).with(:create, env_type).and_return false

      @instance.register_model_action(:view, EnvironmentType)
      @instance.register_model_action(:create, EnvironmentType)

      @ability.should be_able_to(:view, env_type)
      @ability.should_not be_able_to(:create, env_type)
    end

    it "register_model_action should call grant method in application granter" do
      #assume that PermissionManagerTest::RESTRICTIONS has key :application with "Plan"
      app_perm_granter = mock "ApplicationPermissionGranter instance"
      plan = Plan.new

      @instance.should_receive(:permission_granter).twice.with(plan.class).and_return app_perm_granter

      app_perm_granter.should_receive(:grant?).with(:view, plan).and_return true
      app_perm_granter.should_receive(:grant?).with(:delete, plan).and_return false

      @instance.register_model_action(:view, Plan)
      @instance.register_model_action(:delete, Plan)

      @ability.should be_able_to(:view, plan)
      @ability.should_not be_able_to(:delete, plan)
      @ability.should_not be_able_to(:create, plan)
    end

    it "register_model_action should call grant method in environment granter" do
      #assume that PermissionManagerTest::RESTRICTIONS has key :environment with "Server"
      env_perm_granter = mock "EnvironmentPermissionGranter instance"
      server = Server.new

      @instance.should_receive(:permission_granter).twice.with(server.class).and_return env_perm_granter

      env_perm_granter.should_receive(:grant?).with(:create, server).and_return true
      env_perm_granter.should_receive(:grant?).with(:destroy, server).and_return false

      @instance.register_model_action(:create, Server)
      @instance.register_model_action(:destroy, Server)

      @ability.should be_able_to(:create, server)
      @ability.should_not be_able_to(:destroy, server)
      @ability.should_not be_able_to(:delete, server)
    end

    it "register_model_action should use granter type defined in model" do
      app_perm_granter = double "ApplicationPermissionGranter instance"

      request = Request.new

      allow(@instance).to receive(:granter).twice.and_return(app_perm_granter)
      app_perm_granter.should_receive(:grant?).twice.and_return true

      @instance.register_model_action(:view, Request)

      # Grater Type 1
      allow(request).to receive(:granter_type).and_return(:application)

      @ability.can?(:view, request)
      expect(@instance).to have_received(:granter).with(:application)

      # Grater Type 2
      allow(request).to receive(:granter_type).and_return(:environment)

      @ability.can?(:view, request)
      expect(@instance).to have_received(:granter).with(:environment)
    end

    describe '#granter' do
      it 'returns registered permission granter' do
        expect(@instance.granter(:application)).to be_a ApplicationPermissionGranter
      end
    end
  end
end

def create_permissions(perm_hash)
  permissions = []

  perm_hash.each do |key, actions|
    permissions = actions.map { |action| build(:permission, subject: key.to_s.camelize, action: action)}
  end

  permissions
end