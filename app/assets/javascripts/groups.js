////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

//$(document).ready(function() {
 //  customizeMultiSelect();
  // });


// These methods can also be used on other pages wherever required.

function set_options_of_select_list(unselected_values, select){
  $.each(unselected_values, function(index, value){
 		$(select).find("option[value='" + value + "']").hide().attr("disabled", "disabled");
  });
}
 
function add_to_select_1(){
  $('.select_2 :selected').each(function(i, selected){
  	$(".select_1").find("option[value='" + $(selected).val() + "']").removeAttr("disabled").show();
  	$(".select_2").find("option[value='" + $(selected).val() + "']").hide();
  });
  select_all_options('.select_1 option')
}
 
function remove_from_select_1(){
 	$('.select_1 :selected').each(function(i, selected){
 		$(".select_1").find("option[value='" + $(selected).val() + "']").hide().attr("disabled", "disabled");
 		$(".select_2").find("option[value='" + $(selected).val() + "']").removeAttr("disabled").show();
  });
 	$('.select_1 option').each(function(i) {  $(this).attr('selected', 'selected');});
 	$('.select_2 option').each(function(i) {  $(this).removeAttr('selected');});
}
 
function select_all_options(select){
 	$(select).each(function(i) {  $(this).attr('selected', 'selected');});
}
