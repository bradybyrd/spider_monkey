    legend_caption = (@selected_options.present? && @selected_options["group_on"].present?) ? @selected_options["group_on"] : "Part of" 
    cummulative_count = 0
    xml = Builder::XmlMarkup.new
    options = {:caption=>'Problem Trend Report', :xAxisName=> "#{filter_x_axis(@selected_options, "precision")}", :yAxisName=>'Number of requests in problem state', :showValues=> '0', :yAxisMaxValue => '5',
      :showToolTip => '1', :showToolTipShadow => '1', :useRoundEdges =>'1', :exportHandler => 'fcExporter1', :exportEnabled => '1', :manageResize => "1", :exportAtClient => '1', :anchorAlpha=> "100",:showAreaBorder=> "0", :numVisiblePlot=>'6', :showLegend => "1", :legendCaption => legend_caption.capitalize }
    xml.chart(options) do
      xml.categories do 
        (@problem_trend_report.first["request_count"]|| []).each do |month| 
          xml.category(:label=> month.keys.first)
        end 
      end
      work_task_count = 0      
      (@problem_trend_report || []).map{|problem| work_task_count += 1 if problem["request_count"].present? && problem["request_count"].any?{|rq| rq.values.first != 0}}
      i = 12
      cummulative_count = []
      (@problem_trend_report || []).each_with_index do |problem, outer_index|
        if problem["request_count"].present? && problem["request_count"].any?{|rq| rq.values.first != 0}
          radius = i - 12/work_task_count
          xml.dataset(:seriesName=>"#{problem['category']}", :anchorRadius=> i, :showPlotBorder => 1 , :plotBorderAlpha => "100", :alpha => "10") do
            (problem["request_count"]|| []).each_with_index do |count, inner_index|
             cummulative_count[inner_index] = count.values.first + (cummulative_count[inner_index] || 0)
             xml.set(:value=> cummulative_count[inner_index], :link => count['request_link'], :tooltext => "#{problem['category']}, #{count.keys.first}, #{count.values.first}") 
           end
          end
          i = i - 12/work_task_count
        end
      end
    end