################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class FusionChart < ActiveRecord::Base

  def self.columns
    @columns ||= []
  end

  def self.column(name, sql_type = nil, default = nil, null = true)
    columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
  end

  attr_accessor :period, :filters, :start_date, :end_date

  Types = %w(volume-report problem-trend-report time-of-problem completed-report time-to-complete release-calendar environment-calendar events-calendar)
  # Colors = %w(FF8C00 228B22 DAA520 9ACD32 4682B4 9370D8 4169E1 000080 DC143C FF4500 8B4513 40E0D0 FFFF00) #DarkOrange, ForestGreen, GoldenRod, YellowGreen, SteelBlue, MediumPurple, RoyalBlue, Navy, Crimson, OrangeRed, SaddleBrown, Turquoise, Yellow
  Colors = %w(87759D DBDB4C 7A9A9B E0897F 4C96C0 EFDA51 98AD68 EB9D60)

  def initialize(options = {})
    self.period     = options[:period]
    self.filters    = options[:filters]
    self.start_date = options[:start_date]
    self.end_date   = options[:end_date]
  end


end
