require "spec_helper"

describe InstalledComponentsHelper do
  before(:each) do
    @app = create(:app)
    @request1 = create(:request)
    @request1.apps << @app
    @step = create(:step, :request => @request1)
    @env = create(:environment)
    @app_env = create(:application_environment, :app => @app,
                      :environment => @env)
    @component = create(:component)
    @app_component = create(:application_component, :app => @app,
                            :component => @component)
    @installed_component = create(:installed_component, :application_environment => @app_env,
                                  :application_component => @app_component)
  end

  it "#installed_component_name" do
    helper.installed_component_name(@installed_component).should eql(@installed_component.name)
  end

  context "#selected_server_association_type" do
    it "returns server_group" do
      @installed_component.default_server_group_id = create(:server_group).id
      helper.selected_server_association_type(@installed_component, nil).should eql('server_group')
    end

    it "returns server_aspect_group" do
      @installed_component.server_aspect_group_ids = create(:server_aspect_group).id
      helper.selected_server_association_type(@installed_component, nil).should eql('server_aspect_group')
    end

    it "returns server_level" do
      @server = create(:server)
      @server_level = create(:server_level)
      @server_aspect = create(:server_aspect,
                              :server_level_id => @server_level.id,
                              :parent => @server)
      @installed_component.server_aspect_ids = @server_aspect.id
      helper.selected_server_association_type(@installed_component, [@server_level]).should eql("server_level_#{@server_level.id}")
    end

    it "returns server" do
      helper.selected_server_association_type(@installed_component, nil).should eql('server')
    end
  end
end
