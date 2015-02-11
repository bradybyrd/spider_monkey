$(function() {
    $('body').on('change', 'select#component_id', function() {
        $.ajax({
            url: $('#app_env_pick_list_url').attr("value") + '?app_id=' + $('select#app_id').val() + '&component_id=' + $(this).val(),
            type: "GET",
            success: function(data) {
                $('#app_env_pick_list').html(data);
            }
        });
    });
});
