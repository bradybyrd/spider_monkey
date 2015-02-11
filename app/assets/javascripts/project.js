////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

$(function() {
    $('body').on('click', 'div.my_data_pagination a', function(event){
        event.preventDefault();
        var href = $(this).attr("href");
        var page_no = href.replace(/[^0-9]/g, '');
        var state_title = $(this).closest('div').attr('id');
        $.get($(this).attr('href'),{
            state: state_title
        }, function(data){
            if (state_title == "deleted_plan"){
                $("#deleted_plans").html(data);
            }else if(state_title == "archived_plan"){
                $("#archived_plans").html(data);
            }else{
                $("#plan_stage").html(data);
            }
            $("#pagination_plan_stage").show();
            $("#pagination_plan").html($("#pagination_plan_stage"));
            $("#functional_plans_"+page_no).tablesorter({
                sortList:[[0,0],[2,1]],
                widgets: ['zebra']
                });
            $("#archived_plans_"+page_no).tablesorter({
                sortList:[[0,0],[2,1]],
                widgets: ['zebra']
                });
            $("#deleted_plans_"+page_no).tablesorter({
                sortList:[[0,0],[2,1]],
                widgets: ['zebra']
                });

        });
    });
});

