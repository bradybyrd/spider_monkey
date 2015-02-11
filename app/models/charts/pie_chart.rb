################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module Charts
  class PieChart
    def initialize(data, name = "chart title")
            
      #openflashcharts has been removed, raising error if called
      raise "Replace with AM chart."
#       
      # @data = data
#       
      # @chart = OpenFlashChart::OpenFlashChart.new(name) do |c|
      # end
#       
      # @chart.add_element(chart_element)
    end
    
    def to_s
      @chart.to_s
    end
    
  private

    attr_reader :data

    def chart_element
            
      #openflashcharts has been removed, raising error if called
      raise "Replace with AM chart."
#       
      # element = OpenFlashChart::Pie.new
      # data.each do |datum|
        # pie_val = OpenFlashChart::PieValue.new(datum.value, datum.label)
        # pie_val.on_click = "drilldown(#{datum.value})"
        # element.append_value(pie_val)
      # end
      # element
    end
  end
end
