////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

$(function() {
  $('body').on('change', 'div.script_parameter_mapping input[type=radio]', toggleScriptParameterMappings);
  $('body').on('click', 'div.script_parameter_mapping input[type=radio]', toggleScriptParameterMappings);
  $('div.script_parameter_mapping').find('input[type=radio]').livequery(function() { $(this).change() });


  $('body').on('change', 'select.servers_for_script_parameters', scriptParameterMappingRemoteOptions);
  $('select.servers_for_script_parameters').livequery(function() { $(this).change() });

  $('body').on('change', 'select.get_mapped_values', getScriptArgumentValuesFromProperties);
  $('body').on('submit', 'form.map_script_parameters', reloadParameterMappingForm);
  $('form.basic_form').livequery(function(){
        $(this).pendingChanges();
   });

  function scriptParameterMappingRemoteOptions() {
    $.get($('#server_property_ids_url').val() + '?' + $(this).parents('form:first').serialize(), function(options) {
      $('#server_property_ids').html(options);
      var selected_ids = eval($('input[name=selected_property_ids]').val());
      if (selected_ids) {
        $.each(selected_ids, function(i) {
          $('#server_property_ids').find('option[value=' + selected_ids[i] + ']').attr('selected', true);
        });
      }
    }, "text");
  }

  function toggleScriptParameterMappings() {
    var inputs = $('div.script_parameter_mapping').find('input[type=radio]:checked');
    var source_value = inputs.filter('[name=mapping_source]').val();
    var type_value = inputs.filter('[name=mapping_type]').val();

    $('div.mapping_section').hide().find('input, select').attr('disabled', true);
    $('#' + source_value + '_' + type_value + '_mapping').show().find('input, select').removeAttr('disabled');
    $(this).parents('form:first').attr('action', $('#' + source_value + '_' + type_value + '_form_action').val());
  }

  function getScriptArgumentValuesFromProperties() {
    controller = $('#controller').val();
    $.get($('input[name=mapped_values_url]:not(:disabled)').val(), $(this).parents('form').formSerialize(), function(html) {
      $('#script_arguments').html(html);
    }).complete(function(){
      updateTargetArgumentId()
    });
  }

  function reloadParameterMappingForm() {
    var answer =  false
    var parsed_parameter = $('#parsed_parameter')
		var pending_script_changes = $("span#pending").html();
		if (pending_script_changes != ''){
			var answer = confirm("Changes made in the script section will also be saved, If you click Ok, If you click cancel changes made in script section will also persist ");
		}

    $(this).ajaxSubmit(function(html) {
      $.facebox.close();
      parsed_parameter.html(html);
      if (answer){
        $('#basic_form').ajaxSubmit({
          data: {'do_not_render' : true}          
        });
      }
    });

    return false;
  }

});

