################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module ApplicationEnvironmentsHelper
  ENVIRONMENT_COLOR_CLASSES = %w{ environment_color_1 environment_color_2 }

  def class_for_environment_color(app_env)
    @app_env_memo ||= {}
    @environment_color_count ||= -1
    
    @environment_color_count += 1 if !app_env.respond_to?(:different_level_from_previous?) || app_env.different_level_from_previous?

    @app_env_memo[app_env.id] ||= ENVIRONMENT_COLOR_CLASSES[@environment_color_count % 2]
  end
end
