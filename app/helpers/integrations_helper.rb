################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module IntegrationsHelper

  def project_server_list(object_name="query")
    select_tag "#{object_name}[project_server_id]",
               "<option>Select Integration</option>" +
               options_for_select(@servers.collect {|s| [s.name, s.id]}, @query_details ? @query.project_server_id : nil),
               :onchange => "loadProjectServerData()"
  end

end

