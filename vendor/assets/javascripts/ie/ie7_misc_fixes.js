////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////
// Below code written For IE7 to resolve table header multiple background support issue.
$(document).ready(function() {
//    $('.sortable.asc').append('<span class="asc">&nbsp;</span>')
//    $('.sortable.asc').addClass('IE7asc').removeClass('asc');
//    $('.sortable.desc').append('<span class="desc">&nbsp;</span>')
//    $('.sortable.desc').addClass('IE7desc').removeClass('desc');

      sortable_table_header_arrow_assignment();
      tablesorterTableHeaderArrowAssignment();
});
