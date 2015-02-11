////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

$(document).ready(function(){
	$('.content').find('a, input, select').attr('disabled', false)
	$("#promotionForm").find("#application_id").val('');
        $('body').on('click', '#btn-create_p_table', function(){$('#promotion_table').show()});
});

function showPromoteTable() {
    $('#btn-create-promotion').hide();
    $('#create_promotion').show().css('margin-top', '-20px');
    $('#filters-requests').hide();
    $('.filterSection').hide();
}

function hidePromoteTable(){
    $('#btn-create-promotion').show();
    $('#create_promotion').css('margin-top', '0px').hide();
    $('#filters-requests').show();
    $('.filterSection').show();
}

function hidePromotionTable()
{
    $('#promotion_table').hide();
}



function saveRequestPromotion(templateId) {
  var promotionForm = $('#template_' + templateId);

	$.each(['name', 'app_id', 'environment_id','activity_id', 'release_id'], function(index, value) {
	  inputFieldVal = $("#promotion_form").find('#' + value).val();
		promotionForm.find('#request_' + value + '"').val(inputFieldVal);
	});
	promotionForm.find('#request_promotion').val('1');
	promotionForm.submit();
  $('.content').find('a, input, select').attr('disabled', 'disabled')
}

function toggleHeaderChecked(chck_box) {
    var togglevalue;
    if (chck_box.is(':checked'))
        togglevalue=true;
    else
        togglevalue=false;

    $("#list_of_components :checkbox").each( function() {
  
        $(this).attr('checked', togglevalue);
    });
}

function loadEnvforPromotion(app_list) {
    if (app_list.val() != ''){
        $.ajax({
            data:'app_id=' + app_list.val(),
            dataType:'script',
            type:'post',
            url: url_prefix + '/environments_of_app',
            success: function(){$('#generate_promotions').show();}

           })
    }
}
