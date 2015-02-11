################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

module AppsHelper
  def options_for_teams
    teams = current_user.root? ? Team.name_order.all : current_user.teams
    options_for_select teams.map {|team| [team.name, team.id]}
  end
end
