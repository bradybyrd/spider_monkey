################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module Charts
  class PlanDataCollector
    
    def initialize(options)
      @report_type = options[:report_type]
      @plan = Plan.find_by_id(options[:plan_id])
      @plan_stage = PlanStage.find_by_id(options[:plan_stage_id])
      init_data
    end

    def data
      @data ||= Charts::Data.new
    end

    def name
      return '' unless ready_to_collect?
      @name ||= init_name
    end

  private
    
    attr_reader :plan, :plan_stage

    def ready_to_collect?
      (!app_by_status_by_stage? || @plan_stage) && @plan.to_bool
    end

    def app_by_stage?
      @report_type == 'app_by_stage'
    end

    def app_by_status?
      @report_type == 'app_by_status'
    end

    def app_by_status_by_stage?
      @report_type == 'app_by_status_by_stage'
    end

    def init_data
      return unless ready_to_collect?

      grouping_objects.each do |group|
        data.add group.name, grouped_members[group].try(:size).to_i
      end
      data.add nil, grouped_members[nil].size if grouped_members[nil]
    end

    def grouping_objects
      return @grouping_objects if @grouping_objects

      if app_by_stage?
        @grouping_objects = plan.stages
      elsif app_by_status?
        @grouping_objects = plan.statuses
      else
        @grouping_objects = plan_stage.statuses
      end

      @grouping_objects
    end

    def grouped_members
      return @grouped_members if @grouped_members
        
      if app_by_stage?
        @grouped_members = plan.members.group_by { |m| m.stage }
      elsif app_by_status?
        @grouped_members = plan.members.group_by { |m| m.status }
      else
        @grouped_members = plan.members.find_all_by_plan_stage_id(plan_stage.id).group_by { |m| m.status }
      end

      @grouped_members
    end

    def init_name
      if app_by_stage?
        "Applications by stage in #{plan.name}"
      elsif app_by_status?
        "Applications by status in #{plan.name}"
      else
        "Applications by status in #{plan.name} in stage '#{plan_stage.name}'"
      end
    end
  end
end
