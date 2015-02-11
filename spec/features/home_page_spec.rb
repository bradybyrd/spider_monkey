require 'spec_helper'
describe "Home page" do
  it "displays the user's username after successful login", :smoke => true do
    user = valid_user
    sign_in(user)
    visit root_path
    page.status_code.should be_ok
    page.should have_content(user.first_name)
  end
end
