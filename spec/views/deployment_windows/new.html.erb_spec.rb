require 'spec_helper'

describe "deployment_windows/new" do
  pending "undefined method `new' for DeploymentWindow:Module" do
    before(:each) do
      assign(:deployment_window, stub_model(DeploymentWindow).as_new_record)
    end

    it "renders new deployment_window form" do
      render

      # Run the generator again with the --webrat flag if you want to use webrat matchers
      assert_select "form", :action => deployment_windows_path, :method => "post" do
      end
    end
  end
end
