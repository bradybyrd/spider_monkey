################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class SecurityAnswer < ActiveRecord::Base
  belongs_to :user
  
  SECURITY_QUESTIONS = { "Name of your first pet?" => 1, 
                         "What is your favorite animal?" => 2, 
                         "Make of your first car?" => 3, 
                         "Where you were born?" => 4,
                         "Name of your favorite city?" => 5}

  validates :answer,:presence => true
  
  attr_accessible :question_id, :answer

end
