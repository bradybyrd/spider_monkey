require 'spec_helper'

describe "deployment_windows/index" do
  pending "undefined method `new' for DeploymentWindow:Module" do
    before(:each) do
      assign(:deployment_windows, [
        stub_model(DeploymentWindow),
        stub_model(DeploymentWindow)
      ])
    end

    it "renders a list of deployment_windows" do
      render
      # Run the generator again with the --webrat flag if you want to use webrat matchers
    end
  end
end
