xml.row( :class => "id_row", :style=> "font-size:11px;font-weight:bold;white-space:normal;background-color:#E2E2E2;") do
  xml.cell "<span class='active_id'>ID</span"
  grid_columns.each do |column|
    xml.cell column.filter_label
  end
  xml.cell "Year-end Forecast"
end
(@activities[group_id.to_i] || []).each do |activity|
  xml.row(:style=> "font-size:11.5px;", :id => "#{activity.id}") do
    xml.cell content_tag(:div, link_to(activity.id, show_read_only_activity_path(activity)), :class => "id_activity td_underline")
    @activities_grid_columns.each do |col|
      if col.activity_attribute_column == 'name'
        xml.cell content_tag(:strong, is_web(activity_column_value(activity, col)), :title => activity_column_value(activity, col))
      else
        activity_columns = activity_column_value(activity, col)
        column_value = activity_columns.present? ? activity_columns : "&nbsp;".html_safe
        if col.health?
          xml.cell content_tag(:span, column_value)
        else
          xml.cell content_tag(:span, column_value, :title => activity_column_value(activity, col))
        end  
      end
    end
    xml.cell activity_yef_column_data(activity) 
    if current_user.admin?
      xml.cell link_to image_tag('bin_empty.png', :alt => 'Destroy'), '#', :onclick => "destroy_activity(#{activity.id}, #{group_id}); return false", :style => "border:none;"
    else
      xml.cell '&nbsp;'
    end
  end
end