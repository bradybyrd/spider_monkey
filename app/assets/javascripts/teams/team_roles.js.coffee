class TeamRole
  @selector = {
    selectBox:  'select.role_in_app_list'
    setRoleUrl: '#team_group_app_env_roles_create_url'
  }

  handlers: ->
    self        = this
    selectBox   = $(TeamRole.selector.selectBox)
    $(selectBox).live("change", ->
      self.setRoleForEnvironment($(this))
    )

  setRoleForEnvironment: (roleList) ->
    self  = this
    url   = this._setRoleForEnvironmentUrl()
    data  = this._setRoleForEnvironmentData(roleList)

    request = $.post(url, data)
    request.progress(self._showSpinner(roleList))
    request.complete(self._hideSpinner(roleList))

  # private
  _showSpinner: (element) ->
    element.hide().spin()
    this

  _hideSpinner: (element) ->
    element.show().stopSpin()
    this

  _setRoleForEnvironmentUrl: ->
    $(TeamRole.selector.setRoleUrl).val()

  _setRoleForEnvironmentData: (roleList) ->
    data  = {
      team_group_app_env_role: {
        role_id:                    roleList.find('option:selected').val()
        team_group_id:              roleList.attr('data-team-group-id')
        application_environment_id: roleList.attr('data-application-environment-id')
        # app_id:         roleList.attr('data-app-id')
      }
    }

window.Team.TeamRole = new TeamRole()