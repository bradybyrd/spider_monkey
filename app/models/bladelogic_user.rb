################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'fileutils'
require 'open3'

class BladelogicUser < ActiveRecord::Base
  include SharedScript

  belongs_to :streamdeploy_user, :class_name => 'User'

  has_many :roles, :class_name => 'BladelogicRole'

  def self.rbac_get_users_and_roles
    params = Hash.new
    params["SS_script_target"] = "bladelogic"
    params["SS_output_dir"] = AutomationCommon.get_output_dir('user_import')
    params["SS_output_file"] = "#{params["SS_output_dir"]}/output_#{Time.now.to_i}.txt"
    script_file = "#{AutomationCommon::DEFAULT_AUTOMATION_SCRIPT_LIBRARY_PATH}/bladelogic/rbac_export.jy"
    params["SS_script_file"] = script_file
    blscript = BladelogicScript.new
    params["SS_input_file"] = "#{params["SS_output_dir"]}/bl_users_#{Time.now.to_i}.txt"
    conts = File.open(script_file).read
    logger.info "SS__ rbac: #{script_file}\n#{conts}"
    AutomationCommon.init_run_files(params, conts)

    # Run the script
    result = blscript.run_bladelogic_script(params)
    # Result will return as ERROR: or Success: \n
    if result.slice(0..5) == "ERROR:"
      return nil
    else
      is_error = false
      result.split("\n").each do |line|
        if line =~ /STDERR/
          is_error = true
          break
        end
      end

      if is_error
        return nil
      else
        contents = File.open(params["SS_output_file"]).read
        ilen = contents.length
        isep = AutomationCommon.output_separator("RESULTS").length
        ipos = contents.index(AutomationCommon.output_separator("RESULTS"))
        userlist = contents.slice((ipos + isep + 1)..ilen)
        if userlist.length > 10
          return userlist.split("\n").map { |l| l.split(',') }
        else
          return nil
        end
      end
    end
  end

  def self.rbac_import
    users_to_import = self.rbac_get_users_and_roles
    return nil unless users_to_import
    logger.info "SS_rbac #{users_to_import.inspect}"
    new_users = 0
    users_to_import.each do |user, role|
      user.strip!
      role.strip!
      bladelogic_user = BladelogicUser.find_or_initialize_by_username(user)
      new_users += 1 if bladelogic_user.new_record?
      bladelogic_user.save!

      bladelogic_role = bladelogic_user.roles.find_or_initialize_by_name(role)
      bladelogic_role.save!
    end

    new_users
  end

end
