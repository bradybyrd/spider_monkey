################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ScriptArgument < ActiveRecord::Base
  include SharedScriptArgument

  belongs_to :script, :class_name => 'Script'
  
  has_many :step_script_arguments, :dependent => :destroy, :as => :script_argument
  
  # serialize :choices, Array

  validates :argument,
            :presence => true,
            :uniqueness => {:scope => "script_id"}
  validates :name,:presence => true

  scope :input_arguments, where("script_arguments.argument_type not in (?)", Script::SUPPORTED_AUTOMATION_OUTPUT_DATA_TYPES)
  
  scope :output_arguments, where("script_arguments.argument_type not in (?)", Script::SUPPORTED_AUTOMATION_INPUT_DATA_TYPES)

  before_save :set_script_arguments

  def set_script_arguments
    self.is_required = false if is_required.blank?
    self.created_by = User.current_user.try(:id)
    self.argument_type = "in-text" if argument_type.blank?
    true
  end

  # TODO We need to add `type` STI column in `script_arguments` so that it supports
  # CapistranoScript Arguments & HudsonScript Arguments.
  # Today it holds only HudsonScript Arguments.
    
end
