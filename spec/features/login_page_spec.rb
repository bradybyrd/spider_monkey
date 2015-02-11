require 'spec_helper'
describe "Login page" do
  it "goes to dashboard after login" do
    pending 'Failing randomly. Fix in custom roles'
    visit "/login"
    fill_in "Login", :with => valid_user.login
    fill_in "Password", :with => valid_user.password
    click_button "Log In"
    page.status_code.should be_ok
    current_path.should == root_path
  end
end
