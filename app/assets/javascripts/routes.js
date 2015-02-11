////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

$(function () {

    // Click handler for the routes available environments select all
    // check box to allow easy adding of all available environments to a route
    // table seemed to be the lowest bubble up container that would remain stable
    // during DOM updates
    $('table#environments_list').on('click', "input.check_all_input", function () {
        toggleCheckBox($(this).attr("check_box_dom"), $(this).is(':checked'));
    });

});