////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

$.fn.preventLeavingWhenChanged = function() {
  var form = this;
  var changes = false;
  var markChanges = function() {
    if (! changes) {
      $('#pending').html("(changes pending)");
    }
    changes = true;
  };
  var clearChanges = function() {
    changes = false;
    $('#pending').html("");
    form.get(0).reset();
  }
  var warning = function(e) {
    if (changes) {
      var ignore_changes = confirm("Changes are pending on this tab.\n\n" +
									"They will be lost unless the form is updated.\n" +
									"Are you sure you want to continue?\n" +
									"Click 'OK' to continue without saving or 'Cancel' to return to the page.");
      if (! ignore_changes) {
        e.stopImmediatePropagation();
        e.preventDefault();
      } else {
        clearChanges();
      }
    }
  }

  this.find("input:not(.no_confirmation)").change(markChanges);
  this.find("input[type='text']:not(.no_confirmation)").keyup(markChanges);
  this.find("textarea:not(.no_confirmation)").change(markChanges).keyup(markChanges);
  this.find("select:not(.no_confirmation)").change(markChanges);
  $("a.cancel-pending").click(clearChanges);
  $("form#update_workstreams").submit(clearChanges);
  $("a:not(.ignore-pending):not(.cancel-pending)").bindFirst('click', warning);
}

$.fn.pendingChanges = function() {
	var form = this;
  var changes = false;
  var markChanges = function() {
  	if (! changes) {
			$('#pending').html("(changes pending)");
		}
 	};
	this.find("textarea:not(.no_confirmation)").change(markChanges).keyup(markChanges);		
}

