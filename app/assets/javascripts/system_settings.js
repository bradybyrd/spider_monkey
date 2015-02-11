////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

$(document).ready(function() {
    var page_changed = false;

    $('body').on('change', 'form.no_submit input, form.no_submit select', function() {
        var input = $(this)
        input.hide().spin();
        input.parents('form:first').ajaxSubmit(function() {
            input.next().remove();
            input.show();
        });
    });

  $('form.settingsform').submit(function() {
      window.onbeforeunload = null;
  });

  $('body').on('change', 'form.settingsform input:radio, form.settingsform select', function() {
    page_changed = true;
    var rel = $(this).attr("rel");
    if (rel != 'company_name') {
        var input = $(this)
        if (input.attr("id") == "GlobalSettings_authentication_mode_1")
        {
            ldap_settings_enabled(true)
            cas_settings_enabled(false)
            default_settings_enabled(false)
        }
        if (input.attr("id") == "GlobalSettings_authentication_mode_2")
        {
            ldap_settings_enabled(false)
            cas_settings_enabled(true)
            default_settings_enabled(false)
        }
        if (input.attr("id") == "GlobalSettings_authentication_mode_0")
        {
            ldap_settings_enabled(false)
            cas_settings_enabled(false)
            default_settings_enabled(true)
        }
    }
	});

    $('body').on('change', 'form.settingsform input:checkbox', function() {
        page_changed = true;
    });

    $('body').on('keyup', 'form.settingsform input:text', function() {
        page_changed = true;
        var rel = $(this).attr("rel");
        if (rel != 'company_name') {
            $(this).next("span").html("<a style='cursor:pointer;' onclick='settings_text_field($(this))'>update</a>");
        }
    });

    $('body').on('change', 'form.settingsform input:radio[name^="GlobalSettings[ldap_auth_type]"]', function(e) {
        var radioInput = e.target || e.srcElement;
        var bindBaseInput = $('form.settingsform input:text[id="GlobalSettings_ldap_bind_base"]')[0];
        if(radioInput && (parseInt(radioInput.value) == 0)){
            bindBaseInput.disabled = true;
        } else {
            bindBaseInput.disabled = false;
        }
    });


    window.onbeforeunload = function() { 
        if (page_changed) {
            return 'You have made changes on this page that you have not yet confirmed.\nIf you navigate away from this page you will loose your unsaved changes';
        }
    }
});

function ldap_settings_enabled(status)
{
    $('form.settingsform input:text[id="GlobalSettings_ldap_host"]')[0].disabled = !status
    $('form.settingsform input:text[id="GlobalSettings_ldap_port"]')[0].disabled = !status
    $('form.settingsform input:radio[name^="GlobalSettings[ldap_auth_type]"]').each(function(ind, input){
        input.disabled = !status
    })
    $('form.settingsform input:text[id="GlobalSettings_ldap_component"]')[0].disabled = !status
    $('form.settingsform input:text[id="GlobalSettings_ldap_bind_base"]')[0].disabled = !status
    $('form.settingsform input:text[id="GlobalSettings_ldap_bind_user"]')[0].disabled = !status
    $('form.settingsform input:password[id="GlobalSettings_ldap_bind_password"]')[0].disabled = !status
    $('form.settingsform input:text[id="GlobalSettings_ldap_account_attribute"]')[0].disabled = !status
    $('form.settingsform input:text[id="GlobalSettings_ldap_first_name_attribute"]')[0].disabled = !status
    $('form.settingsform input:text[id="GlobalSettings_ldap_last_name_attribute"]')[0].disabled = !status
    $('form.settingsform input:text[id="GlobalSettings_ldap_mail_attribute"]')[0].disabled = !status
}

function cas_settings_enabled(status)
{
    $('form.settingsform input:text[id="cas_server_p_id"]')[0].disabled = !status
}

function default_settings_enabled(status)
{
    $('form.settingsform input:checkbox[id="GlobalSettings_forgot_password"]')[0].disabled = !status
}

function settings_text_field(link){
  link.hide().spin();
  link.parents('form:first').ajaxSubmit(function(){
	  link.next().remove();
    link.show();
	  link.hide().next("span");
    var input_field = link.parents("span").prev();
    if (input_field && input_field.attr("reload_window_on_update") == 'true'){
      window.location.reload();
    }
	});
  return false;
}

