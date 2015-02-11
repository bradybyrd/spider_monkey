################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ActivityAttributeValue < ActiveRecord::Base
  belongs_to :activity
  belongs_to :activity_attribute
  belongs_to :value_object, :polymorphic => true
 
  attr_accessor :new_activity
  # TODO: RF: set activity default value
  after_initialize :set_attr_default
  attr_accessible :activity_attribute_id, :value,:new_activity,:activity_id

  
  validates :activity_attribute_id,
            :presence => true
  validates :activity_id,
            :presence => {:unless => Proc.new { |a| a.new_activity }}
  validates :value,
            :format => {
              :with => DATE_FORMATS[GlobalSettings[:default_date_format] || "%m/%d/%Y %I:%M %p"],
              :if => Proc.new { |a| a.activity_attribute.input_type == 'date' },
              :allow_blank => true
            }
  def value
    self[:value] || value_object
  end

  def value=(new_value)
    if activity_attribute.try(:from_system?)
      self.value_object_type = activity_attribute.value_type
      self.value_object_id = new_value
    else
      self[:value] = new_value
    end
  end

  def set_attr_default
    return unless new_record?
    new_activity = false
  end
end
