// This file is the property of StreamStep, Inc.
// The contents of this file are covered by Copyright by StreamStep, Inc.
// Any unauthorized and unlicensed use is strictly prohibited.
// The software source code can be used only with a valid software license from StreamStep, Inc.
// In NO WAY is this software open source, free, or in the public domain.

$(document).ready(function() {
  $('.step_phase a.expand_procedure').livequery( function() { $(this).expandProcedure();});
  $('.step_phase a.collapse_procedure').livequery( function() { $(this).collapseProcedure();});

  $('input.delete_procedure').livequery( function() { $(this).deleteProcedure();});
});

$.fn.extend({
  expandProcedure: function() {
    this.click(function() {
      link = $(this);

      max_class_number = arrayMax(usedComponentColorClassNumbers('.step'))

      $.get(link.attr('href'), { start_number: max_class_number + 1 }, function(html) {
        var old_div = link.parents('div:first').replaceWith(html);
        var id = old_div.attr('id');
        old_div.removeAttr('id');

        var new_div = $('#' + id);
        new_div.addClass(old_div.attr('class').match(/component_color_\d+/)[0]);
      });

      return false;
    });
  },

  collapseProcedure: function() {
    this.click(function() {
      link = $(this);

      $.get(link.attr('href'), function(html) {
        var old_div = link.parents('div:first').replaceWith(html);
        var id = old_div.attr('id');
        old_div.removeAttr('id');

        var new_div = $('#' + id);

        bad_class = new_div.attr('class').match(/component_color_\d+/);
        if (bad_class)
          new_div.removeClass(bad_class);

        new_div.addClass(old_div.attr('class').match(/component_color_\d+/)[0]);
      });

      return false;
    });
  },

  deleteProcedure: function() {
    this.click(function() {
      delete_icon = $(this)
      form = delete_icon.parent();

      form.ajaxSubmit(function() {
        procedure = delete_icon.parents('div.step:first');
        removeDropGroupIfEmpty(procedure, 'step');
        procedure.remove();
      });

      return false;
    });
  }

});
