ExportCheckboxes =
  setup: ->
    $('#req_templates').change (event) ->
      checkboxesEnabledByRequestTemplates = $('.enabled-by-request-templates input')
      requestTemplatesCheckbox = $(@)
      if requestTemplatesCheckbox.is(':checked')
        checkboxesEnabledByRequestTemplates.prop('disabled', false)
      else
        checkboxesEnabledByRequestTemplates.prop('disabled', true)

window.ExportCheckboxes = ExportCheckboxes
