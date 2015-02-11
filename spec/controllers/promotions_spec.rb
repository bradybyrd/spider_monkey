require 'spec_helper'

describe PromotionsController, :type => :controller do
  before(:each) do
    @request1 = create(:request_with_app)
    @app = @request1.apps.first
    @component = create(:component)
    @environment = @request1.environment
    @app_environment = ApplicationEnvironment.by_application_and_environment_names(@app.name, @environment.name).first
    @app_component = create(:application_component, :app => @app, :component => @component)
    @pr_server = create(:project_server)
    @installed_component = create(:installed_component,
                                  :application_environment => @app_environment,
                                  :application_component => @app_component)
    @request_template = create(:request_template, :request => @request1)
  end

  it "#new" do
    get :new, {:app_id => @app.id}
    assigns(:request_templates).should include(@request_template)
    response.should render_template('new')
  end

  context "#promotion_table" do
    it "creates promotion" do
      post :promotion_table, {:promotion => {:app_id => @app,
                                             :target_env => @environment,
                                             :source_env => @environment},
                              :format => 'js'}
      assigns(:app).should eql(@app)
      response.should render_template("promotion_table")
    end

    it "returns validation errors" do
      post :promotion_table, {:promotion => {:app_id => @app}}
      response.should render_template("misc/error_messages_for")
    end
  end
end