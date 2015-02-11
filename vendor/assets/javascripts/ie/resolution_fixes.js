////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

// Below code written For safari 4.0 and IE7 because due to 'min-width' issue.

$(document).ready(function() {
	if (screen.width>1024) {
		$("table.requestList").css('width','100%');
    $("#steps_container .subheader").css('width','100%');
	}
	else  {
 		$("table.requestList").css('width','850px');
    $("#steps_container .subheader").css('width','850px');
	}
});
