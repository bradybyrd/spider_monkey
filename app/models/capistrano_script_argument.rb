################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CapistranoScriptArgument < ScriptArgument
  include SharedScriptArgument

  # belongs_to :script, :class_name => 'CapistranoScript'
  
  # has_many :step_script_arguments, :dependent => :destroy, :as => :script_argument
  # serialize :choices, Array

  # validates :argument,:presence => true,:uniqueness => {:scope => "script_id"}
  # validates :name,:presence => true
  
end
