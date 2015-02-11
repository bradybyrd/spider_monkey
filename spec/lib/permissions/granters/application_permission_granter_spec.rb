require "spec_helper"
require "cancan/matchers"
require "permissions/permission_granters"
require "support/application_permissions_initialization_helper"

class ApplicationPermissionGranterTest < ApplicationPermissionGranter
  value_for(Environment) {|el| el.apps.map(&:id)}
  value_for(Request) {|el| el.app_ids}
end

describe ApplicationPermissionGranterTest do
  it "initialize should set the user" do
    instance = ApplicationPermissionGranterTest.new
    instance.instance_variable_get(:@user).should_not be_nil
  end

  describe "instance" do
    include ApplicationPermissionsInitializtaionHelper

    before(:each) do
      @instance = ApplicationPermissionGranterTest.new
      @wrong_app = create :app, name: "WrongApp"
      prepare_user_permissions
    end

    it "grant? should works lsuccess" do
      lambda{ @instance.grant?(:any, :any)}.should_not raise_error(NotImplementedError)
    end

    it "grant should allow for permissions in group for object without restriction association" do
      @instance.grant?(:create, Request.new).should be_truthy
      @instance.grant?(:create, Environment.new).should be_truthy
    end

    it "grant should denay for permissions out of group for object without restriction association" do
      @instance.grant?(:update, Request.new).should_not be_truthy
      @instance.grant?(:delete, Environment.new).should_not be_truthy
    end

    describe "App with Environment as object" do
      it "grant should denay for object with not appropriate restriction association" do
        env = create :environment, apps: [@wrong_app]
        req = create(:request, apps: [@wrong_app], environment: env)
        @instance.grant?(:create, env).should_not be_truthy
        @instance.grant?(:create, req).should_not be_truthy
      end

      it "grant should denay for permissions out of group for object with appropriate restriction association" do
        env = create :environment, apps: [@app1]
        req = create(:request, apps: [@app1], environment: env)
        @instance.grant?(:delete, env).should_not be_truthy
        @instance.grant?(:delete, req).should_not be_truthy
      end

      it "grant should allow for object with appropriate restriction association App1" do
        env = create :environment, apps: [@app1]
        req = create(:request, apps: [@app1], environment: env)
        @instance.grant?(:create, env).should be_truthy
        @instance.grant?(:create, req).should_not be_truthy
      end

      it "grant should allow for object with appropriate restriction association App2" do
        env = create :environment, apps: [@app2]
        req = create(:request, apps: [@app2], environment: env)
        @instance.grant?(:create, env).should be_truthy
        @instance.grant?(:create, req).should be_truthy
      end

      it "grant should allow for object with at least one appropriate restriction association" do
        env = create :environment, apps: [@app1, @wrong_app]
        @instance.grant?(:create, env).should be_truthy
      end
    end

  end
end