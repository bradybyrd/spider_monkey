require 'spec_helper'
require 'accessible_app_environment_query'
require 'support/application_environment_permissions_initialization_helper'

describe PermissionMap, custom_roles: true do
  after(:all){ Singleton.__init__(PermissionMap) }
  let!(:user) { create(:user, :non_root, :with_role_and_group) }
  let!(:instance) { PermissionMap.instance }
  let!(:user_permissions) do
    cache = mock 'Cache to be tested'
    instance.instance_variable_set(:@user_permissions, cache)
    cache
  end

  describe 'initialization' do
    it 'should register permission when initialize' do
      permissions_mock = mock 'Cache for permissions'
      map_cache_mock = mock 'Map Cache for all associations'
      TorqueBox::Infinispan::Cache.should_receive(:new).with(name: 'permissions', mode: :distributed).and_return permissions_mock
      TorqueBox::Infinispan::Cache.should_receive(:new).with(name: 'user_permissions', mode: :distributed).and_return map_cache_mock
      PermissionMap.any_instance.should_receive(:register_permissions)
      Singleton.__init__(PermissionMap)

      instance = PermissionMap.instance

      instance.instance_variable_get(:@permissions).should == permissions_mock
      instance.instance_variable_get(:@user_permissions).should == map_cache_mock
    end
  end

  describe '#clean' do
    it 'should clean user_permissions' do
      user_permissions.should_receive(:remove).with(user.id)
      instance.clean(user)
    end
  end

  describe '#get_user_data' do
    it 'should register_user if not contains' do
      user_permissions.should_receive(:contains_key?).with(user.id).and_return false
      instance.should_receive(:cache_user_permissions).with(user)
      instance.get_user_permissions(user)
    end
    it 'should return map data for user if contains' do
      user_permissions.should_receive(:contains_key?).with(user.id).and_return true
      user_permissions.should_receive(:get).with(user.id)
      instance.get_user_permissions(user)
    end
  end

  describe '#register_user and sub methods' do
    include ApplicationEnvironmentPermissionsInitializtaionHelper

    describe '#register_user' do
      before do
        prepare_user_permissions(user)
      end

      let!(:instance) do
        Singleton.__init__(PermissionMap)
        PermissionMap.instance
      end

      let!(:user_permissions) do
        cache = mock 'Cache to be tested for new instance'
        instance.instance_variable_set(:@user_permissions, cache)
        cache.stub(:remove).with(any_args).and_return true
        cache
      end


      it 'should create and store hash with associations with mocks' do
        hash_mock = mock 'Permission Associations Hash'
        instance.should_receive(:global_permissions_hash).with(user).and_return hash_mock
        instance.should_receive(:set_application_environment_permissions).with(user, hash_mock)
        instance.should_receive(:set_application_permissions).with(user, hash_mock)
        user_permissions.should_receive(:put).with(user.id, hash_mock)

        instance.send(:cache_user_permissions, user).should == hash_mock
      end

      let!(:hash) do
        user_permissions.stub(:put)
        hash = instance.send(:cache_user_permissions, user)
      end

      it 'should contains global permission id for VersionTag and Request create permission' do
        hash[instance.send(:stored_key, 'VersionTag', :create)][PermissionMap::GLOBAL_KEY].should == Permission.where(subject: 'VersionTag', action: :create).first.id
        hash[instance.send(:stored_key, 'Request', :create)][PermissionMap::GLOBAL_KEY].should == Permission.where(subject: 'Request', action: :create).first.id
      end

      it 'should has global access for create permission for VersionTag and Request' do
        instance.has_user_global_access?(user, 'VersionTag', :create).should be_truthy
        instance.has_user_global_access?(user, 'Request', :create).should be_truthy
      end

      it 'should not contains permission that not assigned to user' do
        hash[instance.send(:stored_key, 'VersionTag', :forbidden)].should be_blank
        hash[instance.send(:stored_key, 'Request', :forbidden)].should be_blank
      end

      it 'should contains  permission id for VersionTag create permission' do
        hash[instance.send(:stored_key, 'VersionTag', :create)][PermissionMap::GLOBAL_KEY].should == Permission.where(subject: 'VersionTag', action: :create).first.id
        hash[instance.send(:stored_key, 'Request', :create)][PermissionMap::GLOBAL_KEY].should == Permission.where(subject: 'Request', action: :create).first.id
      end
    end
  end

end