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
    fld_value = [] if fld_value == '' && ['select', 'multi_select'].include?(attr.input_type)
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
  
  def link_to_clear_activity_filters(text="clear")
    link_to text, activities_path(:activity_category_id => @activity_category.id, 
      :clear_filters => true, "expandAll" => params[:expandAll])
  end
  def add_bli_for_year(activity, budget_year) # TODO - Need serious refactoring :(
    return link_to_add_bli_for(activity) if current_user.is_fm?
    return unless current_user.is_pm?
    @forecasting_enabled = SystemSetting.forecasting_enabled? unless @forecasting_enabled
    @current_b_year = SystemSetting[:budget_year].try(:to_i) unless @current_b_year
    budget_year = budget_year.to_i    
    if @forecasting_enabled && [@current_b_year, @current_b_year.next].include?(budget_year)
      link_to_add_bli_for(activity)
    elsif @current_b_year == budget_year
      link_to_add_bli_for(activity)
    end
  end
  
  def link_to_add_bli_for(activity, text="add")
    if current_user.cannot_add_edit_closed_bli? && activity.is_closed?
      "&nbsp;".html_safe
    else
      link_to_function text, "addBli('#{activity.id}', $(this))" if current_user.financial_manager? 
    end
  end
  
  def grid_columns
    @activities_grid_columns ||= @activity_category.index_columns
  end
  
  def grid_column_names
    @activities_grid_column_names = ["ID"] << grid_columns.map(&:filter_label) << ["Year-end Forecast", "&nbsp;".html_safe]
    Rails.logger.info "Grid COlumnNames: #{@activity_grid_column_names.inspect}"
    @activities_grid_column_names.flatten!
  end
  
  def grid_column_alignments
    health_column_index = grid_column_names.index("Health")
    @activities_grid_column_alignments = Array.new(grid_column_names.size, "left")
    @activities_grid_column_alignments[health_column_index] = "center" 
    @activities_grid_column_alignments
  end
  
  def grid_column_sorting
    @activities_grid_column_sorting = Array.new(@activities_grid_column_names.size, "na") << ["na", "na"]
    @activities_grid_column_sorting.flatten!
  end
  
  def grid_column_types
    @activities_grid_column_types = ["tree"] << Array.new(@activities_grid_column_names.size - 2, "ro") << ["ro", "ro"]
    @activities_grid_column_types.flatten!
  end
  
  def grid_column_widths
    @all_grid_columns = ["id"] << grid_columns.map(&:activity_attribute_column) << ["year_end_forecast"]
    @all_grid_columns.flatten!
    widths = []
    @all_grid_columns.each do |column|
      widths << column_widths(column)
    end 
    widths 
  end
  
   def column_widths(column_name)
    { "id" => 80, 
      "name" => 200, 
      "budget_category" => 75, 
      "manager_id" => 200, 
      "current_phase_id" => 160,
      "service_description" => 150, 
      "status" => 100, 
      "goal" => 200, 
      "problem_opportunity" => 200,  
      "estimated_start_for_spend" => 96,
      "health" => 82,      
      "parent_ids" => 84, 
      "budget" => 105, 
      "projected_finish_at" => 96, 
      "theme" => 104, 
      "cio_list" => 90, 
      "blockers" => 90,
      "projected_cost" => 85,
      "year_end_forecast" => 140,
       nil => 100 
    }[column_name]
  end

  def b thing
    case thing
    when "true"
      image_tag('check_transparent.png', :alt => '&radic;')
    when "false"
      "&nbsp;".html_safe
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
  
  def filter_select_options(column)
    filter_name = ActivityAttribute.find(column.activity_attribute_id).name if column.activity_attribute_id.present?
    column_name = column.activity_attribute_column if column.activity_attribute_column.present?
    return [["Yes", "true"], ["No", "false"]]  if filter_name == "Group High-priority"
    return customize_filter_ordering(column) if column.activity_attribute_column.present? && ( column_name == "status" || column_name == "theme" || column_name == "manager_id" ) 
    @activity_category.filter_options(column).collect{|opt| 
      if column.custom_attribute_column?
        [opt, opt]  
      else
        if Activity.column_datetime?(column.activity_attribute_column)
          opt.human_value.try(:to_datetime).try(:in_time_zone).try(:default_format_date)
        else
          [opt.human_value.titleize, opt.value]             
        end
      end 
    }
  end
  
  def activity_yef_column_data(activity)
    yef = 0 #group_digits activity.bli_totals.of_year(SystemSetting[:budget_year]).sum(:yef)
    yef.to_i > 0 ? "$#{number_with_delimiter(yef)}" : "0"
  end
end
