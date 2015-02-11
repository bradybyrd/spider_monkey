xml = Builder::XmlMarkup.new
options = {:caption => 'Time of Problem Report', :useRoundEdges => '1', :showQ1Values => '1', :xAxisName=> "#{filter_x_axis(@selected_options, "group_on")}",
 :showQ3Values => '1', :exportHandler => 'fcExporter1', :exportEnabled => '1', :manageResize => "1", :exportAtClient => '1', :yAxisName=>'Time (In Minutes)',
 :showMean => '1', :labelPadding => '30', :showMedianValue => '0', :meanIconAlpha =>'70', :meanIconColor => '#FFFFFF', :plotSpacePercent => '80'}
 
xml.chart(options) do

  xml.categories do 
    @time_of_problem.each do |hash| 
      xml.category(:label=> hash[:obj_name])
    end 
  end

  xml.dataset(:seriesName=>'Requests', :lowerBoxColor => 'C5725F', :upperboxColor => 'C5725F') do 
    @time_of_problem.each do |hash|
      xml.set(:value=> hash[:problem_time].map(&:ceil).join(", "), :link => hash[:request_url]) 
    end  
  end

end