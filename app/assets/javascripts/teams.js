////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

$(function () {

    $('select.roleInAppList').live('change', function () {
        if ($(this).val() == 'not_visible') {
            alert($('.button').data('confirmation'));
        }
    });

    $('.teamUserRoles li').click(function () {
        clickedLi = $(this);
        if (loadApplicationRoleList(clickedLi)) {
            clickedLi.parent().children().each(function (index) {
                if ($(this).attr('tab') == clickedLi.attr('tab')) {
                    $(this).addClass('selected');
                    $("#" + $(this).attr('tab')).show();
                }
                else {
                    $(this).removeClass('selected');
                    $("#" + $(this).attr('tab')).hide();
                }
            });
        }
        else {
            alert("Please select both applications and users of the team before you edit roles for the team");
        }
        return false;
    });

    $("#team_user_selection").val('Group');
});

function selectedAppIds() {
    var app_ids = [];
    $(".team_app_ids").map(function () {
        if ($(this).is(':checked')) {
            app_ids.push($(this).val());
            return $(this);
        }
    });
    return app_ids;
}

// Used to check if user selected both Apps and Users. Returns true or false
function loadApplicationRoleList(clickedLi) {
    if (clickedLi.attr("tab") == "team_roles") {
        var splitted_array = $("#team_form").attr("action").split("/")
        var team_id = splitted_array[splitted_array.length - 1]

        $(".table_of_apps_users").html("<h3> Applications: Assign User to Roles</h3><p></p>");
        $.get($("#team_form").attr("action") + "/app_user_list", {"render_only_app_name": '1' }, function (partial) {
            $(".table_of_apps_users").append(partial);
        });
        $("#team_roles").show();
        return true;
    } else {
        return true;
    }
}

function disableInvisibleEnv() {
    $('.user_role_list_by_app').find('td').each(function (index) {
        if ($(this).attr("id") != '') {
            if ($("div." + $(this).attr("id")).length > 0) {
                $(this).find('select').val('').attr('disabled', true);
            }
        }
    });
}

function insertDivforList(divId) {
    if ($("#p_" + divId).length == 0) {
        $('#user_list_of_groups').append("<div id='p_" + divId + "'></div>");
    }
    $('#user_list_of_groups').find("div").hide();
    $("#p_" + divId).show();
    $("#paginateLinks_" + divId).show();
}
