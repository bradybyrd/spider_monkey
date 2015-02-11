$ ->
  showErrors = (form, errors)->
    form.find('.field.error').removeClass('error')
    form.find('.error-msg').remove()
    $.each errors, (error)->
      input = form.find('#' + this.field)
      input.after($('<span class="error-msg"></span>').html(" " + this.message))
      input.closest('.field').addClass('error')

  validate = (form)->
    errors = []
    form.find('.required').each ->
      field = $(this)
      if field.val() == ''
        errors.push
          field: field.attr('id'),
          message: "required"
    errors

  $("form.schedule_request").submit (e)->
    form = $(this)
    errors = validate(form)
    if errors.length > 0
      showErrors(form, errors)
      e.preventDefault()
  $("form.schedule_request input.button-cancel").click (e)->
    e.preventDefault()
    jQuery(document).trigger('close.facebox')