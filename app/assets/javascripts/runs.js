////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////
var PlanRun = {
  bindEvents: function () {
    $('body').on('ajax:success', 'form.start_run', PlanRun.onStart);
  },

  onStart: function (event, data) {
    var $form = $(this);
    if (data.errors) {
      PlanRun.showErrors($form, data.errors);
    } else {
      window.location.href = data.url;
    }
  },

  showErrors: function ($target, errors) {
    $target.closest('.run_detail').next(".errorExplanation").html(errors.join("<br/>"));
  }
};

$(document).ready(function() {
	var plan_id = $("#run_detail").attr("data-plan-id");
	var run_id = $("#run_detail").attr("data-run-id");
	if (plan_id && run_id) {
		var refreshId = setInterval(function() {
			refreshRun(plan_id, run_id)
		}, 30000);
		$.ajaxSetup({
			cache : false
		});
	}
  PlanRun.bindEvents();
});
function refreshRun(plan_id, run_id) {
        var selected_requests = [];
        $("tr.plan_row td input[type=checkbox]").each(function(){
            if($(this).attr("checked") != undefined){
                selected_requests.push($(this).val());
            }
        });
	$.get(url_prefix + "/plans/" + plan_id, {
		'run_id' : run_id,
		'refresh' : 'true',
                'sel_request': selected_requests
	}, function(data) {
		$("#plan_stages").html(data);
	});
}