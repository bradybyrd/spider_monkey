################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module Charts
  class BarChart
    def initialize(data, name = nil)
      
      #openflashcharts has been removed, raising error if called
      raise "Replace with AM chart."
      
      # name ||= "chart title"
# 
      # # @chart = OpenFlashChart::OpenFlashChart.new(name) do |c|
      # end
# 
      # unless data.empty?
        # @data = data
# 
        # @chart.set_y_axis(y_axis)
        # @chart.set_x_axis(x_axis)
        # @chart.add_element(chart_element)
      # end
    end

    def to_s
      @chart.to_s
    end

  private

    attr_reader :data

    def y_axis
      raise "Replace with AM chart"
      #y = OpenFlashChart::YAxis.new
      # y.set_offset(1)
      # y.set_labels data.labels
      # y
    end

    def x_axis
      raise "Replace with AM chart"
      #x = OpenFlashChart::XAxis.new
      # x.set_offset(false)
# 
      # stepping = data.max_value / 10
      # stepping = 1 if stepping == 0
# 
      # x.steps = stepping
      # x
    end

    def chart_element
      raise "Replace with AM chart"
      #element = OpenFlashChart::HBar.new
      # data.each_value do |value|
        # bar_val = OpenFlashChart::HBarValue.new(0, value)
        # bar_val.on_click = "drilldown(#{value})"
        # element.append_value(bar_val)
      # end
      # element
    end
  end
end
