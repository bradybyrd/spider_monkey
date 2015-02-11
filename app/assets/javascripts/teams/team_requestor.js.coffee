window.Team.TeamRequestor =
  post: (url, data) ->
    $.post url, data  if url
    return

  get: (url, data) ->
    $.get url, data  if url
    return