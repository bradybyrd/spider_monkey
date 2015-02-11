    xml = Builder::XmlMarkup.new
    options = {:caption=>'Volume Report', :xAxisName=>'Applications', :yAxisName=>'Requests', :showValues=> '0', :showToolTip => '1', :yAxisMaxValue => '5',
     :useRoundEdges =>'1', :palette => '3', :showBorder => '1', :showPlotBorder => '1', :exportHandler => 'fcExporter1', :exportEnabled => '1', :manageResize => "1", :exportAtClient => '1'}
    xml.chart(options) do

      xml.categories do 
        @volume_report.each do |hash| 
          xml.category(:label=> hash["Applications"])
        end 
      end

      xml.dataset(:seriesName=>'Completed', :color => '#76A9E1') do 
        @volume_report.each do |hash|
          xml.set(:value=> hash["Completed"], :link => hash["Completed_request_url"], :tooltext => "#{hash['Completed']} Requests {br}completed for #{hash['Applications']}") 
        end  
      end

      xml.dataset(:seriesName=>'Problem', :color => '#C5725F') do 
        @volume_report.each do |hash|
          xml.set(:value=> hash["Problem"], :link => hash["Problem_request_url"], :tooltext => "#{hash['Problem']} Requests {br}in Problem state {br} for #{hash['Applications']}") 
        end  
      end

      xml.dataset(:seriesName=>'Hold', :color => '#CF6347') do 
        @volume_report.each do |hash|
          xml.set(:value=> hash["Hold"], :link => hash["Hold_request_url"], :tooltext => "#{hash['Hold']} Requests on Hold for {br} #{hash['Applications']}") 
        end  
      end

      xml.dataset(:seriesName=>'Cancelled', :color => '#DE4C20') do 
        @volume_report.each do |hash|
          xml.set(:value=> hash["Cancelled"], :link => hash["Cancelled_request_url"], :tooltext => "#{hash['Cancelled']} Requests {br}in Cancelled state for #{hash['Applications']}") 
        end  
      end 
    end