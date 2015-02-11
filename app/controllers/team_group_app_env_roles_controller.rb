# TODO: move this to API controller
class TeamGroupAppEnvRolesController < ApplicationController
  def set
    @thing = TeamGroupAppEnvRole.set(params[:team_group_app_env_role])

    render nothing: true
  end
end
