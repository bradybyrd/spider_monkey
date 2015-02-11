////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////
$(document).ready(function(){
  $('body').on('click', "#runtime_phases .delete_runtime_phase", function(event){
    event.preventDefault();
    delete_runtime_phase($(this));
  });
});

function delete_runtime_phase(current_link) {
  if(confirm("Are you sure you want to delete this runtime phase?")) {
    var deleted_value = $.trim(current_link.parent("td").prev("td").html());
    $.ajax({
      type: "DELETE",
      dataType: "json",
      url: current_link.attr("href"),
      success: function(data) {
        current_link.parent("td").parent("tr").remove();
        $("span.dynamic_fields div.field").each(function(index,value) {
          if(deleted_value == $(value).find("input").attr("value")){
            $(value).remove();
            return false;
          }
        });
      }
    });
  } else {
    return false;
  }
}
