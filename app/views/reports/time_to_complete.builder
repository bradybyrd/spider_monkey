    xml = Builder::XmlMarkup.new
    options = {:caption=>'Time To Complete Report', :xAxisName=>'Applications', :yAxisName=>'Time (In Minutes)', :useRoundEdges => '1', :showMinValue => '1', 
    :showMaxValue => '1', :exportHandler => 'fcExporter1', :exportEnabled => '1', :manageResize => '1', :exportAtClient => '1', :showMean => '1',
    :labelPadding => '30', :showMedianValue => '0', :meanIconAlpha =>'70', :meanIconColor => '#FFFFFF', :plotSpacePercent => '80'}
   
    xml.chart(options) do

      xml.categories do 
       @time_to_complete.each do |hash| 
          xml.category(:label=> hash[:app_name])
        end 
      end

      xml.dataset(:seriesName=>'Applications', :lowerBoxColor => '#76A9E1', :upperboxColor => '#76A9E1') do 
        @time_to_complete.each do |hash|
          xml.set(:value=> hash[:completion_time].map(&:ceil).join(", "), :link => hash[:request_url]) 
        end
      end
    end  
      
     
      