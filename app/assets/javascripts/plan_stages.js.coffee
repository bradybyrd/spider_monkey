$ ->
  form = $("form.plan_stages")
  clearErrors = ->
    form.find('.field.error').removeClass('error')
    form.find('.errors').remove()

  showServerErrors = (errors)->
    clearErrors()
    errs = errors.map (error) -> "<li>#{error}</li>"
    header = "<p>This form contains #{errs.length} #{if errs.length > 1 then 'errors' else 'error'}</p>"
    errorsEl = $('<div class="errors error"></div>').html("#{header} <ul>#{errs.join('')}</ul>")
    form.find('.field:eq(0)').before(errorsEl)

  $(document.body).on 'ajax:success', 'form.plan_stages', (_, data) ->
    if data.errors
      showServerErrors data.errors
    else if data.request_path
      form.submit(false)
      jQuery(document).trigger('close.facebox')
      window.location.href = data.request_path

  form.find("input.button-cancel").click (e)->
    e.preventDefault()
    jQuery(document).trigger('close.facebox')

  form.find('#plan_stage_request_template_ids').change ->
    if !this.value
      request_template_id = '0'
    else
      request_template_id = this.value
    request_template_warning_url = url_prefix + '/request_templates/' + request_template_id + '/request_template_warning'
    $.get(request_template_warning_url, (data)->
      form.find('#request_template_warning').replaceWith(data)
    , "text")
