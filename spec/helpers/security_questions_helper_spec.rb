require "spec_helper"

describe SecurityQuestionsHelper do
  before(:each) { helper.stub(:current_user_authenticated_via_rpm?).and_return(true) }

  context "#security_questions_page_heading" do
    specify "authenticated via rpm" do
      helper.security_questions_page_heading.should eql("Set Security Question")
    end

    specify "authenticated via another method" do
      helper.stub(:current_user_authenticated_via_rpm?).and_return(false)
      helper.security_questions_page_heading.should eql("Welcome")
    end
  end

  context "#security_questions_page_title" do
    specify "authenticated via rpm" do
      helper.security_questions_page_title.should eql("Set Security Question and Reset Password")
    end

    specify "authenticated via another method" do
      helper.stub(:current_user_authenticated_via_rpm?).and_return(false)
      helper.security_questions_page_title.should eql("Provide your Email, First & Last name")
    end
  end

  context "#security_questions_page_welcome_message" do
    specify "authenticated via rpm" do
      helper.security_questions_page_welcome_message.should eql("Please enter a new password and create a security question.")
    end

    specify "authenticated via another method" do
      helper.stub(:current_user_authenticated_via_rpm?).and_return(false)
      helper.security_questions_page_welcome_message.should eql("Please provide following information")
    end
  end
end
