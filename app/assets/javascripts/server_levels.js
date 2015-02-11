////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

$(function() {  
	ajaxifyMyDataPagination(); 

});

function ajaxifyMyDataPagination(domSection){
	if (domSection == undefined){
		var links = ".my_data_pagination a";
	} else {
		alert('else');
		var links =  $("#" + domSection).find('a');
	}
	$(links).each(function(i) {
		$(this).bind('click',function(event){
		event.preventDefault();
		var parentDiv = $(this).parents('div:first');
		var clickedLink = parseInt(parentDiv.find("span.current").html());
		if ($(this).html() == 'Next »'){
			var pageNo = clickedLink + 1;
		} else if ($(this).html() == '« Previous'){
			var pageNo = clickedLink - 1;
		} else {
			var pageNo = parseInt($(this).html());
		}
		paginateMyData(pageNo, $(".my_data_pagination").attr('rel'));
		})
	});
	return false;
}

function paginateMyData(pageNo, section){
	var sectionTables = $("#" + section).find('table').hide();
	if ($("#" + section + "_" + pageNo).length > 0){
		$("#" + section + "_" + pageNo).show();
		$("#" + section + "_pagination_" + pageNo).show();
	} else {
		var server_levels_param = $("#server_levels_params").attr('value');
		var extra_params = $("#extra_params").attr('value');
						
	 jQuery.ajax({
  		dataType: 'script',
  		type: 'get',
		url: url_prefix + '/environment/' + section + '/' + server_levels_param + '?_=' + extra_params + '&page=' + pageNo
  	});

	}
}
