////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////
$(function() {
//STEP PART Move this section in steps.js
  $('body').on('click','#step_form_tabs .pageSection ul li', function(event){
       event.preventDefault();
       $('#step_form_tabs .pageSection ul li').attr('class','');
       $(this).attr('class','selected');

       $('#step_form_tabs .content .step_tab_area').hide();
       if ($(this).attr('id') == "st_automation"){

        $('#' + $(this).attr('id') + '_step_tab_area').show('fast', function(){
           // Moved this callback action to automation partial
           // if ($(this).attr("do_not_trigger") == undefined){
               // updateTargetArgumentId(); // This function is present in shared_resource_automation.js
               // triggerResourceAutomation(); // This function is present in shared_resource_automation.js
           //     $(this).attr("do_not_trigger", true);
           // }
        });
       } else {
              $('#' + $(this).attr('id') + '_step_tab_area').show();
       }
       if(($(this).attr('id') == 'st_tickets') && ($('#st_tickets a').attr('data-remote') !== undefined)){
          $('#ticket_selection_sections').html('');
          $('#ticket_selection_sections').attr('class', 'ticket_data_wait');
       }
       var clicked_area_tab_anchor = $(this).find('a');

       if($(this).attr('id') != 'st_tickets' && $(this).attr('id') != 'st_general' && !clicked_area_tab_anchor.hasClass('tab_loaded')){
            $('#inside_facebox_overlaydiv').attr('style', 'display:block !important');
            $('#wait_inside_facebox').attr('style', 'display:block !important');
            li_id = $(this).attr('id');

            $.get($('#step_form_tabs').attr('data-url'), {'li_id' : li_id, 'related_object_type' : getRelatedObjectType()}, function(data){
                $('#'+li_id + '_step_tab_area').html(data);

                // content tab needs to be loaded whenever it is called since type, package and package instance
                // dropdowns can changes its display. Do not mark content tab as loaded
                if(li_id !== 'st_content') {
                    clicked_area_tab_anchor.attr('class', 'tab_loaded');
                }

                $('#inside_facebox_overlaydiv').attr('style', 'display:none !important');
                $('#wait_inside_facebox').attr('style', 'display:none !important');
            }, "html");
        }
  });
//STEP PART

//New tickets selection methods
 $('body').on('click', '#select_tickets_form_facebox input[name="select_ticket"]', function(event){

        var ticket_ids = [];
        if($('#selected_tickets_section_for_form').children('input').length > 0){
          $('#selected_tickets_section_for_form').children('input').each(function(){
            ticket_ids.push($(this).val());
          });
        }
        var selected_tid = $(this).attr('id').replace(/select_ticket_/, '');
        if((jQuery.inArray(selected_tid,ticket_ids) == -1) && $(this).is(':checked'))
        {
            $('<input type="hidden" value="'+selected_tid+'" name="step[ticket_ids][]" id="step_ticket_ids_'+selected_tid+'">').appendTo('#selected_tickets_section_for_form');

        }else{
          $('#step_ticket_ids_'+selected_tid).remove();
        }

 });


  $('body').on('click', '.pagination a', function(event) {
    event.preventDefault();
    $.ajax({
        type: "GET",
        url: $(this).attr('href'),
        success: function(data) {
            $("#ticket_list_table_div").parents('div.content:first').html(data);
        }
     });
  });
   $('body').on('click', '.ticket_step_facebox_pagination a', function(event) {
    event.preventDefault();
    var data_prm =  '';
    var assigned_tickets = get_tickets_if_selected();
    if (assigned_tickets.length > 0){
      data_prm =  $(this).attr('href') +  "&current_tickets="+ assigned_tickets;
    }else{
      data_prm =  $(this).attr('href');
    }
    $.ajax({
        type: "GET",
        url: data_prm,
        success: function(data) {
        //   alert('complete');
        }
     });
   });
   $("body").on('click', '.ticketList th.sortable', function() {
        if ($('#filters_sort_scope').val() != $(this).attr('data-column')) {
            $('#filters_sort_direction').val('asc');
        } else {
            $('#filters_sort_direction').toggleValues('asc', 'desc');
        }

        $('#filters_sort_scope').val($(this).attr('data-column'));

        var data_prm =  '';
        var assigned_tickets = get_tickets_if_selected();
        if (assigned_tickets.length > 0){
          data_prm = $('#filter_form').serialize() +  "&current_tickets="+ assigned_tickets;
        }else{
          data_prm = $('#filter_form').serialize();
        }

        $.ajax({
            type: "GET",
            data: data_prm,
            url: $('#filter_form').attr('action'),
            success: function(data) {
                if($('#filter_form').attr('action').indexOf('step_facebox=true') > -1){
                  $('#ticket_selection_sections').html(data);
                }else{
                  $("#ticket_list_table_div").parents('div:first').html(data);
                }
            }
        });
    });

    $('body').on('submit', '#select_tickets_form', function() {

        var ticket_ids = [];
        $('.ticket_action :checked').each(function() {
            if ($(this).attr('disabled') != true)
            {
                ticket_ids.push($(this).attr('id').replace(/select_ticket_/, ''));
            }
        });
        if ($("#tickets_list").find('tbody').length > 0)
        {
            $("#tickets_list").find('tbody').find('tr').each(function() {
                if ($(this).attr('id') != undefined) {
					if ($(this).attr('id').length > 0) {
						ticket_ids.push($(this).attr('id').replace(/unpaged_ticket_/, ''));
					}
				}
            });
        }
        if (ticket_ids.length == 0) {
            alert("Please select at least one ticket to add");
        } else {
            $.ajax({
                url: $('#select_tickets_form').attr("action"),
                type: "GET",
                data: {"ticket_ids[]":ticket_ids},
                success: function(data) {
                    $('#tickets_list').html(data);
                    $('.ticket_action :checked').each(function() {
                        if ($(this).attr('disabled') != true)
                        {
                            $(this).attr("disabled", true);
                        }
                    });
                }
            });
        }
        return false;
    });

    // external ticket filter methods ***********************

    // a change handler that sets loads available resource automations for the selected server
    $('body').on('change', "div.query_tickets #resource_automation_id", function() {

    	// inspect the currently selected project server
    	var project_server_id = $("div.query_tickets #resource_automation_id").attr('value');
    	var path = $("div.query_tickets #resource_automation_id").data('path');
    	var plan_id = $("div.query_tickets #resource_automation_id").data('plan-id');
    	// only fire off the call if we have a non-blank project_server and path
    	if (project_server_id && path && plan_id) {
	        $.ajax({
	            url: path,
	            type: "GET",
	            data: {"project_server_id":project_server_id, "plan_id":plan_id},
	            success: function(data) {
	                $("#ticket_resource_automation_selector").html(data);
	            }
	        });
	    } else {
			hideFilterArgumentsAndResults();
			// set the script menu to empty
			$('div.query_tickets #ticket_resource_automation_selector').html("");
	    }
    });

    // Picking a script for a filter should show the filter properties on the external tickets
    $('body').on('change', "div.query_tickets #ticket_resource_automation_selector #script_id", function() {
    	// query the script ID from the select box
    	var script_id = $("div.query_tickets #ticket_resource_automation_selector #script_id").attr('value');
    	// query the path which was cached by rails in the select box data fields
    	var path = $("div.query_tickets #ticket_resource_automation_selector #script_id").data('path')
    	var plan_id = $("div.query_tickets #ticket_resource_automation_selector #script_id").data('plan-id');
    	if (script_id && path) {
	    	// now send the request for the form and then run the init function after it is loaded.
	    	$.ajax({
	            url: path,
	            type: "GET",
	            data: {"script_id": script_id, "plan_id":plan_id},
		        beforeSend:function(data){
		            $("#filter_prompt").html("<p>Fetching selected filter...</p>")
		            $("#script_arguments").html("")
		        },
	            success: function(data) {
	            	// load the arguments form
	                $("#ticket_filter_arguments").html(data);
	                // now refresh the ticketing information
	                displayTicketingScriptArguments(script_id, false);
	            }
	        });
	    } else {
			hideFilterArgumentsAndResults();
	    }
    	// send the selected script to the ticket display routine to enable ajax prompts
    	// and don't worry if it is blank as we will just redisplay the prompt message in that case
		// displayTicketingScriptArguments($(this).val());
    });

    // Picking a historical filter will set the two other menus and show the filter automation with the past values
    // loaded in.
    $('body').on('change', "#saved_query_selector #query_id", function() {
    	// query the path which was cached by rails in the select box data fields
    	var path = $("#saved_query_selector  #query_id").data('path')
    	var query_id = $("#saved_query_selector  #query_id").attr('value');
    	var plan_id = $("#saved_query_selector  #query_id").data('plan-id');
    	if (query_id && path && plan_id) {
	    	// now send the request for the form and then run the init function after it is loaded.
	    	$.ajax({
	            url: path,
	            type: "GET",
	            data: {"plan_id":plan_id,"query_id":query_id},
		        beforeSend:function(data){
		            $("#filter_prompt").html("<p>Reloading saved query...</p>");
					hideFilterArgumentsAndResults();
		        },
	            success: function(data) {
	            	// load the arguments form
	                $("#ticket_filter_arguments").html(data);
	                // now refresh the ticketing information by grabbing the value cached in the partial
	                // loaded after we picked a query (because until that is found, we don;t have a script id)
	                script_id = $("#ticket_filter_arguments input#script_id").attr("value");
	                project_server_id = $("#ticket_filter_arguments input#script_id").attr("value");

	                if (script_id && project_server_id) {
	                	displayTicketingScriptArguments(script_id, true);
	                };
	            }
	        });
	    } else {
			hideFilterArgumentsAndResults();
	    }
    	// send the selected script to the ticket display routine to enable ajax prompts
    	// and don't worry if it is blank as we will just redisplay the prompt message in that case
		// displayTicketingScriptArguments($(this).val());
    });

    // end external ticket filter methods *********************
});


function displayTicketingScriptArguments(script_id, query_mode) {
	// always a resource automation in the ticket context
	var script_type = 'ResourceAutomation';
	// find the form that can be submitted and tracked through the states below
	var form = $("#update_arguments_form");
	// test if the select box returned a value and either reset the prompt or go get the arguments
	if (script_id) {
		// there is a delay in getting things rolling so say its is loading...
		$('#ticket_filter_arguments #filter_prompt').html("<p>Loading remote argument options for selected filter...</p>");

		// fancy call backs to show the progress of this ajax driven form with many
		// independently loading controls
		var options = {
			data : {
				script_id : script_id,
				script_type : script_type,
                query_mode : query_mode
			},
			beforeSubmit : function() {
				$('.step_auto_only').show();
			},
			success : function(html) {
				$('.step_auto_only').show();
				$('#script_arguments').html(html).prev()[html.match('table') ? 'show' : 'hide']();
			},
			complete : function() {
				updateTargetArgumentId();
				if ($(".available_script_arguments").length > 0) {
					var new_options = {
						beforeSubmit : function() {
							$(".available_script_arguments").each(function(index) {
								argument_id = $(this).val();
								$("td#argument_" + argument_id).addClass("resource_automation_loader");
							});
						},
						success : function(data) {
							$('#ticket_filter_arguments #filter_prompt').html("<p>Loading complete.  Select filter options and submit your query.</p>");
							$(".available_script_arguments").each(function(index) {
								argument_id = $(this).val();
								$("td#argument_" + argument_id).removeClass("resource_automation_loader");
								$("td#argument_" + argument_id).html(data[argument_id]);
								$("td#argument_" + argument_id).append("<span></span>");
								updateTargetArgumentId();
							});
						},
						complete : function() {
                            setSavedQueryValuesForControls();
                            triggerAdapterResourceAutomation();
						}
					};
					$("form#update_resource_automation_parameters").ajaxSubmit(new_options);
				}
			}
		};
		form.ajaxSubmit(options);
	} else {
		hideFilterArgumentsAndResults();
	}
}

// because I was having trouble passing arguments all the way through the lookups
// (someone in Pune can probably do it easily) I am writing this silly work around
// to get basic queries working with the controls.  FIXME: This will no work for trees,
// table selections, etc so we need to pull from #update_arguments_form #argument_values
// and get those into the control drawing routines.
function setSavedQueryValuesForControls() {
	argument_values = JSON.parse($('#update_arguments_form #argument_values').val())
	if (argument_values) {
		for (var argument_id in argument_values) {
			var current_value = argument_values[argument_id]["value"];
			if (current_value) {
				my_finder = '#script_argument_' + argument_id;
				my_selector = $(my_finder);
				if (my_selector) {
					my_selector.val(current_value);
                    my_selector.attr('arg_val', current_value);
				}
			}
		}
	}
}

function hideFilterArgumentsAndResults() {
	// hide the argument section and show a helpful message if set back to blank on the menu
	$('.step_auto_only').hide();
	// reset the ticket results table to empty
	$('#select_tickets_table').html("");
    // this prompt appears when the user has de-selected a script from the menu intentionally
	$('#ticket_filter_arguments #filter_prompt').html("<p>Filter arguments will re-appear once you have selected a filter above.</p>");
}


function select_tickets_form_submit_fu(){
       var ticket_ids = [];
        $('.ticket_action :checked').each(function() {
            if ($(this).attr('disabled') != true)
            {
                ticket_ids.push($(this).attr('id').replace(/select_ticket_/, ''));
            }
        });

        if ($("#tickets_list").find('tbody').length > 0)
        {
            $("#tickets_list").find('tbody').find('tr').each(function() {
                if ($(this).attr('id') != undefined) {
					if ($(this).attr('id').length > 0) {
						ticket_ids.push($(this).attr('id').replace(/unpaged_ticket_/, ''));
					}
				}
            });
        }

         if (ticket_ids.length == 0) {
            alert("Please select at least one ticket to add");
        } else {
            $.ajax({
                url: $('#select_tickets_form_facebox').attr("action"),
                type: "GET",
                data: {"ticket_ids[]":ticket_ids},
                success: function(data) {
                    $('#tickets_list').replaceWith(data);
                    $('.ticket_action :checked').each(function() {
                        if ($(this).attr('disabled') != true)
                        {
                            $(this).attr("disabled", true);
                        }
                    });
                }
            });
        }
        return false;
}

function disableCheckBoxes()
{
    if ($("#tickets_list").length > 0)
    {
        ticketsSection = $("#tickets_list");
        if (ticketsSection.find('tbody').length > 0)
        {
            ticketsSection.find('tbody').find('tr').each(function() {
			  if (($(this).attr('id'))!=undefined) {
			  	var ticket_id = $(this).attr('id').replace(/unpaged_ticket_/, '');
			  	$('.ticket_action #select_ticket_' + ticket_id).attr('disabled', true);
			  	$('.ticket_action #select_ticket_' + ticket_id).attr('checked', true);
			  }
            });
        }
    }
}

function disconnectTicket(ticket_id)
{
    var step_id = $('#new_step_form').find('#Step_id').attr('value');
    if ((step_id.length <= 0) || window.confirm("Are you sure?\nTicket's association from the step will be removed when you save it."))
    {
        var ticket_ids = [];
        $("#tickets_list").find('tbody').find('tr').each(function() {
            if ($(this).attr('id').length > 0)
            {
                curr_ticket = $(this).find('input[type="hidden"]').attr('value');
                if (curr_ticket != ticket_id)
                {
                    ticket_ids.push(curr_ticket);
                }
            }
        });
        $.ajax({
            url: $('#show_tickets_url').attr("value"),
            type: "GET",
            data: {"ticket_ids[]":ticket_ids},
            success: function(data) {
                $('#tickets_list').html(data);
            }
        });
    }
}

function refreshCurrentPage() {
    $.ajax({
        url: $('#current_page_url').attr('value'),
        type: "GET",
        success: function(data) {
            $("#ticket_list_table_div").parents('div.content:first').html(data);
        }
    });
}

function toggleFiltersTicketsSection(){
    var state = $("#filters_collapse_state").attr("value");
    var html = $("#toggleFilterLink").find('a').html();
    var rel = $("#toggleFilterLink").find('a').attr("rel");
    $("#toggleFilterLink").find('a').html(rel);
    $("#toggleFilterLink").find('a').attr("rel", html);
    if ((state != undefined) && (state == 'Open'))
    {
        $("#filters_collapse_state").attr("value", "Closed");
        $("#filter_form").parent('div').parent('div').hide();
    }
    else
    {
        $("#filters_collapse_state").attr("value", "Open");
        $("#filter_form").parent('div').parent('div').show();
    }

  submitFilterTicketForm();
}
function submitFilterTicketForm(form) {
    var data_prm =  '';
    var assigned_tickets = get_tickets_if_selected();
    if (assigned_tickets.length > 0){
      data_prm = $('#filter_form').serialize() +  "&current_tickets="+ assigned_tickets;
    }else{
      data_prm = $('#filter_form').serialize();
    }
    $.ajax({
        type: "GET",
        data: data_prm ,
        url: $('#filter_form').attr('action'),
        beforeSend:function(xhr){
            //nothing
        },
        complete: function(data) {
           //nothing
        },
        success: function(data){
            $("#modelFilterSection").parent('div').html(data);
        }
    });
}

function selectAssignedTicketCheckBoxes()
{
    var assigned_tickets = [];

    if($('#selected_tickets_section_for_form').children('input').length > 0){
        $('#selected_tickets_section_for_form').children('input').each(function(){
            assigned_tickets.push($(this).val());
        });
    }
    jQuery.each(assigned_tickets,function(){
        $('.ticket_action #select_ticket_' + this).attr('checked', true);
    });
}

function get_tickets_if_selected(){
    var assigned_tickets = [];
    if($('#selected_tickets_section_for_form').children('input').length > 0){
        $('#selected_tickets_section_for_form').children('input').each(function(){
            assigned_tickets.push($(this).val());
        });
    }

    return assigned_tickets;
}

function toggleStepFaceboxTicketsFilterLink(){
    var state = $("#filters_collapse_state").attr("value");
    if ((state != undefined) && (state == 'Open')){
        $("#toggleFilterStepTicketLink").find('a').html('Close Filters');
        $("#toggleFilterStepTicketLink").find('a').attr("rel", 'Open Filters');
    }else{
        $("#toggleFilterStepTicketLink").find('a').html('Open Filters');
        $("#toggleFilterStepTicketLink").find('a').attr("rel", 'Close Filters');
    }
}

function getRelatedObjectType() {
  var $related_object_type = $('#step_related_object_type');
  return $related_object_type.val() || $related_object_type.data('object-type');
}
