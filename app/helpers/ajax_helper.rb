################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module AjaxHelper
  def select_current_tab(current_tab_object)
    %Q(
      $('.server_tabs li.selected').removeClass('selected');
      #{current_tab_object}.addClass('selected');
    ).html_safe
  end

  def tab_for_server_level(server_level)
    "$('.server_tabs li').filter(function() { return $(this).find('a').html() == '#{server_level.name}' })".html_safe
  end

  def server_level_groups_tab
    "$('.server_tabs #server_aspect_groups_tab')".html_safe
  end

  def click_server_tab(tab_object)
    "#{tab_object}.find('a').click();".html_safe
  end

  def set_server_level_actions(server_level)
    "$('.content .pageFunctions').html(\"#{escape_javascript(render(:partial => 'server_levels/actions', :locals => { :server_level => server_level }))}\");"
  end

  def set_document_title(title)
    "document.title = '#{title}';".html_safe
  end

  def load_partial_into_server_window(partial)
    "$('#server_container').html(\"#{escape_javascript(render(:partial => partial))}\");".html_safe
  end

  def load_partial_into_facebox(partial)
    "$('#facebox form').parent().html(\"#{escape_javascript(render(:partial => partial))}\");".html_safe
  end

  def set_cancel_link_for_server_level(server_level)
    set_cancel_link_to_server_tab tab_for_server_level(server_level)
  end

  def set_cancel_link_to_server_tab(server_tab)
    %Q(
      $('a.server_cancel').click(function() {
        #{click_server_tab server_tab};
        return false;
      });
    ).html_safe
  end

  def server_level_after_create_actions(server_level)
    %Q(
      #{close_facebox}
      #{server_level_after_save_actions server_level}
    ).html_safe
  end

  def server_level_after_save_actions(server_level)
    %Q(
      $('.server_tabs').html(\"#{escape_javascript(render(:partial => 'servers/tabs', :locals => { :selected => '' }))}\").find('li.selected').removeClass('selected');
      $.getScript(\"#{server_level_path(server_level)}\", function(data, textStatus) {
        $("#server_level_groups").addClass('selected');
         tablesorterTableHeaderArrowAssignment();
      });
    ).html_safe
  end

  def server_aspect_after_save_actions(server_level, page, key)
    %Q(
      $('.server_tabs').html(\"#{escape_javascript(render(:partial => 'servers/tabs', :locals => { :selected => '' }))}\").find('li.selected').removeClass('selected');
      $.getScript(\"#{server_level_path(server_level, :page => page, :key => key)}\", function(data, textStatus) {
        $("#server_level_groups").addClass('selected');
            tablesorterTableHeaderArrowAssignment();
      });
    ).html_safe
  end

  def close_facebox
    "$.facebox.close();"
  end

  def image_tag_wait
    content_tag(:div, image_tag("waiting.gif", :alt => "Please wait.."), :id => "wait")
  end

  def facebox_tag
    %Q{<div class='facebox_hide facebox_overlayBG' id='facebox_overlay' style='display: none; opacity: 0;'>
        &nbsp;
      </div>
    }.html_safe
  end

  def select_clear_links(select_id, options={})
    links = select_all_link(select_id, options) + " | " + clear_list_link(select_id, options)
  end

  def clear_list_link(select_id, options)
    js_routine = "$('##{select_id}').val('');"
    js_routine += "#{options[:eval]}" if options[:eval].present?
    link_to_function "Clear", js_routine, :class => "clear_list"
  end

  def select_all_link(select_id, options)
    #js_routine = "$('##{select_id} option').each(function(i) {  $(this).attr('selected', 'selected');});"
    js_routine = "$('##{select_id} option').each(function(i) {  $(this).removeClass('clicked'); $(this).removeClass('unclicked');  $(this).attr('selected', 'selected');});"
    js_routine += "#{options[:env]}" if options[:env].present?
    link_to_function "Select All", js_routine, :class => "select_all"
  end

  def select_clear_chk(select_id, options={})
    select_all_chk(select_id, options) + " | " + clear_list_chk(select_id, options)
  end

  def clear_list_chk(select_id, options)
    js_routine = "$('##{select_id} input').attr('checked', false);"
    js_routine += "#{options[:eval]}" if options[:eval].present?
    link_to_function "Clear", js_routine, :class => "clear_list"
  end

  def select_all_chk(select_id, options)
    js_routine = "$('##{select_id}').each(function(i) {$('##{select_id} input').attr('checked', true);});"
    js_routine += "#{options[:env]}" if options[:env].present?
    link_to_function "Select All", js_routine, :class => "select_all"
  end

  def toggel_inbound_outbound_section_links(hide = true)
    if hide
      "$('#inbound_outbound_request_links').hide();".html_safe
    else
      "$('#inbound_outbound_request_links').show();".html_safe
    end
  end
end

