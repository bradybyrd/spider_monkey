require 'spec_helper'

describe "deployment_windows/edit" do
  before(:each) do
    @deployment_window = assign(:deployment_window, stub_model(DeploymentWindow))
  end

  xit "renders the edit deployment_window form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => deployment_windows_path(@deployment_window), :method => "post" do
    end
  end
end
