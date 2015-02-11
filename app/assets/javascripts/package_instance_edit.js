////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////
 function save_add_references_clicked(){

    $("#auto_submit_id").remove();
    $("name['package_instance[selected_reference_ids][]']").remove();

    $('input[type="checkbox"]:checked').each(function() {
      $('<input>').attr({
        type: 'hidden',
        name: 'package_instance[selected_reference_ids][]',
        value: this.value
      }).appendTo('form');       
    });
    $('<input>').attr({
      id: 'auto_submit_id',
      type: 'hidden',
      name: 'auto_submit',
      value: 'y'
    }).appendTo('form');       
    $( "form" )[0].submit();
 }

