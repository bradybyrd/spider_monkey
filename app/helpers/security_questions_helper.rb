################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

module SecurityQuestionsHelper

  def security_questions_page_heading
    if current_user_authenticated_via_rpm?
      "Set Security Question"
    else
      "Welcome"
    end
  end

  def security_questions_page_title
    if current_user_authenticated_via_rpm?
      "Set Security Question and Reset Password"
    else
      "Provide your Email, First & Last name"
    end
  end

  def security_questions_page_welcome_message
    if current_user_authenticated_via_rpm?
      "Please enter a new password and create a security question."
    else
      "Please provide following information"
    end
  end

end
