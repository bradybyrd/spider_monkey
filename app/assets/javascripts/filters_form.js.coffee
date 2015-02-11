window.FiltersForm = class
  constructor: (@form) ->
    @enableToggling()
    @filters = []
    $('.selected_values').each (i, element) =>
      @filters.push new Filter $(element.parentNode), @form
    @form.find('.clear_request_filters').on 'click', @clear
    @form.on 'ajax:success', (evt, data, status, xhr) ->
      if $('#occurrence-list').length
        $('#occurrence-list').html(data)
      else
        $('#series-lists').html(data)

      $(@).find('#clear_filters').attr('disabled', true)

  enableToggling: ->
    @form.parents('#filterSection').prev().find('a').on 'click', (event) ->
      $('#filterSection').toggle =>
        newText = $(@).data 'placeholder'
        $(@).data 'placeholder', @innerHTML
        @innerHTML = newText
      false
    @ifFilterNotEmpty()

  ifFilterNotEmpty: ->
    if @form.parents('#filterSection').find('#not_empty_filter').length > 0
      @form.parents('#filterSection').show()
      link = @form.parents('#filterSection').prev().find('a')
      link.data 'placeholder', 'Open Filters'
      link.text 'Close Filters'

  clear: =>
    for filter in @filters
      filter.clear()
      filter.showSelected()
      filter.renameAdd()
    @form.find('#clear_filters').attr('disabled', false)
    @form.submit()
    false

class Filter
  constructor: (@tdContainer, @form) ->
    @addLink = @tdContainer.find '.selected a'
    @doneLink = @tdContainer.find '.values_to_select a:nth-of-type(1)'
    @cancelLink = @tdContainer.find '.values_to_select a:nth-of-type(2)'
    @clearLink = @tdContainer.find '.values_to_select a:nth-of-type(3)'
    @formElement = @tdContainer.find '.values_to_select select'
    @formElement = @tdContainer.find '.values_to_select input' if @formElement.size() == 0
    @valuesToSelect = @tdContainer.find '.values_to_select'
    @selectedValues = @tdContainer.find '.selected'

    @addLink.on 'click', @show
    @doneLink.on 'click', @done
    @cancelLink.on 'click', @cancel
    @clearLink.on 'click', @clear
    @formElement.on 'change', @changed

    @showSelected @formElement.find('option:selected')
    @renameAdd()

  show: =>
    @showSelect()
    if @selected?()
      @showDone()
      @showClear()
    else
      @hideClear()
    @showCancel()
    @hideAdd()
    false

  done: =>
    @form.submit()
    @showSelected @formElement.find('option:selected')
    @cancel() if @formElement[0].tagName == 'SELECT'
    @renameAdd()
    false

  cancel: =>
    @hideSelect()
    @hideDone()
    @hideCancel()
    @showAdd()
    @hideClear()
    false

  clear: =>
    @formElement.val []
    @hideClear() if @formElement[0].tagName == 'SELECT'
    false

  selected: ->
    @formElement.val?() and @formElement.val().length > 0

  showSelect: ->
    @valuesToSelect.show()
    @formElement.show()

  showDone: ->
    @doneLink.show()

  showCancel: ->
    @cancelLink.show()

  hideAdd: ->
    @addLink.hide()

  showClear: ->
    @clearLink.show()

  hideClear: ->
    @clearLink.hide()

  hideSelect: ->
    @formElement.hide()
    @formElement.val @formElement.data('values')

  hideDone: ->
    @doneLink.hide()

  hideCancel: ->
    @cancelLink.hide()

  showAdd: ->
    @addLink.show()

  renameAdd: ->
    if @selected?()
      @addLink.html 'edit'
    else
      @addLink.html 'add'

  showSelected: (selected = []) ->
    values = (option.value for option in selected)
    selectedStrings = (option.innerHTML for option in selected)
    @formElement.data('values', values)
    @selectedValues.find('span').remove()
    @selectedValues.prepend $("<span class='multivalues'>#{selectedStrings.join(', ')}</span>")

  changed: =>
    if @selected?()
      @showDone()
      @showClear()
    false
