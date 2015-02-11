window.Team.TeamForm =
  append: (element) ->
    $(element).appendTo $("#" + @id)
    return

  remove: (element) ->
    $(element).remove()
    return

  id: "team_form"