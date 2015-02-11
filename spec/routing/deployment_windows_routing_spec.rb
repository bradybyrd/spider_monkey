require "spec_helper"

describe 'deployment_window namespace routing' do
  describe DeploymentWindow::SeriesController do

    it "routes to #index" do
      get("/environment/metadata/deployment_window/series").should route_to("deployment_window/series#index")
    end

    it "routes to #new" do
      get("/environment/metadata/deployment_window/series/new").should route_to("deployment_window/series#new")
    end

    # it "routes to #show" do
    #   get("/deployment_window/series/1").should route_to("deployment_window/series#show", :id => "1")
    # end

    it "routes to #edit" do
      get("/environment/metadata/deployment_window/series/1/edit").should route_to("deployment_window/series#edit", :id => "1")
    end

    it "routes to #create" do
      post("/environment/metadata/deployment_window/series").should route_to("deployment_window/series#create")
    end

    it "routes to #update" do
      put("/environment/metadata/deployment_window/series/1").should route_to("deployment_window/series#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/environment/metadata/deployment_window/series/1").should route_to("deployment_window/series#destroy", :id => "1")
    end

  end
end
