################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class TemporaryPropertyValue < ActiveRecord::Base

  attr_accessible :property_id, :request_id, :original_value_holder_id, :original_value_holder_type, :step_id, :value
  acts_as_audited
  belongs_to :step
  belongs_to :request
  belongs_to :property
  belongs_to :original_value_holder, :polymorphic => true

  validates :property_id,
            :presence => true
  validates :request_id,
            :presence => true
  validates :original_value_holder_id,
            :presence => true,
            :uniqueness => {:scope => [:original_value_holder_type, :property_id, :step_id, :deleted_at]}
  validates :original_value_holder_type,
            :presence => true


  def self.for (type, *id)
    if type.is_a? ActiveRecord::Base
      where(:original_value_holder_type => type.class.to_s, :original_value_holder_id => type.id)
    else
      result = where(:original_value_holder_type => type.to_s.camelize)
      result = result.where(:original_value_holder_id => id.first.to_i) if id.first
      result
    end
  end

  scope :in_order, order("original_value_holder_type, original_value_holder_id, created_at DESC")

  #FIXME: limits should not be put in a scope like this -- chaining issues
  scope :limited, lambda { |limit_val|
    {:order => "created_at DESC", :limit => limit_val}
  }

  def holder
    original_value_holder_type.constantize.find_by_id(original_value_holder_id)
  end

  def holder_name
    holder.name
  end

  def property_name
    prop = Property.find_by_id property_id
    prop.name
  end


  def value_label
    type_label = "none"
    cur = holder
    inactive = deleted_at.nil? ? "" : "-inactive"
    unless holder.nil?
      case original_value_holder_type
        when "InstalledComponent"
          type_label = "#{cur.application_component.app.name} - #{cur.component.name} - #{cur.application_environment.environment.name} (installed component)"
        when "Server"
          type_label = "#{cur.name} (server)"
        when "ServerAspect"
          type_label = "#{cur.name} (server-level)"
        when "ApplicationComponent"
          type_label = "#{cur.app.name} - #{cur.component.name} (application component)"
      end
    end
    local_owner = "#{request.number.to_s}/step[#{step.try(:number)}] - "
    local_owner + type_label + inactive
  end

  def display_value
    if self.property.is_private?
      self.mask_private_value(self.value)
    else
      self.value
    end
  end


  protected

  def mask_private_value(content_text = "")
    PropertyValue::MASK_CHARACTER * content_text.to_s.size
  end
end
