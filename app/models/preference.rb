################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class Preference < ActiveRecord::Base
  
  concerned_with :request_list_preference
  concerned_with :step_list_preference
  
  belongs_to :user
  
  attr_accessible :text, :active, :position,:preference_type
  
  scope :active, where("preferences.active" => true)
  
  validates :text,:presence => true
  validates :preference_type,:presence => true
  # normalize attributes by default does name and title
  normalize_attributes :text
  
  def preference_label
    text.gsub(/request_|_td/, '')
  end

  def step_preference_label
      text.gsub(/step_|_td/, '')
  end
  
end
