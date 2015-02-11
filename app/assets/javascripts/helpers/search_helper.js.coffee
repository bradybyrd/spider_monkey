InitSearch =
  init: (selector) ->
    @setPlaceholder()
    @bindEvents(selector)

  $form: ->
    $ @formSelector

  formSelector:
    'form.searchform'

  inputSelector:
    'input.searchbox'

  clearLinkSelector:
    'a'

  setPlaceholder: ->
    @$form().find(@inputSelector).placeholder()

  bindEvents: (selector) ->
    return if $(selector).length == 0
    @$form().find(@clearLinkSelector).on 'click', @clear
    @$form().on 'ajax:success', (evt, data, status, xhr) ->
      $(selector).html(data)

  clear: ->
    InitSearch.$form().find(InitSearch.inputSelector).val ''
    InitSearch.$form().submit()
    false

RPM.Helpers.InitSearch = (selector) ->
  InitSearch.init(selector)
