window.Team.GroupHiddenFields =
  add: (values) ->
    self = this
    $.map values, (value) ->
      input = $("<input>").attr(
        id: self.id
        name: self.name
        type: "hidden"
        value: value
        multiple: "multiple"
      )
      window.Team.TeamForm.append input
      return

    return

  remove: (values) ->
    self = this
    $.map values, (value) ->
      input = $("input#" + self.id + "[value=\"" + value + "\"]")
      window.Team.TeamForm.remove input
      return

    return

  id: "team_group_ids"
  name: "team[group_ids][]"