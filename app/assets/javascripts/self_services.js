////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

$(function() {
    $(".pageSection").hide();
    ajaxifyMyDataPagination();

    $('.app_env_srvr li a').click(function() {
        clickedLi = $(this).parent();
        clickedLiParent=clickedLi.parent();
        tabId=clickedLi.attr('tab');
        fetchTabContent(tabId,clickedLi,clickedLiParent);
        return false;
    });

    initialTabLoad();
});

function initialTabLoad() {
  var li = $('ul.my_dashboard_tabs li:first');
  if(!li.length > 0) { return; };
  li.addClass('current');
  var liParent = li.parent();
  var tabId = li.attr('tab');
  fetchTabContent(tabId, li, liParent);
};

function ajaxifyMyDataPagination(domSection){
    var links;
    if (domSection == undefined){
        links = ".my_data_pagination a";
    } else {
        links =  $("#" + domSection).find('a');
    }
    $(links).each(function(i) {
        $(this).bind('click',function(event){
            event.preventDefault();
            var parentDiv = $(this).parents('div:first');
            var clickedLink = parseInt(parentDiv.find("em.current").html());
            var pageNo=1;
            if ($(this).html().indexOf('Next') != -1){
                pageNo = clickedLink + 1;
            } else if ($(this).html().indexOf('Previous') != -1){
                pageNo = clickedLink - 1;
            } else {
                pageNo = parseInt($(this).html());
            }
            paginateMyData(pageNo, parentDiv.attr('rel'));
        })
    });
    return false;
}

function paginateMyData(pageNo, section){
    if ($("#" + section + "_" + pageNo).length > 0){
        hideTables(section)
        $("#" + section + "_" + pageNo).show();
        $("#" + section + "_pagination_" + pageNo).show();
    } else {
        if (section == "request_templates"){
            loadRequestTemplatesPage(section, pageNo);
        } else {
            loadMyData(section, pageNo);
        }
    }
}

function loadMyData(section, pageNo){
    $.get(url_prefix + '/' + section, {
        'page' : pageNo
    }, function(partial){
        initAfterLoad(section, pageNo, partial);
    });
}

function initAfterLoad(section, pageNo, partial){
    hideTables(section)
    $("#" + section).append(partial);
    ajaxifyMyDataPagination(section + '_pagination_' + pageNo);
}

function loadRequestTemplatesPage(section, pageNo){
    $.get(url_prefix + '/' + section + "?page=" + pageNo, $("#new_request").serialize(), function(partial){
        initAfterLoad(section, pageNo, partial);
    });
}

function hideTables(section){
    var sectionTables = $("#" + section).find('table').hide();
    $("#" + section + "_header").show();
}

function addInboundOutboundFilter(filterType){
  $('#filters_inbound_outbound_').remove();

  var $filterForm = $("#filter_form");
  var filter = $('<input>', {
        id: 'filters_inbound_outbound',
        name: 'filters[inbound_outbound][]',
        value: [filterType],
        type: 'hidden'
  });

  $filterForm.append(filter);
  disableForm($filterForm);
}

function fetchTabContent(tabId,clickedLi,clickedLiParent){
  $("#facebox_overlay").show();

  if ($("#" + tabId).length == 0){
    $.get(url_prefix + '/' + tabId, function(partial){
      $('#placeholder').remove();
      $('.app_env_srvr_content').append(partial);
      ajaxifyMyDataPagination();
    });
  }

  $("#" + tabId).show();
  showHideTabs(clickedLi,clickedLiParent);
  registerTableSorters();
  tablesorterTableHeaderArrowAssignment();

  $("#facebox_overlay").hide();
}

function showHideTabs(clickedLi,clickedLiParent)
{
    clickedLiParent.children().each(function(){
        if ($(this).attr('tab') == clickedLi.attr('tab')){
            $(this).addClass('current');
            $(this).find('a').addClass('current');

        } else {
            $(this).removeClass('current');
            $(this).find('a').removeClass('current');
            $("#" + $(this).attr('tab')).hide();
        }
    });

}

function toggleReleaseNames(app_id, object_class){
    $("#" + object_class + "_more_releases_" + app_id).toggle();
}
