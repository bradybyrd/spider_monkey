xml.instruct!
xml.rows do
  @groups.sort_by(&:name).each_with_index do |group, index|
    activities_count = (@activities[group.id] || []).count
    if activities_count > 0
      xml.row(:class => 'index', :style=> "font-weight:bold;", :xmlkids => "1", :id => "group_#{group.id}") do
        xml.tag!(:cell,{:colspan=>2}, 
                  content_tag(:span, group.name, :id => "g_#{group.id}"), 
                  content_tag(:span, ("(#{activities_count})"), :id => "span_activity_count_#{group.id}",
                              :style => "color:#999999;font-size:12px;font-weight:normal;"))
        if @expand_all
          xml << render(:partial => "activities/data_grid/activities", :locals => {
                        :group_id => group.id,
                      })
        end                        
      end    
    end
  end
end