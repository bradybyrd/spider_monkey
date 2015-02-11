$(function () {

    $('body.plan_routes').on('change', "#plan_route_route_app_id", function () {
        load_routes_for_app();
    });

});


function load_routes_for_app() {
    $("#plan_route_route_id").disable();
    if (($("#plan_route_route_app_id").length > 0) && ($("plan_route_route_app_id").val() != '')) {
        $.get(url_prefix + '/apps/route_options', {'app_id': $("#plan_route_route_app_id").val()}, function (options) {
            $("#plan_route_route_id").html(options);
        }, "text");
    } else {
        $("#plan_route_route_id").html("<option>...</option>");
    }
    $("#plan_route_route_id").enable();
}
