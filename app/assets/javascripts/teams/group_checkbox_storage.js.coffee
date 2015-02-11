window.Team.GroupCheckboxStorage =
  add: (values) ->
    storage = this.storage()
    window.Team.GroupHiddenFields.add _.difference(values, storage)
    @_storage = _.union(storage, values)
    return

  remove: (values) ->
    storage = this.storage()
    @_storage = _.difference(storage, values)
    window.Team.GroupHiddenFields.remove values
    return

  restoreCheckboxes: ->
    storage = this.storage()

    # filter checkboxes to select only those that are in the storage
    checkboxes = @checkboxes().filter(->
      return $.inArray($(this).attr("data-group-id"), storage) >= 0
    )

    $.each checkboxes, (i, el) ->
      $(el).attr "checked", true

    return

  checkboxes: ->
    $ "#user_list_of_groups input:checkbox"

  storage: ->
    @_storage

  _storage: []