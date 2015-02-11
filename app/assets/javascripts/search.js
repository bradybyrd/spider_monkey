////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

$(document).ready(function() {
  $('body').on('keypress', '#search_form, #server_level_search_form', function(e){
    if(e.which == 13){
        e.preventDefault();
        $('#search_button').click();
     }
  });    
  ajaxifyAlphabeticalPagination();
});

function search(){
  var url = $("#key").parent("form:first").attr("action");
  var key = $("#key").val();
  var child_dom_1 = $('div#content_box').children().eq(1).attr('id');
  var child_dom_2 = $('div#content_box').children().eq(2).attr('id');
  var child_dom_3 = $('div#content_box').children().eq(3).attr('id');
  var cond = ((child_dom_1 || child_dom_2 || child_dom_3) == 'server_container');
  $.get(url_prefix + url, {"key": key, "render_no_rjs": "true"}, function(results){
    if (cond){
      if($('#server_container div:first').attr('id') == 'server_search_result'){
        $("#server_search_result").html(results);
      }else{
        $("#server_container").html(results);
      }
    }else{
      $("#search_result").html(results);
    }
    ajaxifyAlphabeticalPagination();
  });
}

function clearSearch(){
  var url = $("#key").parent("form:first").attr("action");
  var child_dom_1 = $('div#content_box').children().eq(1).attr('id');
  var child_dom_2 = $('div#content_box').children().eq(2).attr('id');
  var child_dom_3 = $('div#content_box').children().eq(3).attr('id');
  var cond = ((child_dom_1 || child_dom_2 || child_dom_3) == 'server_container');
  $.get(url_prefix + url, {"render_no_rjs": "true"}, function(records){
    $("#key").val('');
    if (cond){
      if($('#server_container div:first').attr('id') == 'server_search_result'){
        $("#server_search_result").html(records);
      }else{
        $("#server_container").html(records);
      }
    }else{
      $("#search_result").html(records);
    }
    ajaxifyAlphabeticalPagination();
  });
}

