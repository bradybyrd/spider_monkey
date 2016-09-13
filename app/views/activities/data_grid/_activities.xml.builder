if @expand_all
  xml << render(:partial => "activities/data_grid/rows", :locals => {:group_id => group_id})  
else
  xml.rows(:parent => "group_#{@group_id}") do
    xml << render(:partial => "activities/data_grid/rows", :locals => {:group_id => @group_id.to_i})  
  end
end  