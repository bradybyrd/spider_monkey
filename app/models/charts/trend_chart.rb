################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module Charts
  class TrendChart
    def initialize(data_hash, name = nil)
      
            
      #openflashcharts has been removed, raising error if called
      raise "Replace with AM chart."
      
      # name ||= "chart title"
      # @data = data_hash
# 
      # @chart = OpenFlashChart::OpenFlashChart.new(name)
# 
      # @chart.set_y_axis(y_axis)
      # @chart.set_x_axis(x_axis)
      # @chart.add_element(chart_element)
    end

    def to_s
      @chart.to_s
    end

    private
    def y_axis
            
      #openflashcharts has been removed, raising error if called
      raise "Replace with AM chart."
      #OpenFlashChart::YAxis.new
    end

    def x_axis
            
      #openflashcharts has been removed, raising error if called
      raise "Replace with AM chart."
      #OpenFlashChart::XAxis.new
    end

    def chart_element
            
      #openflashcharts has been removed, raising error if called
      raise "Replace with AM chart."
      
      # element = OpenFlashChart::Line.new
      # @data.each do |data|
        # v = OpenFlashChart::DotValue.new(data['value'], "#000000")
        # element.append_value(v)
      # end
      # element
    end
  end
end
