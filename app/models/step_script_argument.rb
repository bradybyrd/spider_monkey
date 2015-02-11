################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class StepScriptArgument < ActiveRecord::Base

  class JsonWrapper
    def self.load(string)
      string.nil? ? string : (string.valid_json? ? JSON.parse(string) : string)
    end

    def self.dump(value)
      value.blank? ? value : value.to_json
    end
  end  
  
  acts_as_audited
  belongs_to :step

  # We need to preserver polymorphic for now till we completely depricate BladeLogic jython support
  belongs_to :script_argument, :polymorphic => true

  has_many :uploads, :as => :owner  
  # allow for uploads (a.k.a. assets) to be set through a nested form and updated without special 
  # attribute accessors and prevalidation hooks.  This provides passthrough validatin messages to those forms.
  accepts_nested_attributes_for :uploads, :reject_if => lambda { |a| a[:attachment].blank? }, :allow_destroy => true  

  serialize :value, JsonWrapper

  delegate :argument, :to => :script_argument
  attr_accessible :script_argument, :value, :script_argument_id, :script_argument_type, :uploads_attributes

end