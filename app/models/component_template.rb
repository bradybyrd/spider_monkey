################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'open3'

class ComponentTemplate < ActiveRecord::Base

  belongs_to :app
  belongs_to :application_component

  validates :name,
            :presence => true,
            :uniqueness => { :unless => Proc.new { |ct| ct.name.nil? }}
  validates :app_id,
            :presence => true
  validates :application_component_id,
            :presence => true

  scope :of_app, lambda { |app_id| where(:app_id => app_id) }
  scope :active, where(:active => true)
  attr_accessible :name, :version, :active, :application_component_id, :description, :app_id

# BL Command is written in RAILS_ROOT/public/bladelogic/output_file.txt (Check this file to see what command executed and its status)

  class << self

    def run_sync_command(application_id)
      script_params = Hash.new
      run_time = Time.now.to_i
      script_params["SS_script_type"] = "component_sync"
      script_params["SS_script_target"] = "bladelogic"
      script_params["SS_sync_script_file"] = "#{AutomationCommon::DEFAULT_AUTOMATION_SUPPORT_PATH}/create_ss_component.jy"
      blscript = BladelogicScript.find(:first) #just to use instance methods
      ComponentTemplate.of_app(application_id).active.each do |ct|
        script_params["comp_#{ct.name}"] = "'#{ct.app.name}'__'#{ct.application_component.component.name}'"
      end
      script_params.merge!(AutomationCommon.build_params(script_params))

      contents = File.open(script_params["SS_sync_script_file"]).read
      AutomationCommon.init_run_files(script_params, contents)
      result = blscript.run_bladelogic_script(script_params, true)
      script_params["result"] = result
      script_params
    end
  end

  def component_template_headers
    "'#{app.name}' '#{application_component.component.name}' '#{name}'"
  end

  def is_active?
    active ? 'Yes' : 'No'
  end

end
