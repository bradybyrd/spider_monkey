require 'spec_helper'

describe RequestApplicationEnvironmentPreloader, custom_roles: true do
  describe 'one request' do
    it 'assign proper application_environments to request with 2 apps' do
      app1 = create :app, name: 'First Application'
      app2 = create :app, name: 'Second Application'
      environment = create :environment, name: 'Alone Environment'

      app_env1 = create :application_environment, app: app1, environment: environment
      app_env2 = create :application_environment, app: app2, environment: environment
      request = create :request, apps: [app1, app2], environment: environment

      RequestApplicationEnvironmentPreloader.new(request).preload

      expect(request.application_environments).to match_array [app_env1, app_env2]
    end

    it 'assign proper application_environments to request with 1 app' do
      app_env = create :application_environment
      request = create :request, apps: [app_env.app], environment: app_env.environment

      RequestApplicationEnvironmentPreloader.new(request).preload

      request.application_environments.should == [app_env]
    end

    it "assign nothing if request isn't persisted" do
      request = build :request

      RequestApplicationEnvironmentPreloader.new(request).preload

      expect(request.application_environments).to be_empty
    end
  end

  describe 'list of requests' do
    it 'assign proper application_environments to requests' do
      app_env = create :application_environment
      app_in_other_env = create :application_environment
      app_in_same_env = create(:application_environment, environment: app_in_other_env.environment)

      request1 = create :request, apps: [app_env.app], environment: app_env.environment
      request2 = create :request, apps: [app_in_other_env.app, app_in_same_env.app], environment: app_in_other_env.environment

      RequestApplicationEnvironmentPreloader.new(Request.scoped).preload

      expect(request1.application_environments).to eq [app_env]
      expect(request2.application_environments).to match_array [app_in_other_env, app_in_same_env]
    end


    it "assign nothing if requests isn't persisted" do
      requests = build_list :request, 2

      RequestApplicationEnvironmentPreloader.new(requests).preload

      requests.each{ |request|
        expect(request.application_environments).to be_empty
      }
    end
  end

end