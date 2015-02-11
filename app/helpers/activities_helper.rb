################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module ActivitiesHelper
  include ActivityHealthImage

  def custom_value_name obj
    if obj.respond_to?(:name_for_index)
      obj.name_for_index
    elsif obj.respond_to?(:name)
      obj.name
    else
      obj
    end
  end

  def custom_value_id obj
    obj.is_a?(ActiveRecord::Base) ? obj.id : obj
  end

  def currency_column_contents value
    content_tag(:div, '$' + content_tag(:div, group_digits(value), :class => 'right'), :class => 'currency')
  end

  def activity_column_value activity, col
    value = activity.send(col.activity_attribute_method)
    if col.health?
      activity_health_image(value)
    elsif col.currency?
      ensure_space(value.present? && currency_column_contents(value))
    elsif col.date?
      value.try(:to_s, :simple)
    elsif col.boolean? || col.activity_attribute_column == 'cio_list'
      value ? "Yes" : "No"
    else
      h truncate(value.to_s, :length => 50)
    end
  end

  def activity_attribute_field_name(attr, field_name="activity")
    if attr.static?
      name = "#{field_name}[#{attr.field}]"
    else
      name = "#{field_name}[custom_attrs][#{attr.id}]"
    end
    name << '[]' if attr.multi_select?
    name
  end

  def activity_options_for_select activity, activity_category, attr

    selected_values = if activity.is_a? ActivityDeliverable
      activity.custom_attrs_array
    elsif activity.is_a? Activity
      if attr.field.eql?('manager_id')
        [activity.manager_id]
      else
        Array(attr.value_for(activity)).map { |v| custom_value_id v }
      end
    end rescue []

    option_values_arr = if attr.field.eql?('manager_id')
      User.all
    elsif attr.field.eql?('status')
      list = List.find(:first, :conditions => { :name => 'ValidStatuses' })
      if list.is_text
        list.list_items.unarchived.map(&:value_text).compact
      else
        list.list_items.unarchived.map(&:value_num).compact
      end
      # List.get_list_items("ValidStatuses")
    else
      attr.default_values_for(activity_category)
    end

    option_values = (option_values_arr || []).map { |v| [custom_value_name(v), custom_value_id(v)] }.sort

    if attr.attribute_values[0] == 'Container'
      temp = []
      option_values.each do |val|
        temp << val if val[0] != 'Unassigned'
      end
      option_values = temp
    end

    options_for_select(option_values, selected_values)
  end

  def display_activity_attribute_field activity, attr, activity_category, disabled, field_name="activity", form
    fld_value = attr.pretty_value_for(activity)
    fld_value = (fld_value.nil? ? '' : fld_value)
    render :partial => "activities/fields/#{attr.input_type}",
           :locals => { :field_name => activity_attribute_field_name(attr, field_name),
                        :field_value => fld_value,
                        :attr => attr, :activity => activity, :activity_category => activity_category,
                        :disabled => disabled,
                        :f => form }
  end

  def date_field_tag(field_name, field_value = '', html_options = {}, image_float='float:left;')
    classes = html_options.delete(:class) || ''
    classes << ' date'
    unless field_value.blank?
      default_format_date = GlobalSettings[:default_date_format].split(' ')
      if default_format_date.eql?(["%d/%m/%Y", "%I:%M", "%p"]) && field_value.to_s.include?('/')
        field_value_components = field_value.split('/')
        field_value = field_value_components[1]+'/'+field_value_components[0]+'/'+field_value_components[2]
      end
      field_value = field_value.to_date.strftime(default_format_date[0])
    end

    inner_contents = text_field_tag(field_name, field_value, html_options.merge(:class => classes)) << image_tag('calendar_add.png', :style => image_float)

    content_tag(:label, inner_contents, :class => 'calendar')
  end

  def activity_health_image(health)
    image_tag activity_health_icon(health), :alt => health
  end

  def activity_tab tab, selected_id, activity
    classes = []
    classes << 'selected' if tab.id == selected_id
    classes << 'right_align' if tab.right_align?
    if current_user.present?
      content_tag(:li,
        link_to(h(tab.name), edit_activity_tab_path(activity, tab.id)),
      :class => classes.join(' '))
    else
      content_tag(:li,
        link_to(h(tab.name), show_read_only_activity_tab_path(activity, tab.id)),
      :class => classes.join(' '))
    end
  end

  def b thing
    case thing
    when "true"
      image_tag('check_transparent.png', :alt => '&radic;')
    when "false"
      "&nbsp;"
    else
      thing
    end
  end

  def to_currency snum
    snum.blank? ? '' : '$' + group_digits(snum)
  end

  def group_digits snum
    snum = 0.0 if snum.nil?
    snum = snum.to_i if snum.class == String
    numtrim = snum.round.to_s.gsub(/[\$,]/,'').gsub(/\.0/,'')
    numtrim.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\0,')
  end

  def activity_status_options
    [["[None]", ""]] +
      Activity::ValidStatuses.map { |s| [s, s] }
  end

  def activity_requests(activity)
    requests = activity.requests
    requests = requests.in_assigned_apps_of(current_user) if can? :restrict_to_current_user, Request.new
    requests = requests.functional
  end

  def widget_requests(activity)
    activity.requests.functional.includes(:apps).select { |r| r.is_visible?(current_user) }
  end
end
