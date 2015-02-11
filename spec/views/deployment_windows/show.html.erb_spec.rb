require 'spec_helper'

describe "deployment_windows/show" do
  before(:each) do
    @deployment_window = assign(:deployment_window, stub_model(DeploymentWindow))
  end

  xit "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
