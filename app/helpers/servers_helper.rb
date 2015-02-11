################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module ServersHelper
  def servers_tab_path
    if cannot? :list, Server.new
      return server_groups_path if can? :list, ServerGroup.new
      return server_aspect_groups_path if can? :list, ServerAspectGroup.new
    end
    servers_path
  end
end
