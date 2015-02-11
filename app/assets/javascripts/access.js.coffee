$ ->
  $('#roles_map_form').on 'ajax:success', (e, data) ->
    $('#roles_map_summary').html(data)
  $('.clear_list').click ->
    $(this).parent().find('option.clicked').removeClass('clicked')