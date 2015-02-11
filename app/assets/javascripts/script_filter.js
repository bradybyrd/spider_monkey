$(document).ready(function() {
		$('body').on('click', "#show_script_filter", function() {
       $.get(url_prefix + "/environment/toggle_script_filter", {"open_filter":true}, function(no_data){
       });
      $(this).replaceWith('<a href="#" class="filter_link" id="hide_script_filter">Close Filters</a>');
      $('#filterSection').show();
    });

    $('body').on('click', "#hide_script_filter", function() {
       $.get(url_prefix + "/environment/toggle_script_filter", {"open_filter":0}, function(no_data){
       });
      $(this).replaceWith('<a href="#" class="filter_link" id="show_script_filter">Open Filters</a>');
      $('#filterSection').hide();
    });

    $('body').on('click', 'a.clear_script_filters', function() { 
      var form = $("#filter_form");
      form.find('select').val('');
      $('input#clear_filter').attr('value', '1');
      submitFilterForm(form);
    });
});