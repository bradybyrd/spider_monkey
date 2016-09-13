################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class Preference < ActiveRecord::Base
    
  belongs_to :user
  
  attr_accessible :text, :active, :position,:preference_type
  
  scope :active, where("preferences.active" => true)
  
  validates :text,:presence => true
  validates :preference_type,:presence => true
  # normalize attributes by default does name and title
  normalize_attributes :text
  
  def preference_label
    text.gsub(/activity_|_td/, '')
  end
  
end
