require "spec_helper"
require "cancan/matchers"
require "permissions/permission_granters"
require "support/application_environment_permissions_initialization_helper"


class EnvironmentPermissionGranterTest < EnvironmentPermissionGranter
  value_for(VersionTag) { |el| el.send(:app_env_id) }
  value_for(Request) { |el| el.application_environments.map(&:id) }
  value_for(DeploymentWindow::Series) { |deployment_window_series|
    ApplicationEnvironment.where(environment_id: deployment_window_series.environment_ids).pluck(:id)
  }
end

describe EnvironmentPermissionGranterTest, custom_roles: true do
  include ApplicationEnvironmentPermissionsInitializtaionHelper

  before(:each) do
    @instance = EnvironmentPermissionGranterTest.new
    @wrong_app = create :app, name: "WrongApp"
    @wrong_env = create :environment, apps: [@wrong_app]
    @wrong_app_env = @wrong_app.application_environments.where("environment_id = ?", @wrong_env.id).first

    prepare_user_permissions
  end

  it "grant? should works success" do
    expect { @instance.grant?(:any, :any) }.not_to raise_error(NotImplementedError)
  end

  it "grant should allow for permissions in group for object without restriction association" do
    @instance.grant?(:create, Request.new).should be true
    @instance.grant?(:create, VersionTag.new).should be true
  end

  it "grant should denay for permissions out of group for object without restriction association" do
    @instance.grant?(:forbidden, Request.new).should be false
    @instance.grant?(:forbidden, VersionTag.new).should be false
  end

  describe "App with Environment as object" do
    it "grant should denay for object with not appropriate restriction association" do
      req = create(:request, apps: [@wrong_app], environment: @wrong_env)
      vt = create(:version_tag, application_environment: @wrong_app_env)
      @instance.grant?(:create, req).should be false
      @instance.grant?(:create, vt).should be false
    end

    it "grant should denay for permissions out of group for object with appropriate restriction association" do
      req = create(:request, apps: [@app1], environment: @env1)
      vt = create(:version_tag, application_environment: @app_env1)
      @instance.grant?(:forbidden, req).should be false
      @instance.grant?(:forbidden, vt).should be false
    end

    it "grant should allow for object with appropriate restriction association App1 for all roles" do
      req = create(:request, apps: [@app1], environment: @env1)
      vt = create(:version_tag, application_environment: @app_env1)
      req2 = create(:request, apps: [@app1], environment: @env2)
      vt2 = create(:version_tag, application_environment: @app_env2)
      @instance.grant?(:create, vt).should be true
      @instance.grant?(:create, req).should be true
      @instance.grant?(:create, vt2).should be true
      @instance.grant?(:create, req2).should be true

      @instance.grant?(:delete, vt).should be true
      @instance.grant?(:update, req).should be true
      @instance.grant?(:delete, vt2).should be true
      @instance.grant?(:update, req2).should be true
    end

    it "grant should allow for object with appropriate restriction association App2 with appropriate roles" do
      req = create(:request, apps: [@app2], environment: @env3)
      req2 = create(:request, apps: [@app2], environment: @env4)
      vt = create(:version_tag, application_environment: @app_env3)
      vt2 = create(:version_tag, application_environment: @app_env4)
      @instance.grant?(:view, vt).should be true
      @instance.grant?(:delete, req).should be true
      @instance.grant?(:view, vt2).should be true
      @instance.grant?(:delete, req2).should be true
    end

    it "grant should denay for object with appropriate restriction association App2 with not appropriate roles" do
      req = create(:request, apps: [@app2], environment: @env3)
      req2 = create(:request, apps: [@app2], environment: @env4)
      vt = create(:version_tag, application_environment: @app_env3)
      vt2 = create(:version_tag, application_environment: @app_env4)
      @instance.grant?(:delete, vt).should be false
      @instance.grant?(:update, req).should be false
      @instance.grant?(:delete, vt2).should be false
      @instance.grant?(:update, req2).should be true
    end
  end
end
