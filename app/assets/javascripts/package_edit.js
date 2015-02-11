////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////
$(function () {
    // copy the href for multi picker to new anchor
    var ele = $("#show_picker_link_for_property_id");
    ele.hide();
    var ele2 = $("#map_unmap_link_id");
    ele2.attr('href', $(ele).attr('href') );
});

