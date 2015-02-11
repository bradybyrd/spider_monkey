////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

var count = 0;

$(function() {
	$('a#delete_requests').livequery(function(){
            $(this).click(delete_bulk_requests);
        });
});

function delete_bulk_requests(){
	var request_ids = [];
        var req_fliter_flag = $("#filter_block_collapse_state_flag").attr("value") ;

	$('td.delete_request :checked').each(function(){
		request_ids.push($(this).parents('tr:first').attr('id').replace(/request_row_/, ''));
	});
	if (request_ids.length == 0){
		alert("Please select at least one request to delete.");
		return false;
	} else {
		var answer = confirm("Are you sure you want to delete the selected requests?");
	  if (answer){
			$.ajax({
		  	type: "delete",
                dataType: "text",
				url: url_prefix + "/settings/bulk_destroy",
				data: {"request_ids[]":request_ids},
				success: function(){
					$.each(request_ids, function(index, value) {
						$('#request_row_'+value).find('td.status a div').addClass('deletedRequestStep');
						$('#request_row_'+value).find('td.status a div').html('deleted');
						$('td.delete_request :checked').each(function(){
							$(this).removeAttr("checked")
							$(this).attr('disabled','disabled');
						});
						$('body').on('click', 'a#delete_requests', delete_bulk_requests);
						$('a#delete_requests').hide();
						$('#select_all_chk').removeAttr("checked")
					});
                    window.location = url_prefix + "/settings/bulk_destroy?filter_block_collapse_state_flag=" + req_fliter_flag;
				}
			});
		} else {
			return false;
		}
	}
}

function select_bulk_requests(chk_box){
	if (chk_box.is(':checked')){
		if (chk_box.attr('id') == 'select_all_chk'){
			count = $("input[type='checkbox']").length - 1
		} else {
			count += 1;
		}
	} else {
			if (chk_box.attr('id') == 'select_all_chk'){
				count = 0;
			} else {
				count -= 1;
			}
	}
	if (count > 0) {
		$('a#delete_requests').show();
	} else {
		$('a#delete_requests').hide();
	}
	return false;
}
