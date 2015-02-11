################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module AccountHelper
  def system_setting_toggle(setting, reload_window_on_update  = false, disabled = false)
    field_name = "GlobalSettings[#{setting}]"
    html = ''
    html << hidden_field_tag(field_name, false)
    html << check_box_tag(field_name, true, GlobalSettings[setting], :class => 'checkbox', :reload_window_on_update  => reload_window_on_update ?  true : false, :disabled => disabled)
    html.html_safe
  end

  def automation_path
    if GlobalSettings.capistrano_enabled? || GlobalSettings.hudson_enabled?
      scripts_path
    else
      nil
    end
    # GlobalSettings.capistrano_enabled? ? capistrano_path :
    #   (GlobalSettings.bladelogic_enabled? ? bladelogic_path :
    #     (GlobalSettings.hudson_enabled? ? hudson_path : nil ))
  end
end
