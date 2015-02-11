################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module TableHelper
  def sortable_link(title, column)
    sort_direction_css = sort_direction == 'asc' ? 'Down' : 'Up'
    css_class = column == sort_column ? "headerSort#{sort_direction_css}" : nil
    direction = column == sort_column && sort_direction == 'asc' ? 'desc' : 'asc'
    sort_params = { sort: column, direction: direction }
    link_to title, sort_params, { class: "#{css_class} sortable-link" }
  end
end
