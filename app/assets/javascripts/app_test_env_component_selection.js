////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2014
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////
$(function() {
    $('#step_related_object_type').change(function() {
        $('#component_group').hide();
        $('#package_group').hide();
        $('#' + $(this).val().toLowerCase() + "_group").show();
    });
});
