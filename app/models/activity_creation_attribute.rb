################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ActivityCreationAttribute < ActiveRecord::Base
  
  self.sequence_name = "aca_seq" # aca => activity_creation_attributes
  
  belongs_to :activity_category
  belongs_to :activity_attribute

  attr_accessible :disabled
  
  validates :activity_category_id,
            :presence => true
  validates :activity_attribute_id,
            :presence => true
          
  acts_as_list :scope => :activity_category_id

  delegate :input_type, :name, :to => :activity_attribute, :allow_nil => true
  
  def default_creation_value
    # do it here
    result = nil
    case self.activity_attribute.name.downcase
      when "status"
        result = "Projected"

    end
    result
  end
end
