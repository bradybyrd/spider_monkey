////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

$(function () {

   $('body').on('submit', "#application_component_summary_form", function() {
     $.ajax({
       type: "GET",
       data: $(this).serialize(),
       url: $(this).attr("action"),
       success: function(data) {
					$("div#application_component_summary").html(data);
       }
    });
    return false;
  });

  $('.content li:has(ul)').click(function (event) {
    if (this == event.target) {
      if ($(this).children().is(':hidden')) {
        $(this).css('list-style-image', 'url(/images/triangle_unfolded_white_bg.gif)').children().slideDown()
      } else {
          $(this).css('list-style-image', 'url(/images/triangle_folded_white_bg.gif)').children().slideUp();
          $(this).find('ul').slideUp();
          $(this).find('li').css('list-style-image', 'url(/images/triangle_folded_white_bg.gif)');
        }
    }
    return false
    }).css({
        cursor: 'pointer',
        'list-style-image': 'url(/images/triangle_folded_white_bg.gif)'
    }).children().hide();
    $('li:not(:has(ul))').css({
        cursor: 'default',
        'list-style-image': 'none'
    })

  $('body').on('click', 'div.section a.clear_list', function(){
    if($('select#application_environment_ids').find('option class="clicked"')){
      $('#application_environment_ids option').removeClass('clicked').css({'background-color' : '#FFF'});
    }

    if($('select#component_ids, select#release_ids').find('option class="clicked"')){
      $('#component_ids option, #release_ids option').removeClass('clicked').css({'background-color' : '#FFF'});
    }

    if($('select#environment_ids, select#server_ids, select#server_level_ids').find('option class="clicked"')){
      $('#environment_ids option, #server_ids option, #server_level_ids option').removeClass('clicked').css({'background-color' : '#FFF'});
    }

    if($('select#app_ids, select#property_ids, select#server_aspect_group_ids').find('option class="clicked"')){
      $('#app_ids option, #property_ids option, #server_aspect_group_ids option').removeClass('clicked').css({'background-color' : '#FFF'});
    }
  });

});

