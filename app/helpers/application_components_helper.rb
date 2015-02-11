################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module ApplicationComponentsHelper
  APPLICATON_COMPONENT_COLOR_CLASSES = %W{ even_component_level odd_component_level }

  def class_for_application_component_color(app_component)
    @app_component_count ||= -1

    @app_component_count += 1 if app_component.different_level_from_previous?

    APPLICATON_COMPONENT_COLOR_CLASSES[@app_component_count % 2]
  end
end
