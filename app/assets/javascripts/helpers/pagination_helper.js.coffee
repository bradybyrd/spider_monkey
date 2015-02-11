AjaxPagination =
  ajaxify: (selector) ->
    $(selector).on 'click', '.server_side_tablesorter_pagination a', (e)->
      list = $(e.target).closest('.list')
      $.ajax
        type: "GET"
        url: $(this).attr("href")
      .done (responseText, status, jqXhr) ->
        list.html responseText
      false

RPM.Helpers.AjaxPagination = (selector) ->
  AjaxPagination.ajaxify(selector)
