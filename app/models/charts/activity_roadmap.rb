################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module Charts
  class ActivityRoadmap < GanttChart
    Colors = %w(yellow red blue)

    attr_accessor :activity, :template, :year

    def initialize(activity, year = Date.today.year)
      @activity = activity
      @template = activity.activity_category
      @year = year
    end

    def init_gantt
      args = args_to_js ".gantt_#{object_id}", :today => Date.today.day_of(year)
      "var gantt = new Gantt(#{args});"
    end

    def bars
      the_bars = []
      if template.service?
        the_bars << bar(:row => 0, :start => -1, :end => 366, :color => Colors.first)
      else
        template.activity_phases.each_with_index do |phase, idx|
          start_on, end_on = activity.phase_start_date(phase), activity.phase_end_date(phase)
          next unless start_on && end_on
          if end_on.year == year
            # PP - to_date method is added because default_format_date is for date objects
            right_label = end_on.to_date.default_format_date
          else
            right_label = nil
          end

          the_bars << bar(:row         => idx,
                          :start       => start_on.day_of(year),
                          :end         => end_on.day_of(year),
                          :color       => Colors[idx % Colors.size],
                          :right_label => right_label)
        end
      end
      the_bars.join
    end

    def milestones
      the_milestones = []
      if template.service?
        activity.deliverables.each do |deliverable|
          the_milestones << milestone_content(deliverable, 0)
        end
      else
        template.activity_phases.each_with_index do |phase, idx|
          start_on, end_on = activity.phase_start_date(phase), activity.phase_end_date(phase)
          next unless start_on && end_on
          activity.deliverables.on_phase(phase).each do |deliverable|
            the_milestones << milestone_content(deliverable, idx)
          end
        end
      end
      the_milestones.join
    end

    def milestone_content(deliverable, row)
      shape = deliverable.delivered_on.blank? ? :circle : :triangle
      deliver_date = deliverable.delivered_on || deliverable.projected_delivery_on
      return unless deliver_date
      return if deliver_date.day_of(year) > 365 || deliver_date.day_of(year) < 0
      
      text = "#{deliverable.name}\n #{deliver_date.to_date.default_format_date}"

      milestone(deliver_date.day_of(year), row, text, shape)
    end

    def to_s
      %Q(
        $(function() { 
          #{init_gantt} 
          #{bars} 
          #{milestones}
          $.gantt = gantt;
        });
      )
    end
  end
end
