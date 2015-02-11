xml.instruct!
xml.rows do
  @groups.each do |group|
    xml.row(:parent => group.id) do 
      xml.cell group.name
      activities = Activity.fetch_by_group(@activity_category.id, group.id, current_user.admin? ? true : false, @activity_ids)
      columns = @activity_category.index_columns
      activities.each do |activity|
        xml.row do
          xml.cell activity.id
          columns.each do |col|
            if col.health?
              xml.cell "/images/#{activity_health_icon(activity.send(col.activity_attribute_method))}"
            else
              xml.cell activity_column_value(activity, col)
            end
          end
          xml.cell " "
          if current_user.present? && current_user.can_edit_activity?(activity)
            xml.cell link_to "edit", edit_activity_path(activity)
          else
            xml.cell link_to "detail", show_read_only_activity_path(activity)
          end
          if current_user.present? && current_user.admin?
           xml.cell link_to image_tag("bin_empty.png", :alt => "delete"), activity_path(activity), :method => :delete, :confirm => "Are you sure?"
          end
        end
      end
    end
  end
end

