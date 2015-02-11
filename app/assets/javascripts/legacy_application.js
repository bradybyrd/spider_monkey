////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

var RequestOpener = function(){
  var $requestRow;
  var urlToRequest;
  var anotherUrlToRequest;

  function urlPresent(url){
    return url != undefined;
  }

  function reportPage(){
    return window.location.href.indexOf("reports") != -1;
  }

  function requestDeleted(){
    return $requestRow.hasClass("delete_request");
  }

  function init(requestRow){
    $requestRow = $(requestRow);
    urlToRequest = $requestRow.find('a').attr('href');
    anotherUrlToRequest = $requestRow.parent().find('td.status a').attr('href');
  }

  function openRequestFromReportPage(){
    if ($requestRow.hasClass("escape_lp") && urlPresent(urlToRequest)) {
      window.open(urlToRequest);
    } else if(urlPresent(anotherUrlToRequest)){
      window.open(anotherUrlToRequest());
    }
  }

  function openRequest(){
    var requestParentRow = $requestRow.parents('tr');

    if (anotherUrlToRequest == '#' || !urlPresent(anotherUrlToRequest)) {
      requestParentRow.removeClass('clickable');
    } else if(urlPresent(anotherUrlToRequest)) {
      window.location.href = anotherUrlToRequest;
    }
  }

  function onClick(requestRow){
    init(requestRow);

    if (!requestDeleted()) {
      if (reportPage()) {
        openRequestFromReportPage();
      } else {
        openRequest();
      }
    }
  }

  return { onClick: onClick }
}();

$(document).ready(function () {

  $('body').on('click', '.calendar img', function (e) {
    $(this).parent(':first').click();
  })

  $('body').on('click', '.server_groups_pagination a', function (event) {
    event.preventDefault();
    $.get(this.href, null, null, "script");
  });

  show_drop_down();

  plan_map_scroll();

  start_blink();

  initAjaxIndicator();

  customizeMultiSelect();

  $('body').on('click', '#sync_link', function (event) {
    var s_link = $(this).attr('href');
    $.ajax({
      type: "POST",
      url: s_link,
      beforeSend: function (xhr) {
        $('#sync_link').hide();
        $('#sync_loader').show();
      },
      complete: function (xhr) {
        $('#sync_link').show();
        $('#sync_loader').hide();
      }
    });
    return false;
  });

  $('body').on("click", '.ignore-pending', function () {
    $('select option').each(function (i, el) {
      var optText = $(el).html();
      $(el).attr('title', optText);
    });

    $('select optgroup').each(function (i, el) {
      var optgroupText = $(el).attr('label');
      $(el).attr('title', optgroupText);
    });
  });

  $('body').on('click', 'a.delete', function (event) {
    event.preventDefault();
    if (confirm("Are you sure?")) {
      $(this).parent('form').submit();
    }
  });

  $('body').on('click', 'tr.request_row td:not(.last)', function () {
    RequestOpener.onClick(this);
  });

  $('tr.request_steps').click(function () {
    window.location.href = $(this).find('td.status a').attr('href')
  });

  $('sup.help').livequery(function () {
    $(this).setupHelpBox();
  });

  /*$('.auto_update').autoUpdate(); Disabled after request specific status update configuration*/

  $('#viewCurrentSteps').bind('click', function (event) {
    event.preventDefault();
    if ($('#currentSteps').html() == '') {
      $(this).html($(this).html().replace('View', 'Hide'));
      $('#currentSteps').load($('#viewCurrentSteps').attr('href'), function () {
        $('#currentSteps').fadeIn();
      });
    } else if ($(this).html().match(/Hide/)) {
      $('#currentSteps:visible').fadeOut();
      $(this).html($(this).html().replace('Hide', 'View'));
    } else {
      $('#currentSteps:hidden').fadeIn();
      $(this).html($(this).html().replace('View', 'Hide'));
    }
  });

  $('.expand_all').click(function () {
    var link = $(this);
    if (link.hasClass('active')) {
      link.removeClass('active').html('expand all');
      $('.toggle.open').click();
    } else {
      link.addClass('active').html('close all');
      $('.toggle.closed').click();
    }
    return false;
  });

  $('#show_activity_customer_fields, #hide_activity_customer_fields').click(function (event) {
    elementToggler(this, false);
  });

  $('#btn-create-template').click(function () {
    clone = $("#new_request_template").clone().css({'width': '455px', 'padding-left': '10px' });
    clone.find('p').show();
    // clone duplicates ids, so for testing and other reasons, we need to give this button a unique id
    clone.find('input[type="image"]').attr('id', 'btn-save-template');
    clone.prepend("<div id='error_messages'></div>").prepend("<h2>Create New Template</h2>");
    clone.openWithFacebox();
    return false;
  });

  $('form#new_request input, form#new_request select').change(function () {
    $('form.create_request_from_template').find('input[name="' + $(this).attr('name') + '"]').val($(this).val());
  }).change();

  $('body').on('change', 'select.step_property_value, input.step_property_value', function () {
    $('#hidden_' + $(this).attr('id')).val($(this).val());
  });

  $('input[name="server_ids[]"]').click(function () {
    $('#default_server_id_' + $(this).val()).toggle();
  });

  $('.update_bl_user').ajaxForm();
  $('.update_bl_user select').change(function () {
    $(this).parents('form').submit();
  });

  $('body').on('change', '#filters_user_id', function () {
    $(this).parents('form:first').find('#filters_group_id').val('');
  });

  $('body').on('change', '#filters_group_id', function () {
    var form = $(this).parents('form:first');
    form.find('#filters_user_id').val('');
    form.find('#filters_include_groups').attr('checked', '');
  });

  $('body').on('change', '#per_page_steps', function () {
    var href = $('ul.dashboard_request_tab').find('li.current a').attr('href');
    var per_page = $(this).val();
    $.get(href, {per_page: per_page}, function (data) {
      $("#request_and_calendar").html(data);
    });
  });

  $('body').on('change', '#per_page', function () {
    var me = $('#per_page');
    var form = $('#financials_filters form');
    var href = $('ul.dashboard_request_tab').find('li.current a').attr('href');
    form.find('#filters_per_page').val(me.val());
    $.ajax({
      type: "GET",
      data: form.serialize(),
      url: href,
      success: function (data) {
        $("#request_and_calendar").html(data);
        open_close_filters();
        clearDuplicateIds();
      }
    });

  });

  $('body').on('submit', 'form#new_procedure', function () {
// FIXME,Dinesh,2012-02-10,Need to refactor the code to get rid of form cloning.
    var new_form = $(this).clone();
    step_ids = checkSelectedSteps();
    if (step_ids.length > 0) {
      new_form.append('<input type="hidden" name="procedure[step_ids][]" value="' + step_ids + '" />');
    }
    $(this).find('textarea').attr('id', 'procedure_description_change');
    $(this).find('p.expand_textarea_link a').attr('id', 'procedure_desc_change');
    $(new_form).find('textarea').attr('id', 'procedure_description');
    $(new_form).find('p.expand_textarea_link a').attr('id', 'procedure_desc');
    new_form.openWithFacebox().find('#procedure_form_div').show();

    new_form.find('#procedure_form_div').prepend("<div id = error_messages />")
    new_form.find('input#btn-create-procedure').bind('click', function () {
      $(new_form).ajaxSubmit({dataType: 'script'});
      return false;
    });

    return false;
  });

  $('body').on('change', '#server_association_type', function () {
    var select = $(this);
    var visible_div = $('div.server_association:visible');
    visible_div.fadeOut(200, function () {
      visible_div.find('select').attr('disabled', 'disabled');
      visible_div.find('div').hide();
      var selected_div = $('div#' + select.val());
      selected_div.fadeIn();
      selected_div.find('select').removeAttr('disabled');
      selected_div.find('div').show();
    });
  });

  $('body').on('change', 'select[name="step[server_aspect_ids][]"]', function () {
    $.get($('#step_server_properties_url').val() + '?' + $(this).parents('form:first').serialize(), function (html) {
      $('#server_properties_container').html(html);
    });
  }).triggerHandler('change');

  $('.edit_in_place').livequery(function () {
    $(this).editInPlace();
  });

  $('body').on('change', 'form.no_submit input, form.no_submit select', function () {
    var input = $(this)
    input.parents('form:first').ajaxSubmit(function () {

    });
  });

  $('body').on('change', 'form.no_submit input, form.no_submit select', function () {
    var input = $(this)
    input.hide().spin();
    $('div.request_buttons').find('a, input').attr('disabled', 'disabled')
    input.parents('form:first').ajaxSubmit(function () {
      input.next().remove();
      input.show();
      $('div.request_buttons').find('a, input').removeAttr('disabled')
    });
  });

  $('body').on('click', 'a#mark_uploads_for_delete', function () {
    id = $(this).attr('rel');
    checkbox = $("INPUT[name='upload_for_deletion[]'][type='checkbox']");
    if (checkbox.is(':checked')) {
      var answer = confirm("Are you sure?");
      checkbox.each(function (index) {
        var controller;
        if ($(this).attr('checked') == true) {
          upload_id = $(this).val();
          if ($('a#mark_uploads_for_delete').attr('model') == "step") {
            controller = url_prefix + "/uploads/" + upload_id + "/destroy?step_id=" + id;
          }
          else if ($('a#mark_uploads_for_delete').attr('model') == "activity") {
            controller = url_prefix + "/uploads/" + upload_id + "/destroy?activity_id=" + id;
          }
          else {
            controller = url_prefix + "/uploads/" + upload_id + "/destroy?request_id=" + id;
          }
          //var controller = "/uploads/" + id + "/destroy";
          if (answer) {
            $.ajax({
              type: "delete",
              url: controller,
              success: function (data) {
                $(".uploads_steps_links").html(data);
                if ($('a#mark_uploads_for_delete').attr('model') == "activity") {
                  location.reload(true);
                }
              }
            });
          }
          else {
            return false;
          }
        }
      });
    } else {
      alert("Please select atleast one upload to delete");
    }
  });

  $('body').on('click', 'a#add_field', addField);
  $('body').on('click', 'a.clear_field', clearField);
  $('body').on('click', 'a.remove_field', removeField);

  $('body').on('submit', 'form.ajax', function (event) {
    $(this).ajaxSubmit({ dataType: 'script',
      beforeSend: function () {
        $('form.ajax input.once').attr('disabled', 'disabled');
      },
      success: function () {
        tablesorterTableHeaderArrowAssignment();
        sortable_table_header_arrow_assignment();
      },
      resetForm: true
    });
    return false;
  });

  $('body').on('click', 'a.ajax', function () {
    var link = $(this);
    $.getScript($(this).attr('href'), function () {
      $("#" + link.parents("li:first").attr("parent_tab_id")).addClass("selected");
      sortable_table_header_arrow_assignment();
      tablesorterTableHeaderArrowAssignment();
    });
    if ($(this).attr('rel') == 'remove_prev_flash_notice') {
      $('#flash_error').remove();
    }
    return false;
  });

  $('body').on('click', 'a.templates_ajax', function () {
    $.ajax({
      url: $(this).attr('href'),
      dataType: 'script',
      data: "app_id=" + $('#' + 'request_app_id' + ' :selected').val()
    });
    return false;
  });

  $('body').on('change', 'select.script_argument_values', function () {
    var text_field = $(this).prev();
    text_field.val($(this).val());
  });

  $('body').on('change', 'input.step_script_argument', function () {
    var select_tag = $(this).next();
    select_tag.val('');
  });

  $('a.clear_scheduled_at, a.clear_target_completion_at').click(function () {
    var field_to_clear = $(this).attr('class').match(/clear_(\w+)/)[1];
    $(this).parents('form:first').find('*[id^="request_' + field_to_clear + '"]').val('');
    return false;
  });

  $('#new_step_form #step_name').focus();

  $('select.maps_remote_options').livequery(function () {
    $(this).mapsRemoteOptions();
  });
  //$('.add_step_category').always().updateStepRow();

  $('.use_remote_options').livequery(function () {
    $(this).useRemoteOptions();
  });

  $('select.update_title').livequery(function () {
    $(this).updateDocumentTitleAndHeaderFromSelect();
  });

  $('a[rel*=facebox]').livequery(function () {
    $(this).facebox();
  });

  $('.facebox').livequery(function () {
    $(this).openWithFacebox();
  });

  $('.initialFocus:first').livequery(function () {
    $(this).focus();
  });

  $('form.edit_installed_component').livequery(function () {
    $(this).updateComponentInstallationWithForm();
  });

  $('input.date').livequery(function () {
    $(this).datepicker({
      dateFormat: $('#datepicker_format').val(),
      changeMonth: true,
      changeYear: true,
      showButtonPanel: true,
      closeText: "OK"
    });
    restrictStepEndDateSelection();
  });

  $('a.add_remove').livequery(function () {
    $(this).cancelEverybodyElse().updateParentElement('tr');
  });

  $('a.edit').livequery(function () {
    $(this).cancelEverybodyElse().faceboxOverlayLoader().updateParentElement('tr');
  });

  $('body').on('click', 'a.copy_all_components_link', function () {
    $(this).parents('form').submit();
  });

  $('a.edit_row, a.update_row, a.edit_row_twiddle, a.edit_row_unfolded').livequery(function () {
    $(this).updateParentElement('tr');
  });

  $('a.replace_row').livequery(function () {
    $(this).replaceParentElement('tr');
  });

  $('a.append_row').livequery(function () {
    $(this).appendParentElement('tr');
  });

  //$('select#step_script_id').always().displayStepScriptArgumentsNew();
  //$('select#step_capistrano_script_id').always().displayStepScriptArguments();
  //$('select#step_hudson_script_id').always().displayStepScriptArguments();
  //$('select#step_bladelogic_script_id, select#step_owner_id, input[name=script_type]').always().displayStepScriptArguments();

  $('#property_entry_options').livequery(function () {
    $(this).togglePropertyEntryOptions();
  });

  $('a.cancel').livequery(function () {
    if ($(this).closest('.edit_in_place').length == 0) { // has no ".edit_in_place" parent
      $(this).faceboxOverlayLoader().updateParentElement('td.members');
    }
  });

  $('.create_item a').livequery(function () {
    $(this).newItem();
  });

  $('#steps_list tr.editable > td:not(.last, .step_form, .procedure_step_form)').livequery(function () {
    $(this).linkify().cancelEverybodyElse().faceboxOverlayLoader().updateParentElement('tr');
  });

  $('#get_alternate_servers').livequery(function () {
    $(this).loadAlternateServers();
  });

  $('td.members form.add_remove').livequery(function () {
    $(this).updateParentElementWithAjaxForm('td.members');
  });
  //$('#steps_list form.edit').always().replaceParentElementWithAjaxForm('tr');
  //$('#steps_list form.add').always().replaceParentElementWithAjaxForm('tr');

  $('a.collapsible_heading').livequery(function () {
    $(this).collapsible();
    ;
  });

  $('form.replace_row').livequery(function () {
    $(this).replaceParentElementWithAjaxForm('tr');
  });

  // $('#steps_list form.reset_step').always().spinner();
  $('td.additional_info form').livequery(function () {
    $(this).saveSerialized();
  });

  $('form.update_details_step_form').livequery(function () {
    $(this).updateParentElementWithAjaxForm('#steps_container');
  });

  $('form.delete').livequery(function () {
    $(this).deleteParentRowAfterAjaxSubmit();
  });

  /* $('form.delete').always().submit(function() { return confirm('Are you sure?') }), */
  $('.justAdded').livequery(function () {
    $(this).highlightNextAndRemove();
  });


  $('body').on('submit', 'form.require_confirmation', function () {
    return confirm($(this).attr('data-confirmation') || "Are you sure?");
  });

  registerTableSorters();

  $('.spinner').livequery(function () {
    $(this).spinner();
  });

  $('input[name="user_group_step_owner"]').livequery(function () {
    $(this).toggleStepOwnerSelect();
  });

  $('#step_manual').livequery(function () {
    $(this).toggleStepFields();
  })

  $('input[name=sop_url_file_radio]').livequery(function () {
    $(this).toggleSOPFields();
  });

  $('#steps_list').livequery(function () {
    $(this).eventsForStepsList();
  });

  $('.note_ordering').livequery(function () {
    $(this).updateParentElement('#request_notes');
  });

  $('.activity_ordering').livequery(function () {
    $(this).updateParentElement('#request_activity');
  });

  $('#steps_with_invalid_components').livequery(function () {
    $(this).openUpdateComponentFacebox();
  });

  $('.collapsible_section_heading').livequery(function () {
    $(this).collapsible();
  });

  $('td.step_position').on('click', 'input', function (e) {
    e.stopPropagation();
  });

  $('.collapsible_section_heading_from_children').livequery(function () {
    $(this).collapsibleFromChildren();
  });

  $('div.tiny_step_buttons').find('input').click(function (e) {
    e.stopPropagation();
  });

  $('input[name="custom_value_change_date"]').livequery(function () {
    $(this).setNewPropertyValues();
  });

  $('body').on('change', '.toggles input[type="radio"]', toggleFields);
  $('body').on('click', '.toggles input[type="radio"]', toggleFields);

  $('.toggles input[type="radio"]').livequery(function () {
    $(this).change()
  });
  //$('.toggles input[type="radio"]').livequery(function() { $(this).change() }); // For IE(all versions)

  $('body').on('change', '.toggles select', toggleFields);
  $('.toggles select').livequery(function () {
    $(this).change()
  });

  $('#request_status_form').ajaxForm({ dataType: 'json', success: function (json) {
    $('#request_status_info').html(json.payload);
  }});

  $('.activity_name').blur(function (event) {
    if (!$('.app_name_for_copy').attr('value')) {
      $('.app_name_for_copy').attr('value', this.value);
    }
    ;
  });

  /*$('a.mirror_checkboxes').always().click(function() {
   var checked_in_this_env = $(this).parents('tbody:first').find('input.installed_component_ids:checked').map(function() { return $(this).parents('tr:first')[0] });
   var should_check = checked_in_this_env.map(function() { return $('tr.' + $(this).attr('class').match(/application_component_\d+/)) });

   $('input.installed_component_ids').attr('checked', false);
   should_check.each(function() {
   $(this).find('input.installed_component_ids').attr('checked', true);
   });

   return false;
   });
   */
  $('body').on('click', 'a.clear_all_checkboxes', function () {
    var checked_in_this_env = $(this).parents('tbody:first').find('input.installed_component_ids').map(function () {
      return $(this).parents('tr:first')[0]
    });
    checked_in_this_env.each(function () {
      $(this).find('input.installed_component_ids').attr('checked', false);
    });

    return false;
  });

  $('body').on('click', 'input.submit_form, a.submit_form', submitFormWithNewAction);

  $('body').on('click', 'a.change_step_status_form', function (event) {
    event.preventDefault();
    appendUnfoldedSteps($(this));
  });

  $('body').on('change', 'input.check_duplicates', checkDuplicates);

  $('select.label_color').change(function () {
    $(this).css('background-color', $(this).val());
  });

  $('body').on('change', "#automation_type", function () {
    if ($(this).val() != "") {
      $('.step_auto_only').hide();
      buildScriptList();
    }
  });

  $('body').on('change', 'select#step_script_id', function () {
    if ($(this).val() == "") {
      $('.step_auto_only').hide();
//			alert("Please choose a job")
    } else {
      displayStepScriptArguments();
    }
  });

  $('body').on('click', "#select_all_chk", function () {
    var check_all_checkboxes = this;

    // if there is specific checkboxes to work with
    if ($(check_all_checkboxes).attr('check_box_dom')) {
      toggleCheckBox($(this).attr("check_box_dom"), $(this).is(':checked'));
    }
    // else work in scope of clicked checkbox's table
    else {
      var checkbox_to_toggle = $(check_all_checkboxes).parents('table:first'); //.find('*:checkbox[name^=step]');
      toggleCheckBox(checkbox_to_toggle, $(check_all_checkboxes).is(':checked'));
    }
  });

  // check `check all checkboxes` checkbox if all of
  // checkboxes have been checked
  // otherwise -- uncheck it;
  $('body').on('click', 'table input:checkbox', function () {
    var clickedCheckbox = $(this);
    var checkboxTable = clickedCheckbox.parents('table:first');
    var siblingCheckboxes = checkboxTable.find('input:checkbox[id!=select_all_chk]');
    var checkAllCheckbox = checkboxTable.find('input:checkbox[id=select_all_chk]');

    var allSiblingCheckboxesChecked = true;
    siblingCheckboxes.each(function (i, e) {
      allSiblingCheckboxesChecked = allSiblingCheckboxesChecked && $(e).attr('checked') == 'checked';
    });

    if (allSiblingCheckboxesChecked) {
      checkAllCheckbox.attr('checked', true);
    }
    else {
      checkAllCheckbox.attr('checked', false);
    }
  });

  // check `checkAll` checkbox if all of the checkboxes are checked;
  // doesn't work  :(
  // problem: trigger event on table render
//  $('table').on('render', function(){
//    console.log('i do work');
//    var checkAllCheckboxes  = $('#select_all_chk');
//
//    checkAllCheckboxes.each(function(i, e){
//      // find `check all` checkbox's table
//      var checkboxTable     = e.parents('table:first');
//
//      // find checkboxes in a table scope
//      var siblingCheckboxes = checkboxTable.find('input:checkbox[id!=select_all_chk]');
//      var checkAllCheckbox  = checkboxTable.find('input:checkbox[id=select_all_chk]');
//
//      var allSiblingCheckboxesChecked = true;
//      siblingCheckboxes.each(function(i, e){
//        allSiblingCheckboxesChecked = allSiblingCheckboxesChecked && $(e).attr('checked') == 'checked';
//      });
//
//      if (allSiblingCheckboxesChecked){
//        checkAllCheckbox.attr('checked', true);
//      }
//      else{
//        checkAllCheckbox.attr('checked', false);
//      }
//    });
//  });

  $('body').on('click', 'a[ajax*="true"]', function (event) {
    loadUsingXHR($(this), event);
  });

  $('body').on('change', "#user_first_day_on_calendar", function () {
    ChangeFirstDayOnCalender($(this));
  });

  $('body').on('click', "#fetch_integration", function () {
    showLoader();
  });

  $('body').on('click', "#step_versions", function () {
    showArtifactPath();
  });


  $('body').on('change', "#email", function () {
    $.ajax({
      url: url_prefix + '/get_security_question',
      data: 'email=' + this.value,
      dataType: 'script',
      type: 'post'
    });
  });

  /* RF- (Coffee script not working in IE when upload partial replace through ajax) Uploads Coffee script converted in to functions - start*/
  $('body').on('click', 'form .remove_fields', function (event) {
    $(this).parent().find('input[type=hidden][name*="[_destroy]"]').val('1');
    $(this).closest('fieldset').hide();
    return event.preventDefault();
  });

  $('body').on('click', 'form .add_fields', function (event) {
    var regexp, time;
    time = new Date().getTime();
    regexp = new RegExp($(this).data('id'), 'g');
    $(this).before($(this).data('fields').replace(regexp, time));
    return event.preventDefault();
  });

  $('body').on('click', 'form .edit_attachment, form .cancel_edit, form .apply_edit', function (event) {
    event.preventDefault();
    var $attachment, attachment_description, $description_field, $attachment_description;

    $attachment = $(event.target).closest('fieldset');
    $description_field = $attachment.find('.description_field');
    $attachment_description = $attachment.find('.attachment_description');
    attachment_description_text = $attachment_description.text();
    $attachment.find('.additional_actions, .edit_attachment, .attachment_description').toggle();

    if ($(event.target).hasClass('cancel_edit')) $description_field.val(attachment_description_text);
    if ($(event.target).hasClass('apply_edit')) {
      $attachment_description.text($description_field.val());
      $attachment_description.attr('title', $description_field.val());
    }
  });

  //ajax form uploads
  $('body').on('submit', '#additional_uploads_form', function (event) {
    event.preventDefault();
    $(this).ajaxSubmit({
      type: "POST",
      data: {ajax_upload: 'true'},
      success: function (data, status, xhr) {
        $('#documents_ajax_uploads_section').html(data);
      }
    });
  });
  /*  Uploads Coffee script converted in to functions - end*/
});

function argument_upload_form_hide_add_link() {
  $(".argument_upload_form").each(function () {
    if ($(this).find(".remove_argument_fields").length > 0) {
      return $(this).find("a.add_argument_fields").hide();
    }
  });
}
/*variable used to prevent multiple window opening for script results  */
var scriptResultWin = null;

function registerTableSorters() {
  $(".stepsList").livequery(function () {
    $(this).tablesorter({
      sortList: [
        [1, 0]
      ],
      textExtraction: 'complex',
      widgets: ['zebra'],
      headers: {
        //  9: { sorter: false }
      }
    });
  });

  $('.group_list_sorter').livequery(function () {
    $(this).tablesorter({
      sortList: [
        [0, 0]
      ],
      textExtraction: 'complex',
      widgets: ['zebra'],
      headers: {
        1: { sorter: false },
        2: { sorter: false },
        3: { sorter: false },
        4: { sorter: false }
      }
    });
  });

  $('.team_list_sorter').livequery(function () {
    $(this).tablesorter({
      sortList: [
        [0, 0]
      ],
      textExtraction: 'complex',
      widgets: ['zebra'],
      headers: {
        2: { sorter: false },
        3: { sorter: false }
      }
    });
  });

  $('.one_column_sorter').livequery(function () {
    $(this).tablesorter({
      sortList: [
        [0, 0]
      ],
      textExtraction: 'complex',
      widgets: ['zebra'],
      headers: {
        1: { sorter: false }
      }
    });
  });
  $('.two_column_sorter').livequery(function () {
    $(this).tablesorter({
      sortList: [
        [0, 0]
      ],
      textExtraction: 'complex',
      widgets: ['zebra'],
      headers: {
        2: { sorter: false }
      }
    });
  });
  $('.three_column_sorter').livequery(function () {
    $(this).tablesorter({
      sortList: [
        [0, 0]
      ],
      textExtraction: 'complex',
      widgets: ['zebra'],
      headers: {
        3: { sorter: false }
      }
    });
  });
  $('.four_column_sorter').livequery(function () {
    unbindTablesorterHandlers($(this));
    $(this).tablesorter({
      sortList: [
        [0, 0]
      ],
      textExtraction: 'complex',
      widgets: ['zebra'],
      headers: {
        4: { sorter: false }
      }
    });
  });
  $('.request_templates_sorter').livequery(function () {
    $(this).tablesorter({
      sortList: [
        [0, 0]
      ],
      textExtraction: 'complex',
      widgets: ['zebra'],
      headers: {
        1: { sorter: false },
        2: { sorter: false },
        5: { sorter: false },
        6: { sorter: false }
      }
    });
  });

  $('.project_requests_and_automation_sorter').livequery(function () {
    $(this).tablesorter({
      sortList: [
        [0, 0]
      ],
      textExtraction: 'complex',
      widgets: ['zebra'],
      headers: {
        8: { sorter: false }
      }
    });
  });

}


function elementToggler(element, event) {
  var match = $(element).attr('id').match(/(show|hide)_(\w+)/);
  var action = match[1];
  var type = match[2];

  if (true) $(element).hide();

  var dom_path = $(element).attr("dom_path");
  if (dom_path != undefined) {
    if ($(dom_path).html().length == 0) {
      element = $(element)
      loadUsingXHR(element, event)
    }
  }

  if (action == 'show') {
    $('#hide_' + type).fadeIn();
    $('.' + type).fadeIn();
  } else {
    $('#show_' + type).fadeIn();
    $('.' + type).fadeOut();
  }
}

function loadUsingXHR(element, event) {
  event.preventDefault();
  $.get(element.attr("href"), function (data) {
    $(element.attr("dom_path")).html(data);
  });
}

function toggleCheckBox(dom, checked_val) {
  $(dom).find("input[type=checkbox]:enabled").each(function () {
    $(this).attr("checked", checked_val);
  });
}

function selectCheckboxes(ids, dom_prefix) {
//alert(ids);
  $.each(ids, function (index, id) {
    $(dom_prefix + id).attr("checked", true);
  });
}

function toggleElem(elementId) {
  $("#" + elementId).toggle();
}

function toggleSection(clickedLink) {
  var rel = clickedLink.attr('rel')
  var title = clickedLink.html();
  clickedLink.html(rel);
  clickedLink.attr('rel', $.trim(title));
  toggleElem(clickedLink.attr('class'));
}

//function toggleSectionFilter(){
//    var f_state = $("#filter_block_collapse_state_flag").val();
//    if (f_state == '1') {
//         $("#filter_form").parent('div').parent('div').hide();
//    }else {
//        $("#filter_form").parent('div').parent('div').show();
//    }
//}

function plan_map_scroll() {
  //CHKME,Sourabh,2012-01-09,should same ids be assigned to all elements with a particular css tag??
  $(".content").attr("id", "content_box");
  if (document.getElementById('content_box') != null) {
    var plans_content_width = document.getElementById('content_box').offsetWidth;
    var maps_content_width = document.getElementById('content_box').offsetWidth;
  }
  var apply_width = document.body.clientWidth - 280;

  $(".plans .horizontal_scroll .top_div").css({'width': apply_width + 10 + "px"});
  $(".plans .btm_border").css({'width': apply_width + 10 + "px", overflow: 'auto'});
  $(".plans .version_report_scroll").css('width', apply_width - 115 + "px");

  //$(".maps .vscroll_960").css('width',apply_width-7+"px");
  //$(".cont_horizontal_scroll").always().css('width',apply_width-12+"px");
  //$(".plans .^").css('width',apply_width+"px");
  $(".plans .left .content").css('width', apply_width + "px");

}

function blink_text() {
  var blink_class = ["step_status_in_process"];
  $(blink_class).each(function (index, value) {
    if ($('.' + value + ' .state').html() == "In process") {
      $('.' + value + ' .state').html("&nbsp;");
    }
    else {
      $('.' + value + ' .state').html("In process");
    }
  })
}
function start_blink() {
  setInterval("blink_text()", 600);
}

function setPlanEnvDetails() {
  if ($("#lifecyle_env_ids").length > 0) {
    plan_environments = $("#lifecyle_env_ids").val().split(",");
    $.each(plan_environments, function (index, value) {
      $("#request_environment_id").find("option[value='" + value + "']").attr("selected_option", "yes");
    });
    $("#request_environment_id").find("option").each(function () {
      if ($(this).attr("selected_option") == null) $(this).remove();
    });
  }
}

// Ex. [1,2,3].compare([2,4,5]);
$.fn.compare = function (t) {
  if (this.length != t.length) {
    return false;
  }
  var a = this.sort(),
      b = t.sort();
  for (var i = 0; t[i]; i++) {
    if (a[i] !== b[i]) {
      return false;
    }
  }
  return true;
};

$.fn.extend({
  scrollTo: function (speed, easing) {
    return this.each(function () {
      var targetOffset = $(this).offset().top;
      $('html,body').animate({scrollTop: targetOffset}, speed, easing);
    });
  }
});

$.fn.extend({
  toggleValues: function (first, second) {
    if ($(this).val() == first) {
      $(this).val(second);
    } else {
      $(this).val(first);
    }
  }
});

$.expr[':'].regex = function (elem, index, match) {
  var matchParams = match[3].split(','),
      validLabels = /^(data|css):/,
      attr = {
        method: matchParams[0].match(validLabels) ? matchParams[0].split(':')[0] : 'attr',
        property: matchParams.shift().replace(validLabels, '')
      },
      regexFlags = 'ig',
      regex = new RegExp(matchParams.join('').replace(/^\s+|\s+$/g, ''), regexFlags);
  return regex.test($(elem)[attr.method](attr.property));
}

function show_drop_down() {
  $('body').on('mouseover', ".server_tabs li, #primaryNav ul li", function () {
    $(this).find(".drop_down").show();
    var height = $(this).find(".drop_down").height();
    if (height > 200) {
      $(this).find(".drop_down").addClass('scrl');
    } else {
    }
  });
  $('body').on('mouseout', ".server_tabs li, #primaryNav ul li", function () {
    $(this).find(".drop_down").hide();
  });
}

function showLoader(overlayPopup) {
  $('#wait').show();
  if (overlayPopup) $('#facebox_overlay').css('z-index', '999');
  $('#facebox_overlay').show();
}

function hideLoader(overlayPopup) {
  $('#wait').hide();
  if (overlayPopup) $('#facebox_overlay').css('z-index', '99');
  $('#facebox_overlay').hide();
}

function initAjaxIndicator() {

  $('#wait').hide().ajaxStart(function () {

    if ($("#no_overlay").length == 0) {
      $('.loading').hide();
      /*Hiding facebox spinner to avoid mulitiple loding images, ref defect DE71906*/
      showLoader();
    }
  }).ajaxStop(function () {
    if ($("#facebox").is(':visible')) {
      $('#wait').hide();
    } else {
      hideLoader();
    }
  });
}

function updateUserStatus(url, frequency) {
  setInterval(function () {
        updateLastResponse(url)
      },
          parseInt(frequency) * 1000)
}

function updateLastResponse(url) {
  $.ajax({
    url: url + ".json",
    type: "PUT",
    beforeSend: function () {
      if ($("#facebox").is(":visible") || $("#wait").is(":visible")) {
        showLoader();
      } else {
        hideLoader();
      }
    },
    success: function (user_ids) {
      if (user_ids == null) {
        user_ids = "";
      }
      var user_ids = user_ids.split(",");
      $(".ui-button").hide();
      $(".online_user").hide();
      $("#user_list").show();
      user_ids.length == 0 ? $("#no_users").show() : $("#no_users").hide();
      $.each(user_ids, function (id, user_id) {
        $("#user_" + user_id).show();
      });
    }
  })
}

function ajaxifyAlphabeticalPagination() {
  if ($('.alpha_pagination').children().eq(1).attr('id') == 'current_page') {
    $('.alpha_pagination').find('a:first').hide();
  }
  if ($('.alpha_pagination a:last-child').prev().attr('id') == 'current_page') {
    $('.alpha_pagination a:last-child').hide();
  }

  $('body').on('click', ".alpha_pagination a", function (event) {
    event.preventDefault();
    var div_id = $(this).attr("class_name");
    var pagination_link = $(this);
    //var pageNo = $(this).attr("href").match(/page=([0-9]+)/);
    $.get($(this).attr("href"), { /* page: pageNo, */ "render_no_rjs": "true"}, function (data) {
      $('#' + div_id).html(data);
      $('#' + resultContainerId(pagination_link)).html(data);
    });
  });
  tablesorterTableHeaderArrowAssignment();
}

function displayingServerRecords(link) {
  return link.attr("class_name").match(/server/) == "server";
}

function resultContainerId(link) {
  displayingServerRecords(link) ? "server_container" : "search_result"
}

function showCommonRequestEnvs(options) {
  if ($("#request_environment_id").length > 0) {
    ShowCommonEnvs(options);
  }
}

function ChangeFirstDayOnCalender(first_day) {
  var day = first_day.val();
  $.ajax({
    url: url_prefix + "/update_profile",
    data: {"user[first_day_on_calendar]": day},
    type: "PUT"
  });
}

function getUrlVars(url, param) {
  var arr = []
  var vars = [], hash;
  var hashes = url.slice(url.indexOf('?') + 1).split('&');

  for (var i = 0; i < hashes.length; i++) {
    hash = hashes[i].split('=');
    vars[hash[0]] = hash[1];
    if (hash[0] == param) {
      arr.push(hash[1]);
    }
  }

  arr = uniqArray(arr);
  return arr;
}

function updatingOptionsAfterValueChange(target, submit_button, selectedOptions) {
  if (target.attr('rel') == 'step_phase_id') {
    $('#' + target.attr('rel')).change(function () {
      updateOptionsWithLimitedData(submit_button, target, '#step_phase_id', selectedOptions)
    }).change();
  } else if (target.attr('click_env')) {
    /* IE doesn't support event handling on option tag, hence conveted option click event to select onchange event*/
    $('body').on('change', '#' + target.attr('rel'), function () {
      var sel_ele = $(this);
      var sel_val = $(this).val();
      var opt = '';
      $(sel_ele).find("option").each(function () {
        if ($(this).val() == sel_val) {
          opt = $(this);
          return;
        }
      });
      if ($(opt).attr("class") == undefined || $(opt).attr("class").length == 0) {
        $(opt).attr("selected", "selected");
      }
      $(sel_ele).find("option.clicked").attr("selected", "selected");
      $(sel_ele).find("option.unclicked").removeAttr("selected");
      updateOptions(submit_button, target, selectedOptions)
    }).not(':disabled').change();
  } else {
    $('#' + target.attr('rel')).change(function () {
      updateOptionsWithLimitedData(submit_button, target, 'select, #request_scheduled_at_date', selectedOptions)
    }).not(':disabled').change();
  }
}

function checkSelectedSteps() {
  var steps = $(".step_position").find("input[type='checkbox']").map(function () {
    if ($(this).is(':checked')) return $(this)
  });

  // Collecting Step IDS
  var step_ids = [];
  if (steps.length > 0) {
    steps.each(function () {
      step_ids.push(parseInt($(this).attr("id").replace(/[^0-9]/g, '')));
    });
  }
  return step_ids;
}

function ajax_call_on_script_edit(dis) {

  $.get($(dis).attr('href'), function (html) {
    $(dis).parents('tr').eq(0).replaceWith(html);
  });

}

function faceboxScroll() {
  var page_height = document.body.clientHeight - 116;
  $("#facebox").find(".content").css('max-height', page_height + 'px');
}

function open_preview_script_window(url) {
  if ((preViewWin != null) && (typeof(preViewWin) == "object")) {
    if (!preViewWin.closed) {
      preViewWin.close();
    }
  }
  preViewWin = window.open(url, '_blank', 'height=600,width=800,toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes');
  return false;
}

function open_script_result_window(url){
  if ((scriptResultWin != null) && (typeof(scriptResultWin) == "object")){
    if (!scriptResultWin.closed){
      scriptResultWin.close();
    }
  }
  scriptResultWin = window.open(url.replace('#', '%23'),'_blank','height=300,width=600, toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes');
  return false;
}

function sortable_table_header_arrow_assignment() {
  if ($.browser.msie && $.browser.version == 7) {
    $('.sortable.asc').append('<span class="asc" style="float: right; margin-top: -12px;margin-right:-5px;">&nbsp;</span>')
    $('.sortable.asc').addClass('IE7asc').removeClass('asc');
    $('.sortable.desc').append('<span class="desc" style="float: right; margin-top: -12px;margin-right:-5px;">&nbsp;</span>')
    $('.sortable.desc').addClass('IE7desc').removeClass('desc');
  }
}

function tablesorterTableHeaderArrowAssignment() {

  if ($.browser.msie && $.browser.version == 7) {

    $('.header.IE7headerSortDown').find('span.headerSortDown').remove();
    $('.header.IE7headerSortDown').removeClass('IE7headerSortDown');
    $('.header.IE7headerSortUp').find('span.headerSortUp').remove();
    $('.header.IE7headerSortUp').removeClass('IE7headerSortUp');

    $('.header.headerSortUp').append('<span class="headerSortUp" style="display: block; margin-top: -12px;float:right;margin-right:-5px;">&nbsp;</span>');
    $('.header.headerSortUp').addClass('IE7headerSortUp').removeClass('headerSortUp');
    $('.header.headerSortDown').append('<span class="headerSortDown" style="display: block; margin-top: -12px;float:right;margin-right:-5px;">&nbsp;</span>');
    $('.header.headerSortDown').addClass('IE7headerSortDown').removeClass('headerSortDown');
  }
}

function remote_option_load_to_form_field_environments(server_lvl_id) {
  $('body').on('change', "#server_aspect_parent_type_and_id", function (event) {
    $.ajax({data: 'server_aspect_parent_type_and_id=' + escape($("#server_aspect_parent_type_and_id").val()), dataType: 'script', type: 'post', url: url_prefix + "/environment/server_levels/" + server_lvl_id + "/server_aspects/update_environmentsList"})
  });
}

function restrictStepEndDateSelection() {
  $('#step_complete_by_date').datepicker('option', 'minDate', $('#step_start_by_date').datepicker('getDate'));
}

var restrictRequestFilterEndDateSelection = function () {
  $('#end_date').datepicker('option', 'minDate', $('#beginning_date').datepicker('getDate'));
}

function unbindTablesorterHandlers(element) {
  element
    .unbind('appendCache applyWidgetId applyWidgets sorton update updateCell')
    .find('thead th')
      .unbind('click mousedown')
      .removeClass('header headerSortDown headerSortUp');
}
