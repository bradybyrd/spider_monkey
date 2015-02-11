#= require ./team_scope
#= require ./group_checkbox_storage
#= require ./group_hidden_fields
#= require ./team_form
#= require ./team_requestor
#= require ./team_roles

#//////////////////////////////////////////////////////////////////////////////
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
#//////////////////////////////////////////////////////////////////////////////

GroupHiddenFields     = window.Team.GroupHiddenFields
GroupCheckboxStorage  = window.Team.GroupCheckboxStorage
TeamForm              = window.Team.TeamForm
TeamRequestor         = window.Team.TeamRequestor
TeamRoles             = window.Team.TeamRole

# Groups Selection
addRemoveTeamGroups = (checkbox, groupId) ->
  checked = $(checkbox).attr("checked")
  (if checked then addGroupsToTeam([groupId]) else removeGroupsFromTeam([groupId]))

addGroupsToTeam = (groupIds) ->
  url = $("#add_groups_team_url").val()
  TeamRequestor.post url, group_ids: groupIds

  GroupCheckboxStorage.add groupIds

removeGroupsFromTeam = (groupIds) ->
  url = $("#remove_groups_team_url").val()
  TeamRequestor.post url, group_ids: groupIds

  GroupCheckboxStorage.remove groupIds

selectAllTeamGroups = (checkboxes) ->
  groupIds = $.map(checkboxes, (el) ->
    $(el).attr("data-group-id")
  )

  # check all the checkboxes
  $.each checkboxes, (i, el) ->
    $(el).attr "checked", true

  addGroupsToTeam groupIds
  GroupCheckboxStorage.add groupIds

clearAllTeamGroups = (checkboxes) ->
  groupIds = $.map(checkboxes, (el) ->
    $(el).attr("data-group-id")
  )

  # uncheck all the checkboxes
  $.each checkboxes, (i, el) ->
    $(el).attr "checked", false

  removeGroupsFromTeam groupIds
  GroupCheckboxStorage.remove groupIds

# Apps Selection
addRemoveTeamApps = (checkbox, appId) ->
  checked = $(checkbox).attr("checked")
  (if checked then addAppsToTeam([appId]) else removeAppsFromTeam([appId]))

addAppsToTeam = (appIds) ->
  url = $("#add_apps_team_url").val()
  TeamRequestor.post url, app_ids: appIds

removeAppsFromTeam = (appIds) ->
  url = $("#remove_apps_team_url").val()
  TeamRequestor.post url, app_ids: appIds

selectAllTeamApps = (checkboxes) ->
  appIds = $.map(checkboxes, (el) ->
    $(el).attr "data-app-id"
  )

  $.each checkboxes, (i, el) ->
    $(el).attr "checked", true

  addAppsToTeam appIds

clearAllTeamApps = (checkboxes) ->
  appIds = $.map checkboxes, (el) ->
    $(el).attr "data-app-id"

  $.each checkboxes, (i, el) ->
    $(el).attr "checked", false

  removeAppsFromTeam appIds

# pagination
paginateGroupList = (clickedLink) ->
  page  = clickedLink.attr('data-page-number')
  url   = $("#alphabetic_pagination_url").val()
  data  = page: page
  $.get(url, data).done ->
    GroupCheckboxStorage.restoreCheckboxes()

# Roles
expandCollapseTeamApplicationForRoles = (clickedLink, appId) ->
  partial   = $("p#team_app_#{appId} > table")
  expanded  = partial.length > 0

  if expanded
    collapseTeamApplicationForRoles(partial)
  else
    expandTeamApplicationForRoles(clickedLink, appId)

expandTeamApplicationForRoles = (clickedLink, appId) ->
  url             = $('#expand_apps_for_roles_url').val()
  data            = app_id: appId

  $.get url, data, (partial) ->
      $("#team_app_" + appId).html partial

collapseTeamApplicationForRoles = (partial)->
  $(partial).remove()

# on load handlers
$ ->
  $(".team_apps_checkbox").live "change", (event) ->
    addRemoveTeamApps $(event.target), $(event.target).attr("data-app-id")

  $("#select_all_team_apps").live "click", (event) ->
    event.preventDefault()
    selectAllTeamApps $("#development_teams [data-default='false']")

  $("#clear_all_team_apps").live "click", (event) ->
    event.preventDefault()
    clearAllTeamApps $("#development_teams [data-default='false']").filter(':checked').not(':disabled')

  $("#team_groups_assignments input:checkbox").live "change", (event) ->
    addRemoveTeamGroups $(event.target), $(event.target).attr("data-group-id")

  $("#select_all_team_groups").live "click", (event) ->
    event.preventDefault()
    selectAllTeamGroups $("#user_list_of_groups [data-default='false']")

  $("#clear_all_team_groups").live "click", (event) ->
    event.preventDefault()
    clearAllTeamGroups $("#user_list_of_groups [data-default='false']").filter(':checked').not(':disabled')

  $('.groups_alphabetic_pagination a').live 'click', (event) ->
    event.preventDefault()
    paginateGroupList $(event.target)

  $('.expand_team_application a.expand_team_application_link').live 'click', (event) ->
    event.preventDefault()
    expandCollapseTeamApplicationForRoles $(event.currentTarget), $(event.currentTarget).attr('data-app-id')
