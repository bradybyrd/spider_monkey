require "spec_helper"

describe AccountHelper do
  it "#system_setting_toggle" do
    helper.system_setting_toggle('company_name').should include("<input id=\"GlobalSettings_company_name\" name=\"GlobalSettings[company_name]\"")
  end

  context "#automation_path" do
    it "returns script path" do
      GlobalSettings.stub(:capistrano_enabled?).and_return(true)
      helper.automation_path.should eql(scripts_path)
    end

    it "returns nil" do
      helper.automation_path.should eql(nil)
    end
  end
end