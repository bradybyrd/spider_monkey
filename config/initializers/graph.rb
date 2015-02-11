################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class Graph

  %w(x_grid_color y_grid_color x_axis_color y_axis_color).each do |method|
    define_method("set_#{method}") do |a|
      self.instance_variable_set("@#{method}", a)
    end
  end

end
