////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////
$.fn.clearForm = function() {
  return this.each(function() {
    var type = this.type, tag = this.tagName.toLowerCase();
    if (tag == 'form')
      return $(':input',this).clearForm();
    if (type == 'text' || type == 'password' || tag == 'textarea')
      this.value = '';
    else if (type == 'checkbox' || type == 'radio')
      this.checked = false;
    else if (tag == 'select')
      this.selectedIndex = -1;
  });
};

// str.include('something')
// arg:
// - string
// result:
//  boolean
String.prototype.include = function(str){
  return this.indexOf(str) != -1;
}

$(function() {
  $('#add_remove_application_environment').livequery(function(){
    $(this).updateElement('#application_environments');
  });

  //FIXME: Not sure if this is still needed from merge
  //$('#add_remove_application_component').always().updateElement('#application_components');

  //$('form.add_remove_eg').always().updateParentElementWithAjaxForm('tbody#app_environments');
  $('form.add_remove_eg').live('ajax:success', function(xhr, data, status) {
    $('form.add_remove_eg').parents('tbody#app_environments').eq(0).html(data);
  });


  // FIXME: duplicated in table_drop_zone.js
  $('.work_task_row').livequery(function(){
    $(this).tableDropZone('work_task');
  });


  $("table.comp_table").find('.pageSection').find('div:nth-child(2)').remove();

  $('.applicationEnvPackage li').click(function() {
    clickedLi = $(this);
    clickedLi.parent().children().each(function(index){
      if ($(this).attr('tab') == clickedLi.attr('tab')){
        $(this).addClass('selected');
        $("#" + $(this).attr('tab')).show();
      } else {
        $(this).removeClass('selected');
        $("#" + $(this).attr('tab')).hide();
      }
    });
    return false;
  });

  $('body').on('change', 'form.no_direct_submit input, form.no_direct_submit select', function() {
    var input = $(this);
    input.hide().spin();
    input.parents('form:first').ajaxSubmit(function() {
      input.next().remove();
      input.show();
    });
  });

  $('body').on('click', '#add_properties', function(event){
    var form = $(this).siblings('form:first');
    var current_table = form.find('div[id^=property_table_]:visible');
    var current_table = current_table.length == 0 ? form.find('div#property_table_1') : current_table;
    var current_table_rows = current_table.find('table tr').length;

    if(current_table_rows > 0){
      current_table.show();
    }

    $('form.new_properties_form .edit_new_properties_table').find('.edit_property_table').each(function(){
      if(($(this).attr('style') == undefined  ) || ($(this).attr('style') == '') || $(this).attr('style').indexOf('none') == -1) {
        page = $(this).attr('id').match(/[0-9]+/)[0];
      }
    });

    event.preventDefault();

    $('form.new_properties_form').find('.edit_new_properties_table .edit_property_table').each(function(){
      if ($(this).is(":visible")) {
        if($(this).find('table#new_properties tr:last').attr('id') != undefined){
          property_number = parseInt($(this).find('table#new_properties tr:last').attr('id')) + 1;
        } else {
          property_number = $(this).find('table#new_properties tr').length;
        }
      }
    });

    $.ajax({
             url: $(this).attr('href'),
             type: 'GET',
             data: {'property_number' : property_number, 'show_property' : 'add', 'page'  : page},
             success: function(data){
               $("#new_property_section .edit_new_properties_table").find("#property_table_"+ String(page)).find('table#new_properties tr:last').after(data);
             }
           });

    return false;
  });

  $('body').on('click', '#add_new_property', function(event){
    event.preventDefault();
    property_number = 1
    $.ajax({
             url: $(this).attr('href'),
             type: 'GET',
             data: {'property_number' : property_number, 'add_property' : 'add'},
             success: function(data){
               $('#add_new_property').replaceWith(data);
             }
           });
    return false;
  });

  $('table#edit_properties input, table#show_existing_properties input, table#new_properties input').livequery(function(){
    $(this).observe_field(1, function( ) {
      update_property_values($(this).attr('property_id'))
    });
  });
  $('table#new_properties  input[class =property_field]').livequery(function(){
    $(this).observe_field(1, function() {
      update_property_values_new_property($(this).parents('tr').attr('id'))
    });
  });

  var getPageNo = function(clickedLink, that){
    var pageNo;

    if ($(that).html().indexOf('Next') != -1)           pageNo = clickedLink + 1;
    else if ($(that).html().indexOf('Previous') != -1)  pageNo = clickedLink - 1;
    else                                                pageNo = parseInt($(that).html());

    return pageNo;
  }

  var renderPaginatedPart = function(data, pageNo, table_to_show, options){
    var force_reload      = options.force_reload;
    var navigationWrapper = options.renderTo;
    var tablePlaceholder  = $('form.property_value_form');
    var cachedPart        = navigationWrapper.parents('*:eq(2)').find('#property_table_' + pageNo); // table_to_show;
    var appendedBefore    = !!cachedPart.length;

    // rerender loaded `data` everytime
    if(force_reload){
//      console.log('### REAPEEND');
      navigationWrapper.parents('.main_property_value_form').append(data);
      navigationWrapper.parents('.edit_property_table').remove();
    }
    else {
      // render if it hasn't been yet
      if(!appendedBefore){
//        console.log('### APEENDFIRSTTIME');
        navigationWrapper.parents('.main_property_value_form').append(data);
        navigationWrapper.parents('.edit_property_table').hide();
      }
      // hide/show 'page' if it was rendered already
      else{
//        console.log('### HIDE/SHOW');
        navigationWrapper.parents('.edit_property_table').hide();
        cachedPart.show();
      }
    }
  }

  var getPropertyIds = function(table_on_page){
    var property_ids = [];

    $(table_on_page).find('input[type=text]').each(function(){
      property_ids.push($(this).attr('property_id'))
    });

    property_ids = uniqArray(property_ids);

    return property_ids;
  }

  var getPropertyNumbers = function(paginationForm){
    var property_number   = 0;
    var property_numbers  = [];

    paginationForm.find('.edit_property_table:visible').each(function(){
      if($(this).find('table#new_properties tr:last').attr('id').length != 0){
        property_number = parseInt($(this).find('table#new_properties tr:last').attr('id')) + 1;
      }
      else {
        property_number = $(this).find('table#new_properties tr').length;
      }

      $(this).find('table#new_properties tr').each(function(){
        if ($(this).attr('id') && $(this).attr('id').length != 0){
          property_numbers.push(parseInt($(this).attr('id')));
        }
      });
    });

    return [property_number, property_numbers];
  }

  $('body').on('click', 'div.my_data_pagination a', function(event){
    event.preventDefault();

    var form                = $(this).parents('form:first');
    var parentDiv           = $(this).parents('div:first');
    var force_reload        = parentDiv.attr('class').indexOf('force_reload') != -1;
    var clickedLink         = parseInt(parentDiv.find("span.current").html()) ||
                              parseInt(parentDiv.find("em.current").html());
    var property_form       = $(this).parents('form:first');
    var property_ids        = [];
    var property_number     = '';
    var	property_name_keys  = new Object();
    var property_name_field = [];
    var property_numbers    = [];
    var MINIMUM_ROW_COUNT   = 1;
    var selected_view;
    var property_tbl_tr;
    var needs_request;

    // calculate page number
    var pageNo              = getPageNo(clickedLink, this);

    // why `#property_table_`?
    // because you're supposed to have your pagination
    // `div` wrapper id right like that
    /*
     *  HTML structure:
     * paginated table wrapper:
     *  |_ paginated table (aka #property_table_):
     *     (^- may be more than one with the same ID on page, so searching in a scope of `parentDiv`'s 2nd wrapper)
     *    |_ navigation wrapper:
     *       |_ navigation (aka parentDiv)
     */
    // requested paginated table
    var table_to_show       = parentDiv.parents('*:eq(2)').find('#property_table_' + pageNo);

    // current paginated table
    var table_on_page       = parentDiv.parents('*:eq(2)').find('[id^="property_table_"]:visible');

    var lower_properties_table = parentDiv.attr('table_position') == 'lower_table';

    // get selected property attribute:
    // - Adding from existing prorepties
    // - Adding new property
    $('.content').find('input.add_properties:checked').each(function(){
      selected_view         = $(this).attr('property');
    });

    // save properties in second(lower) pagination table
    if (lower_properties_table) {
      if (form.attr('class') != 'new_properties_form'){
        property_ids          = getPropertyIds(table_on_page);
      }

      property_number = 1;
      if (form.attr('class') == 'new_properties_form') {
        var properties        = getPropertyNumbers(form);
        property_number       = properties[0];
        property_numbers      = properties[1];
      }
    }

    // calculate rows count in current paginated table
    property_tbl_tr         = table_on_page.find('table tr').length;

    // ?
    if (property_tbl_tr == 'undefined'){
      property_tbl_tr = MINIMUM_ROW_COUNT;
    }

    // was there previously generated pagination part on page and its rows count is >= 1?
    // does row count in current table differ from row count in table to show?
    // e.g. we may have added\deleted a row in current table;
    property_conds  = table_to_show.html() == null && property_tbl_tr >= MINIMUM_ROW_COUNT;
    table_conds     = table_to_show.find('table tr').length != property_tbl_tr;
    table_conds     = table_to_show.find('table tr').length > 0 ? table_conds : false;

    // if we visited a page with paginated table before, it's already appended and hidden
    // no need to get the same data again;
    needs_request = property_conds || table_conds;

    // save properties' input values
    $('form.new_properties_form').find('table#new_properties input[class!=property_field]').each(function(){
      if ($(this).is(":visible")) {
        property_name_keys[$(this).attr('id')] = $(this).val();
        property_name_field.push($(this).attr('id'));
      }
    });

    if (needs_request || force_reload) {

      // prepare url
      url = $(this).attr('href');
      $.each (getUrlVars($(this).attr('href'), "property_ids%5B%5D"), function(k, v){
        url = url.replace("&property_ids%5B%5D="+v, "")
      });
      $.each (getUrlVars($(this).attr('href'), "property_numbers%5B%5D"), function(k, v){
        url = url.replace("&property_numbers%5B%5D="+v, "")
      });

      $.get(url, {
        'show_view': true,
        'property_ids[]': property_ids,
        'property_number': property_number,
        'property_numbers[]':property_numbers
      }, function(data){
        if (parentDiv.attr('table_position') == 'lower_table') {

          if (selected_view == 'new_property') {
            renderPaginatedPart(data, pageNo, table_to_show, {renderTo: parentDiv, force_reload: force_reload});

            if (table_conds){
              var new_pro_val_keys  = new Object();
              new_pro_app_env_ids   = [];

              $('form.new_properties_form').find('.edit_new_properties_table #property_table_'+pageNo+' table#new_properties input[class=property_field]').each(function(){
                // save properties' values
                // e,g, {property_values_4_1: "value"}
                new_pro_val_keys[$(this).attr('id')] = $(this).val();

                // save prorepties' ids
                new_pro_app_env_ids.push($(this).attr('id'));
              });

              $('form.new_properties_form').find('.edit_new_properties_table #property_table_'+pageNo).remove();
              $('form.new_properties_form').find('.edit_new_properties_table').append(data);
              $.each(new_pro_app_env_ids, function(index, value) {
                index = index + 1;
                $("form.new_properties_form .edit_new_properties_table #property_table_"+pageNo +" table#new_properties input[class=property_field][id="+value+"]").val(new_pro_val_keys[value]);
              });
            } else {
              $('form.new_properties_form').find('.edit_new_properties_table').append(data);
            }
            put_property_name(pageNo, property_name_keys,property_name_field);
          }
          else {
            renderPaginatedPart(data, pageNo, table_to_show, {renderTo: parentDiv, force_reload: force_reload});

            if (table_conds){
              pro_app_env_ids = []
              var pro_val_keys = new Object();
              $('form.existing_properties_form').find('.edit_existing_properties_table #property_table_'+pageNo+' table#show_existing_properties input').each(function(){
                pro_val_keys[$(this).attr('id')] = $(this).val();
                pro_app_env_ids.push($(this).attr('id'));
              });

              table_to_show.remove();
//              $('form.existing_properties_form').find('.edit_existing_properties_table #property_table_'+pageNo).remove();

              $('form.existing_properties_form').find('.edit_existing_properties_table').append(data);
              $.each(pro_app_env_ids, function(index, value) {
                $("form.existing_properties_form .edit_existing_properties_table #property_table_"+pageNo +" table#show_existing_properties input[id="+value+"]").val(pro_val_keys[value]);
              });
            }
            else {
              $('form.existing_properties_form').find('.edit_existing_properties_table').append(data);
            }
          }

        }
        else {
          renderPaginatedPart(data, pageNo, table_to_show, {renderTo: parentDiv, force_reload: force_reload});
        }
      });
    }
    else {
      renderPaginatedPart(data = null, pageNo, table_to_show, {renderTo: parentDiv, force_reload: force_reload});

      // restore properties' values
      put_property_name(pageNo, property_name_keys, property_name_field);
    }
  });

  $('body').on('click', ".component_property", function(event){
    var page    = 1;
    page        = current_page(page);

    var property_number = 0;
    var property_id     = $(this).val();

    var current_table   = $('table[id^=show_existing_properties]:visible');

    if ($(this).attr('checked')) {
      // 1 -- for table header. Table itself is hidden;
      property_number = current_table.find('tr').length || 1;
    }
    else {
      property_number = current_table.find('tr').length - 2;
    }

    if(property_number > 0){
      $.get($(this).attr('url'),{'show_property':true, 'property_id': property_id, 'property_number': property_number,  'page': page}, function(data){
        $('form.existing_properties_form').show();

        if (page == 1){
          $("table#show_existing_properties").show();
          $('.lower_table_pagination').show();
        }

        if ($('input[value='+property_id+']').attr('checked')){
          $('table.existing_property_table').find('input[value='+property_id+']').attr('checked', false);
          current_table.find('input[property_id='+property_id+']').parents('tr:first').remove();
        }
        else {
          $('table.show_existing_properties_'+page).append(data);
          if($(data).find('td').length < 4){
            $('table.show_existing_properties_'+page+'  tr#'+property_id).append('<input type="hidden" name="property_id_for_uninsalled_component['+ property_id +']"/>');
          }
          $('table.existing_property_table').find('input[value='+property_id+']').attr('checked', true);
        }
      });
    }
    else{
      $('form.existing_properties_form').hide();
      $('table.existing_property_table').find('input[value='+property_id+']').attr('checked', false);
      current_table.find('input[property_id='+property_id+']').parents('tr:first').remove();

      return true;
    }

    return false;
  });

  $('body').on('click', '.property_value_form_submit', function(event){
    var form = 'undefined';
    var page = 1;
    var existing_prop_style = $('#existing_property_section');
    page = current_page(page)
    if ( $(existing_prop_style).is(":visible")  && $('table#show_existing_properties').is(":visible")){
      if($('table.show_existing_properties_'+page).find('tr').length > 1) {
        form = 'form.existing_properties_form'
      }
    }
    if ($('#existing_property_section').is(":hidden") && $('table#new_properties tr').length > 1) {
      form = 'form.new_properties_form'
    }
    if (form == 'undefined') {
      form = 'form.property_value_form'
    }
    $(form).ajaxSubmit({dataType: 'script'});
    return false;
  });

  $('body').on('click', '.add_properties', function() {
    if($(this).attr('property') == 'existing_property'){
      $('input#view_by_new_property_').attr('checked', false);
      $('#new_property_section').hide();
      $('#existing_property_section').show();
      $('form.existing_properties_form').show();
      $('table#show_existing_properties').show();
    } else{
      $('input#view_by_existing_property_').attr('checked', false);
      $('#existing_property_section').hide();
      $('table#show_existing_properties').hide();
      $('form.existing_properties_form').hide();
      $('#new_property_section').show();
    }
  });

  $('body').on('click', '.destroy_new_property', function(){
    var form = $(this).parents('form:first');
    var tr_id = $(this).parents('tr:first').attr('id');
    var current_table = $(this).parents('table:first');
    var current_table_wrapper = current_table.parents('div[id^=property_table_]');
    form.find('tr#'+tr_id).remove();

    var current_table_has_rows = current_table.find('tr').length > 1; // 1 -- table headers

    if(!current_table_has_rows){
      current_table_wrapper.hide();
    }

    if($("#existing_property_section").attr('style').indexOf("none") == -1){
      $("#existing_property_section").find('input#component_property_ids_'+tr_id).attr('checked', false);
    }
  });


  // a change handler that sets loads available resource automations for the selected server
  $('body').on('change', "div.component_mappings #resource_automation_id", function() {

    // inspect the currently selected project server
    var project_server_id = $("div.component_mappings #resource_automation_id").attr('value');
    var path = $("div.component_mappings #resource_automation_id").data('path');

    hideFilterArgumentsAndResults();
    $('div.component_mappings #component_resource_automation_selector select').attr('value', "");

    // only fire off the call if we have a non-blank project_server and path
    if (project_server_id && path) {
      $.ajax({
               url: path,
               type: "GET",
               data: {"project_server_id":project_server_id},
               success: function(data) {
                 $("#component_resource_automation_selector").html(data);
               }
             });
    } else {
      // set the script menu to empty
      $('div.component_mappings #component_resource_automation_selector select').attr('disabled', true);
    }
  });

  // Picking a script for a filter should show the filter properties on the external tickets
  $('body').on('change', "div.component_mappings #component_resource_automation_selector #script_id", function(event, query_mode) {
    // query the script ID from the select box
    var script_id = $("div.component_mappings #component_resource_automation_selector #script_id").attr('value');
    // query the path which was cached by rails in the select box data fields
    var path = $("div.component_mappings #component_resource_automation_selector #script_id").data('path');
    // inspect the currently selected project server
    var project_server_id = $("div.component_mappings #resource_automation_id").attr('value');

    if (query_mode == undefined)
    {
      query_mode = false
    }

    if (script_id && path) {
      // now send the request for the form and then run the init function after it is loaded.
      $.ajax({
               url: path,
               type: "GET",
               data: {"script_id": script_id, "project_server_id":project_server_id},
               beforeSend:function(data){
                 // $("#filter_prompt").html("<p>Fetching selected filter...</p>")
                 $("#script_arguments").html("")
               },
               success: function(data) {
                 // load the arguments form
                 $("#component_selection_filters").html(data);
                 // now refresh the ticketing information
                 displayComponentMappingScriptArguments(script_id, query_mode);
               }
             });
    } else {
      hideFilterArgumentsAndResults();
    }
    // send the selected script to the ticket display routine to enable ajax prompts
    // and don't worry if it is blank as we will just redisplay the prompt message in that case
    // displayTicketingScriptArguments($(this).val());
  });
});


function displayComponentMappingScriptArguments(script_id, query_mode) {
  // always a resource automation in the ticket context
  var script_type = 'ResourceAutomation';
  // find the form that can be submitted and tracked through the states below
  var form = $("#update_arguments_form");
  // test if the select box returned a value and either reset the prompt or go get the arguments
  if (script_id) {
    // there is a delay in getting things rolling so say its is loading...
    //$('#component_selection_filters #filter_prompt').html("<p>Loading remote argument options for selected filter...</p>");

    // fancy call backs to show the progress of this ajax driven form with many
    // independently loading controls
    var options = {
      data : {
        script_id : script_id,
        script_type : script_type,
        query_mode: query_mode
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
              //$('#ticket_filter_arguments #filter_prompt').html("<p>Loading complete.  Select filter options and submit your query.</p>");
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
          my_selector.val(current_value)
          my_selector.attr('arg_val', current_value);
        }

        my_selector = $('#tree_renderer_' + argument_id);
        if (my_selector) {
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
  //$('#select_tickets_table').html("");
  // this prompt appears when the user has de-selected a script from the menu intentionally
  //$('#ticket_filter_arguments #filter_prompt').html("<p>Filter arguments will re-appear once you have selected a filter above.</p>");
}

function saveComponentMapping(clickedBtn) {
  clickedBtn.attr('disabled', true);
  var addPostdata = {ajax_request: 'true'};
  componentMapForm = $('form#map_component_form');
  $(".tree_renderer").each(function(){
    var dt = $(this).dynatree("getTree").serializeArray();
    $.each(dt, function() {
      if (addPostdata[this.name] == undefined){
        addPostdata[this.name] = this.value;
      }else{
        addPostdata[this.name] = addPostdata[this.name].concat(",").concat(this.value);
      }

    });
  });
  componentMapForm.ajaxSubmit({
                                type: "POST",
                                data: addPostdata,
                              });
}

function deleteComponentMapping(clickedBtn) {
  clickedBtn.attr('disabled', true);
  var project_server_id = $("div.component_mappings #resource_automation_id").attr('value');
  var action = confirm("Are you sure you want to delete the selected mapping?");
  if (action) {
    $.ajax({
             url : $('#delete_mapping_url').attr('value'),
             type : "DELETE",
             data : {"project_server_id" : project_server_id }
           });
  }
}

function submitPropertyValuesForm() {
  $('form.property_value_form').ajaxSubmit({dataType: 'script'});
}

function put_property_name(pageNo, property_name_keys,property_name_field){
  $.each(property_name_field, function(index, value) {
    $("form.new_properties_form .edit_new_properties_table #property_table_"+pageNo +" #new_properties #"+value).val(property_name_keys[value]);
  });
}

function current_page(page){
  $(".existing_properties_form .edit_existing_properties_table").find('.edit_property_table').each(function(){
    if(($(this).attr('style') == undefined  )|| $(this).attr('style').indexOf('none') == -1) {
      page = $(this).attr('id').match(/[0-9]+/)[0];
    }
  });
  return page;
}

function cancelPackageTempateForm(){
  $('#newPackageTemplate').hide();
  $('#packageTempalteList').show();
  $('#new_package_template_form').clearForm();
  return false;
}

function showPackageTemplateForm(){
  $('#newPackageTemplate').show();
  $('#packageTempalteList').hide();
  $('#new_package_template_form').clearForm();
  $('#new_package_template_form').show();
  $('.editPackageTemplateform').hide();
  $('.validation_errors').html('');
  return false;
}

function _selectTab(toSelect){
    $('ul.component_tabs li:nth-child(1)').removeClass('selected');
    $('ul.component_tabs li:nth-child(2)').removeClass('selected');
    $('ul.component_tabs li:nth-child(3)').removeClass('selected');
    $('ul.component_tabs li:nth-child(' + toSelect + ')' ).addClass('selected');
}

function showAppComponents() {
    _selectTab(1);
    $('#application_components_list').show();
    $('#component_templates_list').hide();
    $('#packages_list').hide();
    $('.package_link_div').hide();
    $('.compnent_link_div').show();
    $('#list_of_components').show();
    return false;
}

function showAppComponentTemplates() {
    _selectTab(2);
    $('#application_components_list').hide();
    $('#component_templates_list').show();
    $('#packages_list').hide();
    $('.compnent_link_div').hide();
    $('#list_of_components').hide();
    $('.package_link_div').hide();
    return false;
}

function showAppPackages() {
    _selectTab(3);
    $('#application_components_list').hide();
    $('#component_templates_list').hide();
    $('#packages_list').show();
    $('.compnent_link_div').hide();
    $('.package_link_div').show();
    $('#list_of_components').hide();
    return false;
}

function insertPktiEditForm(pktiId){
  if ($("#editPackageTemplate_" + pktiId).length != 0) {
    $("#editPackageTemplate_" + pktiId).html('');
  } else {
    $("<div class='editPackageTemplateform' id='editPackageTemplate_" + pktiId + "'></div>").appendTo("#packageTemplates");
  }
  $("#newPackageTemplate").hide();
  $("#packageTempalteList").hide();
  $("#editPackageTemplate_" + pktiId).show();
}

function showTemplateItemForm(pkId) {
  tiId = '';
  $("#template_item_id").val("yes");
  showConcernedTemplateItem(pkId, tiId);
  $('#package_template_item_type').trigger('onchange');
  $("#add_new_package_template_item").hide();
}

function showConcernedTemplateItem(pkId, tiId) {
  $('.validation_errors').html('');
  $('.templateItemforms').hide();
  $(".newTemplateItem_pkg_" + pkId).show();
  $(".newTemplateItem_pkg_" + pkId).find('table').hide();
  $("#template_item_id").val("no");
  rel = 'pk_' + pkId + '_item_' + tiId;
  $(".Ct-" + rel).trigger('onchange');
  $(".newTemplateItem_pkg_" + pkId).find('table').each(function(index){
    if ($(this).attr('rel') == rel) {
      $(this).show();
    }
  });
}

function changeTemplateItemForm(selectListVal, class_name) {
  $("#template_item_id").val("yes");
  if (selectListVal == '1') {
    $('.1_' + class_name).show();
    $('.2_' + class_name).hide();
  } else if (selectListVal == '2') {
    $('.1_' + class_name).hide();
    $('.2_' + class_name).show();
  } else {
    $('.1_' + class_name).hide();
    $('.2_' + class_name).hide();

  }
}

function CanceladdNewItem(formSectionClass) {
  $('#add_new_package_template_item').show();
  $('.validation_errors').html('');
  $(formSectionClass).hide();
  $("#template_item_id").val("no");
  return false;
}


$.fn.extend({

  tableDropZone: function(row_type, plural_row_type) {
    return this.droppable({
      accept: '.' + row_type,
      hoverClass: 'hover',
      drop: function(e, ui) {
        //ui.helper.hide(); // don't show snap-back animation
        dropZone = $(this);

        var rowId = ui.draggable.attr('id').match(/\d+/)[0];
        var insertionPoint = dropZone.prevAll('tr.' + row_type + '_row').length + 1;
        reOrderField = '<input type="hidden" id="reorder" "name="reorder" value="1" />';
        itemId = '<input type="hidden" id="re_template_item_id" name="template_item_id" value="' + rowId + '" />';
        insertionPointField = '<input type="hidden" id="insertion_point" name="insertion_point" value="' + insertionPoint + '" />';
        $('form#edit_package_template_form').append(reOrderField);
        $('form#edit_package_template_form').append(itemId);
        $('form#edit_package_template_form').append(insertionPointField);
        $('form#edit_package_template_form').trigger('onsubmit');

		$('form#edit_package_template_form').find("#reorder").remove();
        $('form#edit_package_template_form').find("#re_template_item_id").remove();
        $('form#edit_package_template_form').find("#insertion_point").remove();

      }
    });
  }

});

function loadComponentProperties(componentTemplate){
  var template_item_count = componentTemplate.attr('id').match(/\d+/g);
  var ctRel = componentTemplate.attr('rel').replace(/Ct-/g, '');
  $(".property_values_" + ctRel).remove();
  if (componentTemplate.val() != '') {
    $.get(url_prefix + '/component_templates/' + componentTemplate.val() + '/component_properties?template_item_count=' + template_item_count + '&package_template_item=' + ctRel.replace(/pk_\d+_item_/g, '') + '&identifier=' + ctRel, {}, function(partial){
      $('table #properties_' + ctRel + ' tr:last').before(partial);
    });
  }
}

function checkEnvironmentsAndSubmit(appName){
  if ($(".application_environment_row").length > 0){
    $('#copy_all_components_to_app').submit();
  } else {
    alert("You cannot copy the components as no environment exist for " + appName + " application.");
  }
}

function setCommandOptions(options, tableRel){
  var cmd_tbl = $("#cmd_" + tableRel)
  cmd_tbl.find('.single_user_mode').val(options['single_user_mode']);
  cmd_tbl.find('.action_on_fail').val(options['action_on_fail']);
  cmd_tbl.find('.reboot').val(options['reboot']);
}

function hideAppEnvironmnets(){
  $("#hideAppEnvironments").hide();
}

function update_property_values(property_id){
  var properties_values = []
  var flag;

  $('table#edit_properties, table#show_existing_properties').find('input[property_id='+property_id+']').each(function(){
    properties_values.push($(this).val());
  });

  prop_values_length = 	properties_values.length

  $('table#edit_properties, table#show_existing_properties').find('input[property_id='+property_id+']').each(function(){
    field_value = $(this).val();
    for (i=0;i<prop_values_length;i++) {
      if (field_value == properties_values[i] ){
        flag = true
      } else {
        flag = false
        return false;
      }
    }
  });
  if (flag){
    $('table#edit_properties, table#show_existing_properties').find('td#property_val_'+property_id).html('Identical');
  } else {
    if (flag == undefined){
      $('table#edit_properties, table#show_existing_properties').find('td#property_val_'+property_id).html('None');
    } else  {
      $('table#edit_properties, table#show_existing_properties').find('td#property_val_'+property_id).html('Vary');
    }
  }
}

// Set values identical or vary for newly added properties

function update_property_values_new_property(id){
  var properties_values = []
  var flag;
  var expected_tr = $('table#new_properties').find('tr#'+id)
  expected_tr.find('input[class=property_field]').each(function(){
    properties_values.push($(this).val());
  });
  prop_values_length = 	properties_values.length
  expected_tr.find('input[class=property_field]').each(function(){
    field_value = $(this).val();
    for (i=0;i<prop_values_length;i++) {
      if (field_value == properties_values[i] ){
        flag = true
      } else {
        flag = false
        return false;
      }
    }
  });
  if (flag){
    expected_tr.find('td#property_val_').html('Identical');
  } else {
    if (flag == undefined){
      expected_tr.find('td#property_val_').html('None');
    } else  {
      expected_tr.find('td#property_val_').html('Vary');
    }
  }
}

function removing_table_except_current_page(data,page){
  if($(data).attr('id') != "property_table_"+page) {
    $(data).remove();
  }
}
