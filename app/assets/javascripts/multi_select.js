////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

function customizeMultiSelect(){
  /* IE doesn't support event handling on option tag, hence conveted option click event to select onchange event*/
  $('body').on('change','.customize_multiselect', function(){
    var select = $(this);
    var sel_val = $(this).val();
    var sel_opt = '';
    $(select).find("option").each(function () {
        if($(this).val() == sel_val){
            sel_opt = $(this);
            return;
        }
    });
    if ($(sel_opt).attr("class") == undefined || $(sel_opt).attr("class").length == 0 || $(sel_opt).hasClass("unclicked")){
        $(sel_opt).removeClass('unclicked');
        $(sel_opt).addClass('clicked');
    } else {
        $(sel_opt).removeClass('clicked')
        $(sel_opt).addClass('unclicked');
        $(sel_opt).removeAttr("selected");
    }
    $(select).find("option.clicked").attr("selected","selected");
    $(select).find("option.unclicked").removeAttr("selected");
  });
}

