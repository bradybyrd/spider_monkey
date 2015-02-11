require "spec_helper"

describe EnvironmentPermissionScoper, custom_roles: true do
  class TestEnvironmentPermissionScoper < EnvironmentPermissionScoper; end

  describe ".scope_for" do
    it "adds scope to available scopes" do
      proc = Proc.new { 'test' }
      TestEnvironmentPermissionScoper.scope_for(Object, &proc)
      expect(TestEnvironmentPermissionScoper.scopes.keys).to include('Object')
    end
  end

  describe '#scope_subject' do
    it 'returns scope class name' do
      scoper = TestEnvironmentPermissionScoper.new(User.current_user, Request.scoped)
      expect(scoper.send(:scope_subject)).to eq 'Request'
    end
  end

  describe '#get_scope' do
    it 'returns scoper for class' do
      proc = Proc.new { 'test' }
      TestEnvironmentPermissionScoper.scope_for(Request, &proc)
      scoper = TestEnvironmentPermissionScoper.new(User.current_user, Request.scoped)
      expect(scoper.send(:get_scope)).to eq proc
    end
  end

  describe '#entities_by_ability' do
    it 'returns entities using defined scope' do
      entities = [1, 2, 3]
      proc = Proc.new {|attr1, attr2| entities.dup }
      TestEnvironmentPermissionScoper.scope_for(Request, &proc)
      scoper = TestEnvironmentPermissionScoper.new(User.current_user, Request.scoped)
      scoper.entities_by_ability(:list).should =~ entities
    end
  end

  describe '#environment_selector' do
    it 'returns environment selector instance' do
      scoper = TestEnvironmentPermissionScoper.new(User.current_user, Request.scoped)
      env_selector = scoper.environment_selector(:list)
      expect(env_selector).to be_a AccessibleAppEnvironmentQuery
      expect(env_selector.user).to eq User.current_user
      expect(env_selector.subject).to eq 'Request'
      expect(env_selector.action).to eq :list
    end
  end
end
