#= require filters_form
#= require jquery.contextMenu

window.Occurrences =
  showTooltip: ->
    if $("a.environment-link").length
      link = $("a.environment-link")
      title = ''
      link.attr('href', '')
      link.tooltip()
      link.on('click', (e) -> e.preventDefault())
      link.on('mouseenter', ->
          title = $(this).closest('td').attr('title')
          $(this).closest('td').attr('title', '')
        )
      link.on('mouseleave', ->
          $(this).closest('td').attr('title', title)
          title = ''
        )

  ContextMenu:
    LEFT_BUTTON: 0

    init: ->
      if arguments.length == 1
        selector = arguments[0]
      else if arguments.length == 2
        parentSelector = arguments[0]
        targetSelector = arguments[1]
        selector = "#{parentSelector} #{targetSelector}"

      $(document).on 'mouseup', ($event) =>
        @href = url_prefix + '/environment/metadata/deployment_window/events/' + $event.target.getAttribute('data-id') + '/popup'
        @coordinates =
          x: $event.clientX
          y: $event.clientY

      callback = ($event) ->
        $(this).contextMenu @coordinates if $event.button == Occurrences.ContextMenu.LEFT_BUTTON

      if arguments.length == 1
        $(selector).on 'mouseup', callback
      else if arguments.length == 2
        $(parentSelector).on 'mouseup', targetSelector, callback

      $.contextMenu
        selector: selector

        trigger: 'none'

        callback: (key, options) =>
          $.facebox({ajax: @href + '?popup_type=' + key })

        items:

          "edit":
            name: "Edit"
            className: 'edit'
            disabled: (key, root) ->
              disabled = $(this).data('in-past') || !$(this).data('can-edit')
              root.$menu.find('.edit').toggle !disabled
              disabled

          "request":
            name: "Schedule request",
            className: 'schedule'
            disabled: (key, root) ->
              disabled = $(this).data('behavior') == 'prevent' || $(this).data('event-state') == 'suspended' || $(this).data('aasm-state') == 'draft' || !$(this).data('can-schedule')
              root.$menu.find('.schedule').toggle !disabled
              disabled

  initContextMenu: (url)->
    if( /occurrences/.test(url) )
      parentSelector = 'body.deployment_window_occurrences #deployment_window_series_list'
      childSelector = 'td.environments a:not(.more-links)'
    else
      parentSelector = 'body.deployment_window_series #deployment_window_series_list'
      childSelector = 'td.environments a:not(.more-links)'

    $(parentSelector).unbind('mouseup')
    Occurrences.ContextMenu.init(parentSelector, childSelector)


$ ->
  $filters_form = $('body.deployment_window_occurrences form.filters')
  new FiltersForm $filters_form if $filters_form.length > 0

  $('body.deployment_window_occurrences #deployment_window_series_list')
    .on 'click', '.tablesorter a.more-links', ->
      $(@parentNode.parentNode.children).toggleClass('hidden')

  Occurrences.ContextMenu.init 'body.deployment_window_occurrences #deployment_window_series_list',
                               'td.environments a:not(.more-links)'
