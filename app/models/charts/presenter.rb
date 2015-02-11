################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module Charts
  class Presenter
    def initialize(options)
      @options = options.dup
    end

    def component_property_data?
      options[:data_type] == 'component_properties'
    end

    def server_property_data?
      options[:data_type] == 'server_properties'
    end

    def chart
      case options[:chart_type]
      when nil, 'hbar'

        #openflashcharts has been removed, raising error if called
        raise "Replace with AM chart."
      #Charts::BarChart.new(data, name)
      when 'pie'
        #openflashcharts has been removed, raising error if called
        raise "Replace with AM chart."
      #Charts::PieChart.new(data, name)
      when 'trend'
        #openflashcharts has been removed, raising error if called
        raise "Replace with AM chart."
      #Charts::TrendChart.new(data, name)
      end
    end

    private

    attr_reader :options

    def data
      data_collector.data
    end

    def name
      data_collector.name
    end

    def data_collector
      return @data_collector if @data_collector

      if component_property_data?
        @data_collector = Charts::ComponentPropertyDataCollector.new(options)
      elsif server_property_data?
        @data_collector = Charts::ServerPropertyDataCollector.new(options)
      else
        @data_collector = Charts::PlanDataCollector.new(options)
      end

      @data_collector
    end

  end
end
