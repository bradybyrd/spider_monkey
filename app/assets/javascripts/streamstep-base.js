////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

asset_field_number = 1
StreamStep = {}

// Set up a global AJAX error handler to handle the 401
// unauthorized responses. If a 401 status code comes back,
// the user is no longer logged-into the system and can not
// use it properly.
$.ajaxSetup({
  statusCode: {
    401: function () {
      // Redirect the to the login page.
      location.href = url_prefix + "/";
    }
  }
});

// Callback receives responseText and 'success' / 'error'
// based on response.
//
// settings hash:
//   facebox: true        // a facebox 'loading' will open pre-submit
//   confirmation: string // a confirm pop-up will open with the supplied string
$.fn.appjax = function (callback, settings) {
  var settings = settings || {}
  // var options  = { dataType: 'json' }
  var options = {};

  options.complete = function (xhr, ok) {
    callback.call(this, xhr.responseText, ok)
  }

  if (settings.confirmation) {
    options.beforeSubmit = function () {
      var execute = confirm(settings.confirmation);
      if (!execute) return false;
      if (settings.facebox) $.facebox.loading();
    }
  } else if (settings.facebox) {
    options.beforeSubmit = $.facebox.loading;
  }
  $(this).ajaxForm($.extend(settings, options));

  return this;
}

$.browser.ie6 = $.browser.msie && $.browser.version == "6.0"

// generic error and success faceboxes
$.errorBox = function (text) {
  $.facebox("<h2 class=\"title\">You forgot something, didn't you?</h2>" + text);
}

$.successBox = function (text) {
  $.facebox('<h2 class="title">Success</h2>' + text);
}

$.flashNotice = function (text) {
}

function toggleTextarea(noteId, anchorID) {
  if (!anchorID) {
    anchorID = 'noteToggle';
  }

  var textarea = $('#' + noteId);
  var link = $('#' + anchorID);

  if (textarea.attr('class') == 'expand') {
    textarea.attr('class', 'expanded');
    link.html('collapse');
    document.cookie = "noteId=expanded";
  }
  else {
    textarea.attr('class', 'expand');
    link.html('expand');
    var cookie_date = new Date();  // current date & time
    cookie_date.setTime(cookie_date.getTime() - 1);
    document.cookie = "noteId=;expires=" + cookie_date.toGMTString();
  }
}

Date.format = 'yyyy-mm-dd';

$.fn.extend({
  replaceWithElementOfSameTag: function (content) {
    var tagName = this[0].tagName
    return this.replaceWith($(content).find(tagName).andSelf().filter(tagName));
  },

  appendAjaxFlag: function () {
    return this.append('<input type="hidden" name="_ajax_flag" value="true" />');
  },

  filterDraggables: function () {
    return this.not('.dragging, .helping');
  },

  setupHelpBox: function () {
    $(this).hover(function () {
          $(this).next('.help_box').css("display", "inline");
        },
        function () {
          $(this).next('.help_box').hide();
        });
  },

  updateComponentInstallationWithForm: function () {
    if (this.attr('rel') == undefined) {
      this.ajaxForm({ dataType: 'json', success: function (json) {
        var parentId = '#installed_component_' + json.id;
        $(parentId + ' .installed_component_version').html(json.version);
        $.facebox.close();
      }});
    }
  },

  linkify: function () {
    this.click(function () {
      var row = $(this).parents('tr:first');

      if (row.attr('id')) {
        setTimeout("setting_delay();", 1000)
        var step_id = row.attr('id').match(/step_(\d+)/)[1];
        var step_position = row.attr('id').split('_')[2];
        var edit_path = row.find('#step_' + step_id + '_' + step_position + '_edit_path').val();
        $(this).attr('href', edit_path);
      }
    });
    return this;
  },

  appendParentElement: function (selector) {
    return this.click(function () {
      var element = $(this).parents(selector).eq(0);
      var flag = true;
      $("table#scripts_list tr").each(function () {
        if ($(this).attr("id") != undefined && $(this).attr("id") == $(element).attr("rel")) {
          element.hide();
          $(this).show();
          flag = false;
        }
      });
      if (flag) {
        $.get($(this).attr('href'), function (html) {
          $(element).before(html);
          $(element).attr("rel", $(html).attr("id")).hide();
        });
      }
      return false;
    });
  },

  updateParentElement: function (selector) {
    return this.click(function () {
      if ($(this).attr('update_div') == undefined) {
        var element = $(this).parents(selector).eq(0);
      }
      else {
        var element = $("#" + $(this).attr('update_div'))
      }

      // RVJ: This is a wiered issue.
      // AJAX calls sometimes return html and sometimes returns html
      // This causes this function to behave wierdly and not work at some places
      // So I have done this workaround that seems to work at most of the places.
      // It looks dumb, but atleast it does seem to work
      // Verified that this works at atleast following places:
      // 1. Inline edit  App name, then cancel
      // 2. Create a step in request design view
      // 3. Save a step in request design view
      // 4. Cancel creating a step in request design view
      if (element.size() > 0) {
        element.load($(this).attr('href'));
      }
      else {
        $.ajax({
          url: $(this).attr('href'),
          success: function (data) {
            element.replaceWith(data);
          }
        });
      }
      return false;
    });
  },

  replaceParentElement: function (selector) {
    return this.click(function () {
      var element = $(this).parents(selector).eq(0);
      $.get($(this).attr('href'), function (html) {
        element.replaceWith(html);
        add_color_to_step_rows($("#steps_list"))
      });
      return false;
    });
  },

  updateElement: function (selector) {
    return this.click(function () {
      var element = $(selector).eq(0);
      var table = $(element).parents("table:first")
      if (!table.is(':visible')) {
        table.show();
      }
      var table = $(element).parents("table:first")
      if (!table.is(':visible')) {
        table.show();
      }
      element.load($(this).attr('href'));
      return false;
    });
  },

  updateParentElementWithAjaxForm: function (selector) {
    this.each(function () {
      $(this).ajaxForm({target: $(this).parents(selector).eq(0)});
    });
  },

  replaceParentElementWithAjaxForm: function (selector, options) {
    this.each(function () {
      var parent = $(this).parents(selector).eq(0);
      options = $.extend({
        success: function (content) {
          parent.next('.delete_with_parent').remove();
          parent.replaceWithElementOfSameTag(content);
        }
      }, options || {});
      $(this).appendAjaxFlag().ajaxForm(options);
    });
  },

  deleteParentRowAfterAjaxSubmit: function () {
    this.each(function () {
      var form = $(this);
      form.ajaxForm({
        beforeSubmit: function () {
          return confirm(form.attr('data-confirmation') || 'Are you sure?')
        },
        success: function () {
          parent_id = form.parents('tr:first').attr('id').match(/(\d+)/)[1];
          form.parents('table:first').find('tr.parent_' + parent_id).remove();

          form.parents('tr:first').next('.delete_with_parent').remove();
          form.parents('tr:first').remove();
        }
      });
    });
  },

  highlightNextAndRemove: function () {
    this.next().highlight();
    this.remove();
  },

  newItem: function () {
    this.each(function () {
      $(this).click(function () {
        var newItem = $(this).parents('tr:first').prev('.new_item');
        newItem.clone()
            .insertBefore(newItem)
            .removeClass('new_item')
            .show()
            .find('input[type=text]')
            .removeAttr('disabled')
            .focus();
        return false;
      });
    });
  },

  useRemoteOptions: function () {
    this.each(function () {
      var target = $(this);
      var hiddenField = $('#selected_' + this.id);
      var multipleSelect = eval($('#multiple_selected_' + this.id).val()) || [];

      var selectedOptions = multipleSelect.concat(hiddenField.val());
      var submit_button = target.parents('form:first').find('input[type="submit"]');

      target.change(function () {
        hiddenField.val(target.val());
      });
      updatingOptionsAfterValueChange(target, submit_button, selectedOptions)
    });
  },

  mapsRemoteOptions: function () {
    this.change(function () {
      $(this).parents('form').ajaxSubmit({url: $('#maps_remote_options_url').val(), dataType: 'script'});
    }).change();
  },

  saveSerialized: function () {
    this.submit(function () {
      $(this).data('serialized', $(this).serialize());
    }).each(function () {
      $(this).triggerHandler('submit')
    });

    return this;
  },

  autoUpdate: function () {
    this.each(function () {
      updateSteps();
    });
  },

  dateTimePicker: function () {
    this.click(function () {
      var link = $(this);
      $.facebox(function () {
        $.get(link.attr('href') + '&date_field=' + link.prev().val(), function (html) {
          $.facebox(html)
        });
      });

      return false;
    });
  },

  openWithFacebox: function () {
    this.each(function () {
      $.facebox(this)
    }).show();
    return this;
  },

  toggleText: function (this_text, that_text) {
    if (this.html().match(this_text)) {
      this.html(this.html().replace(this_text, that_text));
    } else {
      this.html(this.html().replace(that_text, this_text));
    }
    return this;
  },

  eventsForStepsList: function () {
    this.stripeTableForStepPhases();
    this.completedStepEvents();
  },

  stripeTableForStepPhases: function () {
    add_color_to_step_rows(this);
  },

  completedStepEvents: function () {
    if (this.find('tr.incomplete_step').length > 0)
      $('#reorder_steps:not(.no_toggle)').show();
    else
      $('#reorder_steps:not(.no_toggle)').hide();
  },

  togglePropertyEntryOptions: function () {
    var container = this;
    this.find('input').change(function () {
      if (container.find('input:checked').val() == 'true') {
        $('#tasks_field').show();
      } else {
        $('#tasks_field').hide();
      }
    }).triggerHandler('change');
  },

  toggleStepOwnerSelect: function () {
    radio = this;
    this.change(function () {
      if ($('#user_group_step_owner_user').attr('checked')) {
        $('.step_user_only').show().find('input, select').removeAttr('disabled');
        $('.step_group_only').hide().find('input, select').attr('disabled', 'disabled');
      } else {
        $('.step_group_only').show().find('input, select').removeAttr('disabled');
        $('.step_user_only').hide().find('input, select').attr('disabled', 'disabled');
      }
    });
  },

  toggleStepFields: function () {
    this.click(function () {
      if ($(this).attr('checked')) {
        $('.step_auto_only').show().find(':input').removeAttr('disabled');
        $('.step_manual_only').hide().find(':input').attr('disabled', true);
        $('input[name="step[script_type]"]').change();
      } else {
        $('.step_auto_only').hide().find(':input').attr('disabled', true);
        $('.step_manual_only').show().find(':input').removeAttr('disabled');
      }
    }).triggerHandler('click');
  },

  toggleSOPFields: function () {
    this.change(function () {
      if ($('input[name=sop_url_file_radio]:checked').val() == 'url') {
        $('.sop_url_only').show();
        $('.sop_file_only').hide();
      } else {
        $('.sop_url_only').hide();
        $('.sop_file_only').show();
      }
    }).triggerHandler('change');
  },

  displayStepScriptAuthentication: function () {
    this.change(function () {
      var row = $(this).parents('tr:first');
      var form = row.find('.step_update_script_authentication');

      form.find('#bladelogic_script_id').val(row.find('#step_bladelogic_script_id').val());
      form.find('#step_owner_id').val(row.find('#step_owner_id').val());

      form.ajaxSubmit(function (html) {
        $('#script_authentication_section').html(html).prev()[html.match('table') ? 'show' : 'hide']();
      });
    }).triggerHandler('change');
  },

  setNewPropertyValues: function () {

    this.change(function () {
      form = $(this).parents('form');

      form.ajaxSubmit(function (json) {
        json = eval(json);

        app_env_id = json.pop().application_environment_id;

        $.each(json, function (index, field_value) {
          td = $('#properties_map_' + app_env_id + '_' + field_value.property_id);
          td.html(field_value.value);

          if (field_value.needs_highlight) {
            td.css({ backgroundColor: 'yellow' });
          } else {
            td.css({ backgroundColor: '' });
          }

        });
      });
    });

  },

  openUpdateComponentFacebox: function () {
    this.openWithFacebox();
    if (this.length > 0) {
      $(document).bind('close.facebox', function () {
        window.location.href = window.location.href;
      });
    }
  },

  editInPlace: function () {
    this.each(function () {
      var eip = $(this);
      var link = eip.find('a.activate');
      link.click(function (event) {
        event.preventDefault();
        link.hide();
        eip.find('.show').hide();
        eip.find('.editable').addClass('visible').find(':text').focus();
      });
      eip.find('.cancel').click(function (event) {
        event.preventDefault();
        link.show();
        eip.find('.show').show();
        eip.find('.editable').removeClass('visible');
      });
    });
  },

  loadResponseIntoTarget: function (target) {
    this.click(function () {
      link = $(this);
      target = $(target);
      target.load(link.attr('href'), function () {
        target.fadeIn();
      });
      return false;
    });
  },

  cancelEverybodyElse: function () {
    return this.click(function () {
      $(this).parents('#steps_list').find('#new_step_form a.cancel').click();
    });
  },

  faceboxOverlayLoader: function () {
    return this.click(function () {
      showLoader();
    });
  },

  collapsibleFromChildren: function () {
    this.each(function () {
      var parent = $(this);
      return parent.children(parent.attr('data-collapse-child-filter')).click(
          function () {
            collapsibleActions(parent);
            return false;
          }
      );
    });
  },

  collapsible: function () {
    return this.click(function () {
      collapsibleActions($(this));
      return false;
    });
  },

  loadProperties: function () {
    return this.change(function () {
      var prop_reload_call = true;
      var svr_prop_reload_call = true;
      if (typeof step_tab_loading_flag != 'undefined') {
        if (step_tab_loading_flag != null) {
          if ($('#st_properties a').hasClass('tab_loaded')) {
            prop_reload_call = false;
          }
          if ($('#st_server_properties a').hasClass('tab_loaded')) {
            svr_prop_reload_call = false;
          }
        }
      }
      /*RF: nulified the glaoble variable to make sure that the actual component onchange trigger works fine.*/
      step_tab_loading_flag = null;

      changedSelectList = $(this);
      var stepForm = changedSelectList.parents('form:first');
      if (stepForm.attr("action").indexOf("bulk_update") != -1) return false;

      /* always on page*/
      var step_component_id = stepForm.find("#step_component_id");
      var step_version_tag_id = $("#step_version_tag_id").val();
      var step_version_text = $("#step_version").val();
      var step_properties_load_path = $("#step_properties_load_path");
      var step_server_properties_load_path = $("#step_server_properties_load_path");
      var executor_data_entry = stepForm.data("executorEntry");
      var step_id = stepForm.find("#Step_id").val();

      /*
       var app_package_template_items = stepForm.find("#app_package_template_items");
       */
      /* Automation tab*/
      var step_bladelogic_script_id = stepForm.find("#step_bladelogic_script_id");
      var step_capistrano_script_id = stepForm.find("#step_capistrano_script_id");
      var step_script_id = $("#step_script_id").val();

      /* Properties tab*/
      var properties_container = stepForm.find("#properties_container");
      /* Server properties tab*/
      var server_properties_container = stepForm.find("#server_properties_container");
      /* General Tab*/
      var step_work_task_id = stepForm.find("#step_work_task_id");

      step_bladelogic_script_id.change();
      step_capistrano_script_id.change();

      step_component_id_val = step_component_id.val();

      var url_params = {
        step: { component_id: step_component_id_val, version_tag_id: step_version_tag_id,
          component_version: step_version_text },
        step_id: step_id, work_task_id: step_work_task_id.val()
      }

      if (prop_reload_call == true && properties_container.length > 0) {
        $.get(step_properties_load_path.val(), $.extend({}, url_params, { container: properties_container.attr('id') }));
      }

      if (step_component_id_val == "") {
        $('#properties_container_new').hide();
        $('#horizontal_rule').hide();
      }
      else {
        if (svr_prop_reload_call == true) {
          var params = $.extend(true, {}, url_params, { step: { executor_data_entry: executor_data_entry } },
              { load_component_version: 1, container: 'properties_container_new' });
          $.get(step_properties_load_path.val(), params);
        }

        $('#properties_container_new').show();
        //$('#horizontal_rule').show();
      }

      // Note: the ajax request is triggered when we click on `server properties` tab within a step;
      //  It calls the request_controller's `server_properties_for_step` method and renders content
      //  nevertheless it has been loaded and rendered before(!) by step_controller's `load_tab_data` method.
      // So why do we need this?
      // TODO: double request on getting server properties. Remove one;

      // Do not reload Server Properties when Task is changed
      if ($(this).attr('id') != 'step_work_task_id') {
        if (svr_prop_reload_call == true) {
          var step_id_str = "";
          var step_input = null;
          if (stepForm.find("#Step_id") && (step_input = stepForm.find("#Step_id")[0]) &&
              step_input.value && !isNaN(parseInt(step_input.value))) {
            step_id_str = "&step_id=" + step_input.value;
          }
          var url = step_server_properties_load_path.val() + '?component_id=' + step_component_id_val + step_id_str;
          server_properties_container.load(encodeURI(url), function () {
            setServerAspectCheckboxes(changedSelectList);
          });
        }
      }
      /* }*/
    });
  },

  toggleAppAndEnvSelects: function () {
    this.click(function () {
      if ($(this).attr('checked')) {
        $(this).parents('form:first').find('select').attr('disabled', 'disabled');
      } else {
        $(this).parents('form:first').find('select').removeAttr('disabled');
      }
    }).triggerHandler('click');

    return this;
  },

  updateStepRow: function () {
    this.submit(function () {
      $(this).ajaxSubmit(function (html) {
        $('#steps_container').html(html);
      });
      $(document).trigger('close.facebox');
      return false;
    });
  },

  updateDocumentTitleAndHeaderFromSelect: function () {
    this.change(function () {
      newTitle = $(this).find('option:selected').html();

      toBeReplaced = document.title.match(/Stream Step (.*)/)[1];
      document.title = document.title.replace(toBeReplaced, '- ' + newTitle);

      $('div.pageSection').children('h1:first').html(newTitle);
    }).change();
  },

  spinner: function () {
    this.click(function () {
      $(this).hide().spin();
    });

    return this;
  },

  loadAlternateServers: function () {
    this.click(function () {
      var form = $('<form method="POST" />');

      var params = {};
      $('#alternate_servers_container').find('input, select').each(function () {
        params[$(this).attr('name')] = $(this).val();
      });

      form.ajaxSubmit({
        url: $(this).attr('data-form-action'),
        data: params,
        success: function (html) {
          $('#alternate_servers').html(html);
        }
      });

      return false;
    });

    return this;
  },

  toggleTinyButtons: function () {
    return this.click(function () {
      var step_id = $(this).parents('tr:first').attr('id').match(/\d+/)[0];
      $('div#tiny_step_buttons_' + step_id).toggle();
    });
  }

});


function setServerAspectCheckboxes(selectList) {
  var parentForm = selectList.parents('form:first');
  var stepId = parentForm.find("#Step_id").val();
  if (stepId != '') {
    var serverIds_raw = parentForm.find("#server_ids").val();
    if (typeof(server_Ids_raw) != 'undefined') {
      var serverIds = serverIds_raw.split(',');
      $.each(serverIds, function (index, s_id) {
        if ($("#server_" + s_id).length > 0) {
          $("#server_" + s_id).attr('checked', true);
        }
      });
    }
  }
}

function addField() {
  asset_field_number += 1
  var fields = $('span.dynamic_fields');
  var new_fields_span = $('span#field_for_clone');
  var new_field = new_fields_span.clone(true).removeAttr('id');
  new_field.insertBefore(new_fields_span).show().find('input').attr("id", asset_field_number).focus();
  return false;
}

function removeField() {
  $(this).parents('span:first').remove();
  return false;
}

function clearField() {
  $(this).prev().val('');
  return false;
}

function removeComponent(divId, submitUrl) {
  $(divId).ajaxSubmit({
    url: submitUrl,
    type: 'POST',
    data: { _method: 'put' },
    beforeSubmit: function () {
      return confirm('Are you sure you want to remove this component?');
    },
    success: function () {
      $(divId).parents('tr:first').remove();
    }
  });
}

function collapsibleActions(heading) {
  if (heading.data('is-fetching-section')) return;
  var section = $('#' + heading.attr('id').replace('heading', 'section'));
  var current_step_id = (heading.attr('id').replace('_heading', ''));
  $("#hidden_divs_list").val($("#hidden_divs_list").val() + ',' + current_step_id);
  if ($("#" + current_step_id + "_heading").find(".spinner_request").length == 0) {
    if (section.length > 0) {
      $(heading).toggleClass('unfolded');
      toggleExtraCollapsibleElement(heading);
      //section.toggle();

      var elem = $(section)[0];
      heading_parent_id = heading.parents("tr:first").attr("id");
      if (elem.style.display == 'none') {
        $(section).show();
        if (heading_parent_id) {
          appendToCookieList('step-toggles', "step_" + heading_parent_id.split("_")[1] + "_id_" + heading.attr('id'));
        }
      } else {
        $(section).hide();
        if (heading_parent_id) {
          removeFromCookieList('step-toggles', "step_" + heading_parent_id.split("_")[1] + "_id_" + heading.attr('id'));
        }
        $.cookie("step_" + current_step_id, null);
      }
    }
    else {
      heading.data('is-fetching-section', true);
      $.get(heading.attr('data-section-url'), function (html) {
        toggleExtraCollapsibleElement(heading)
        heading.after(html);
        heading.toggleClass('unfolded');
        heading.next().addClass(heading.attr('class').match(/(even|odd)_step_phase/)[0]);
        heading.data('is-fetching-section', false);
      });
    }
    toggleLastClassForCollapsible(heading, section);
  }
}

function toggleExtraCollapsibleElement(heading) {
  var element_selector = heading.attr('data-extra-toggle-selector')
  if (element_selector) $(element_selector).toggle();
}

function toggleLastClassForCollapsible(heading, section) {
  if ($(heading).hasClass('last')) {
    $(heading).removeClass('last');
    $(heading).addClass('was_last');
    section.addClass('last');
  } else if ($(heading).hasClass('was_last')) {
    $(heading).removeClass('was_last');
    $(heading).addClass('last');
    section.removeClass('last');
  }
}

function toggleFields() {
  var toggles_div = $(this).parents('.toggles:first');
  var selected_input = toggles_div.find('input:checked, option:selected');
  var other_inputs = toggles_div.find('input:not(:checked), option:not(:selected)');

  other_inputs.each(function () {
    $('span.' + $(this).val() + '_fields').hide().find('input, select').attr('disabled', 'disabled');
  });

  $('span.' + selected_input.val() + '_fields').show().find('input, select').removeAttr('disabled').change();
}

function submitFormWithNewAction() {
  var form = getForm($(this));
  saveForm(form, $(this));
  setFormAction(form, $(this));
  setFormMethod(form, $(this));

  form.unbind('submit');

  setFormAjax(form, $(this));

  form.submit();

  return false;
}

function getForm(submitter) {
  var explicit_id = submitter.attr('data-form-id');

  if (explicit_id)
    return $('#' + explicit_id);
  else
    return submitter.parents('form:first');
}

function saveForm(form, submitter) {
  if (submitter.attr('data-restore-form')) {
    form.data('needsRestore', true);
    form.data('action', form.attr('action'));
    form.data('method', form.find('input[name=_method]').val());
  }
}

function restoreForm(form) {
  if (form.data('needsRestore')) {
    form.attr('action', form.data('action'));
    form.find('input[name=_method]').val(form.data('method'));
    form.unbind('submit', form.data('ajaxEventHandler'));
    form.data('needsRestore', false);
  }
}

function setFormAction(form, submitter) {
  form.attr('action', submitter.attr('data-form-action') || submitter.attr('href'))
}

function setFormMethod(form, submitter) {
  var new_method = submitter.attr('data-form-method');
  var confirm_del = submitter.attr('confirm-delete');
  if (confirm_del) {
    var answer = confirm("are you sure?");
    if (answer) {
      if (new_method) form.append('<input type="hidden" name="_method" value="' + new_method + '" />');
    }
    else {
      return false;
    }
  }
  else {
    if (new_method) form.append('<input type="hidden" name="_method" value="' + new_method + '" />');
  }

}

function setFormAjax(form, submitter) {
  if (submitter.attr('data-use-ajax')) {
    form.submit(function (event) {
      form.data('ajaxEventHandler', event.handler);
      $(this).ajaxSubmit({ dataType: 'script', success: function () {
        restoreForm(form)
      } });
      return false;
    });
  }
}

function checkDuplicates() {
  $('input[name="' + $(this).attr('name') + '"]').attr('checked', $(this).attr('checked'));
}

$.fn.highlight = function () {
  if ($(this).length > 0) {

    var colors = [
      '#FFFF99',
      '#FFFFAA',
      '#FFFFBB',
      '#FFFFCC',
      '#FFFFDD',
      '#FFFFEE',
      '#FFFFFF',
      'transparent'
    ]

    var elem = this;

    $.each(colors, function (i) {
      var color = this;

      setTimeout(function () {
        elem.css('background-color', color);
      }, 300 * i);
    });
  }
}


function updateOptions(submit_button, target, selectedOptions) {
  if (!$.browser.ie6)
    submit_button.attr('disabled', 'disabled');
  $.ajax({
    url: $('#' + target.attr('id') + '_url').val(),
    type: "GET",
    data: target.parents('form').formSerialize(),
    dataType: "html",
    success: function (options) {
      target.html(options);

      $(selectedOptions).each(function (idx, val) {
        target.find('option[value=' + val + ']').attr('selected', 'selected');
      });

      showCommonRequestEnvs(options);

      target.change();
      setPlanEnvDetails();
      if (!$.browser.ie6)
        submit_button.removeAttr('disabled');
    }
  });
}

function updateOptionsWithLimitedData(submit_button, target, selector, selectedOptions) {
  if (!$.browser.ie6)
    submit_button.attr('disabled', 'disabled');
  var url_str = $('#' + target.attr('id') + '_url').val();
  var sep = '?';
  if (url_str.indexOf(sep) != -1) {
    sep = '&';
  }
  var select = target.parents('form').find(selector);
  window.RPM.Helpers.Utils.doWithEnabled(select, this, function(){
    $.ajax({
      url: $('#' + target.attr('id') + '_url').val() + sep + target.parents('form').find(selector).serialize(),
      type: "GET",
      dataType: "html",
      success: function (data) {
        target.html(data);
        $(selectedOptions).each(function (idx, val) {
          target.find('option[value=' + val + ']').attr('selected', 'selected');
        });

        showCommonRequestEnvs(data);

        target.change();
        setPlanEnvDetails();
        if (!$.browser.ie6)
          submit_button.removeAttr('disabled');
      }
    });
  });
}

// Helper functions

function arrayMax(ary) {
  return Math.max.apply(Math, ary);
}

function setting_delay() {
  var i = 0;
  while (i <= 1000) {
    i++;
  }
}

function add_color_to_step_rows(step_list) {
  var classesForSteps = ['odd_step_phase', 'even_step_phase'];
  var counter = 0;
  step_list.find('tr:not(.procedure_step, .procedure_step_form, #first_step_row)').each(function () {
    var row = $(this);
    if (row.hasClass('different_level_from_previous')) {
      counter += 1;
    }
    row.addClass(classesForSteps[counter % 2]);
  });

  counter = 0;

  step_list.find('tr.procedure_step').each(function () {
    var row = $(this);
    if (row.hasClass('different_level_from_previous')) {
      counter += 1;
    }
    row.addClass(classesForSteps[counter % 2]);
  });
}

function updateforall_loaded_properties() {
  var step_related_object_type = $("#step_related_object_type") ? $("#step_related_object_type").val() : null;

  if (step_related_object_type && step_related_object_type !== null && step_related_object_type === "package") {
    $('#package_instance_id').change();
    return;
  }

  /*RF: This function only gets called on tab lazy loading,
   hence a globle varible disclare bellow which is used for conditioning in componet on change function*/
  step_tab_loading_flag = true;
  $('#step_component_id').change();
}

function updateStateTransition(transition_url, state, list_url) {
//	alert("Changing to " + id);
  $.ajax({
    url: transition_url,
    type: "GET",
    dataType: "html",
    success: function (data) {
      if (state == 'Draft' && list_url != "")
        window.location.assign(list_url);
      else
        $('#state_indicator').replaceWith(data);
    }
  });

}

function updateStateColumnTransition(transition_url, id, state,previous_state) {
  var str = "#state_list_" + id;
  var stat_str = "#td_state_" + id;
  var state_html = "<div id=\"td_state_" + id + "\">" + state + "</div>";
    $.ajax({
    url: transition_url,
    type: "GET",
    dataType: "html",
    success: function (data) {
      if (state == 'Archived' || state == 'Draft' || (state == 'Pending' && previous_state == 'Draft'))
        window.location.reload();
      else
        $(str).replaceWith(data);
      $(stat_str).replaceWith(state_html);
    }
  });

}
