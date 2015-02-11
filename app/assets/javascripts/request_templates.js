////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

function setTeamName(){
	//var form = $(this).parents('form:first');
	var team_name;
	team_name = $("#teams option:selected").text();
	$("#team_name").val(team_name);
	//hiddenField = '<input type="hidden" id="team_name" name="team_name" value =' + team_name + '/>';
	//form.append(hiddenField)
}

function requestTemplateAlphabeticalPagination(){
  if ($('.alpha_pagination').children().eq(1).attr('id') == 'current_page')
  {
    $('.alpha_pagination').find('a:first').hide();
  }
  if ($('.alpha_pagination a:last-child').prev().attr('id') == 'current_page')
  {
    $('.alpha_pagination a:last-child').hide();
  }

  $('body').on('click', ".alpha_pagination a", function(event) {
      event.preventDefault();
      var div_id = $(this).attr("class_name");
      var href = $(this).attr("href");
      var pageNo = $(this).attr("href").match(/page=([0-9]+)/);
       var pagination_link = $(this);
      $.get(href, { page: pageNo, "render_no_rjs": "true"}, function(data) {
         $('#' + div_id).html(data);
         $('#' + resultContainerId(pagination_link)).html(data);
        if(href != undefined && href.indexOf("environment/request_templates") != -1) {
          $('#new_request input, #new_request select').change();
          $("div#request_templates").find("div.alpha_pagination").each(function() {
            $(this).find("a").each(function() {
              $(this).attr('href', href.replace("page="+getUrlVars(href,"page"),"page="+getUrlVars($(this).attr('href'),"page")));
            });
          });
        }
        requestTemplateAlphabeticalPagination();
       });
   });
}

//----------- On DOM ready

$(function() {
  $('body').on('click', '.choose_template', function(e) {
    e.preventDefault();
    $.get(url_prefix + "/requests/choose_environment_for_template", {"request_template_id": $(this).data("id")}, function(html) {
      if (html == ""){
      } else {
        $.facebox(html);
      }
    });
  });

  $('body').on("ajax:beforeSend", "#new_request_template", function() {
    showLoader();
  });
  $('body').on("ajax:complete", "#new_request_template", function() {
    hideLoader();
  });
});
