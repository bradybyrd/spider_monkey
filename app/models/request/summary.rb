################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class Request < ActiveRecord::Base

  def total_run_count
    @activity_logs = logs unless @activity_logs
    @activity_logs.select{|l| l.activity  =~ /Complete/ && !l.activity.include?('Step')}.count
  end

  def steps_with_groups
    @should_execute_steps = steps.should_execute
    @steps_with_groups = @should_execute_steps.where(owner_type: 'Group')
  end

  def participant_groups
    @groups = Group.where(:id => steps_with_groups.map(&:owner_id)).order('groups.name asc')
  end

  # FIXME: This seems to loop instead of using SQL to get the related tasks
  def work_tasks
    @should_execute_steps = steps.should_execute.top_level unless @should_execute_steps
    @steps_with_work_tasks = @should_execute_steps.select{|s| !s.work_task_id.blank? }
    @work_tasks = WorkTask.where(:id => @steps_with_work_tasks.map(&:work_task_id).uniq).order('work_tasks.name asc')
  end

  def total_groups # Total groups involved in steps
    steps_with_groups.map(&:owner_id).uniq.count
  end

  def total_step
    steps.count - steps.find_procedure.count
  end

  def total_participants # Total participants involved in steps
    users_in_step.count
  end

  def users_in_step
    User.where(:id => steps.should_execute.select{|s| s.owner_type == 'User'}.map(&:owner_id).uniq).order('users.last_name asc')
  end

  def participating_users
    User.where(:id => @activity_logs.map(&:user_id).uniq).order('users.last_name asc')
  end

  def automatic_steps
    @should_execute_steps.where(:manual => false)
  end

  def manual_steps
    conds = {"steps.manual" => true, "steps.procedure" => false}
    @should_execute_steps.where(conds)
  end

  def step_modification_prefix(step)
    RequestActivity::StepActivityInfo.new(step).modification_prefix
  end

  ["ready", "problem", "in_process", "blocked", "hold"].each do |state_name|
    define_method "steps_time_in_#{state_name}" do |step = nil|
      @activity_logs = logs unless @activity_logs
      regex = /\"#{state_name}\"/
      if step.blank?
        status_logs = @activity_logs.select do |l|
          l.activity.starts_with?(RequestActivity::StepActivityInfo::MODIFICATION_PREFIX) && l.activity =~ regex
        end
      elsif step.is_a?(Hash)
        step_prefix = step_modification_prefix(step["step"])
        status_logs = @activity_logs.select {|l| (l.activity =~ /#{Regexp.escape(step_prefix)}/) && (step["user_id"] == l.user_id) }
      else
        step_prefix = step_modification_prefix(step)
        status_logs = @activity_logs.select {|l| l.activity =~ /#{Regexp.escape(step_prefix)}/ }
      end
      time_between_states(status_logs, state_name)
    end
  end


  #
  # These functions create database independence
  # while doing the math
  def earliest(logs)
    return nil if logs.blank?
    f = logs.first
    logs.each do |l|
      f = l if (f.id > l.id)
    end
    f
  end

  def time_between_states(status_logs, state)
    return 0.00 if status_logs.size == 0
    duration = []
    state_entered_events = status_logs.select {|l| l.activity =~ /\"aasm_state\"=>\[.*\"#{state}\"\]/}
    state_left_events = status_logs.select {|l| l.activity =~ /\"aasm_state\"=>\[\"#{state}\".*\]/}

    state_entered_events.each do |entered_event|
      step_prefix = entered_event.activity.scan(/#{RequestActivity::StepActivityInfo::MODIFICATION_PREFIX}.*--/).first
      state_left_events_after = state_left_events.select {|e| (e.id > entered_event.id) && e.activity.starts_with?(step_prefix)}
      first_state_left_event_after = earliest(state_left_events_after)
      unless first_state_left_event_after.blank?
        duration << (first_state_left_event_after.created_at - entered_event.created_at)
      else
        duration << (Time.now - entered_event.created_at)
      end
    end
    return duration.compact.sum
  end

  def time_spent_in_problem_blocked_state
    steps_time_in_problem + steps_time_in_blocked
  end

  def steps_execution_time(count_execution_time_of_steps=nil)
    @should_execute_steps = steps.should_execute.top_level unless @should_execute_steps
    @activity_logs = logs unless @activity_logs
    steps_hash = if count_execution_time_of_steps.blank?
      @should_execute_steps
    else
      count_execution_time_of_steps # Specially selected step objects
    end.group_by(&:number)
    step_numbers = steps_hash.keys
    parent_steps = step_numbers.select{|n| n if n.split('.').first != n}.collect{|i| i.split(".").first}
    step_numbers = step_numbers.select{|s| !parent_steps.include?(s)}

    @steps_by_execution_time = {}
    step_numbers.each do |sn|
      step = steps_hash[sn][0]
      step_prefix = step_modification_prefix(step)

      duration = []

      enter_ready_states = @activity_logs.select{|l| (l.activity =~ /#{Regexp.escape(step_prefix)}/) && (l.activity =~ /\"aasm_state\"=>\[.*\"ready\"\]/)}
      enter_ready_states.each do |e|
        enter_complete_states_after = @activity_logs.select {|l| (l.activity =~ /#{Regexp.escape(step_prefix)}/) && (l.id > e.id) && (l.activity =~ /\"aasm_state\"=>\[.*\"complete\"\]/)}
        first_complete_state = earliest(enter_complete_states_after)
        unless first_complete_state.blank?
          duration << (first_complete_state.created_at - e.created_at)
        end
      end

      duration = duration.compact.sum

      if duration > 0
        @steps_by_execution_time[duration] = steps_hash[sn]
      end
    end
    @steps_by_execution_time
  end

  def total_time_by_groups(group_id)  # Actual Execution time and not estimation time
    steps_execution_time(@steps_with_groups.select{|s|s.owner_id == group_id}).keys.sum
  end

  def total_time_by_work_tasks(work_task_id) # Actual Execution time and not estimation time
    steps_execution_time(@steps_with_work_tasks.select{|s|s.work_task_id == work_task_id}).keys.map(&:to_i).sum
  end

  def duration_in_state_in_float(time_array)
    time_array.map { |s| sprintf("%.2f", s).to_f }
  end

  def execution_time_of_all_steps
    steps_execution_time(steps.should_execute.top_level || []).keys.sum
  end

  def total_execution_time_of_all_steps
    steps.should_execute.where("estimate is not null").sum(:estimate)
  end

  def completion_time_in_minutes
     completion_time_seconds / 60
  end

  def completion_time_seconds
    completed_at && started_at ? (completed_at - started_at).round : 0
  end

  def create_timeline_data
    step_info = ordered_step_info
    info = []
    logs.each do |log|
      if log.activity.include?("Step")
        step_pos = log.activity.split(":")[0].gsub("Step ","")
        step_id = log.step_id
        idx = step_info.map{ |a| a[0]}.index(step_id)
        idx = step_info.map{ |a| a[3]}.index(step_pos.to_i) if step_id.nil?
        info << [step_info[idx][0],
              log.activity.split(", ")[1].try(:strip),
              log.created_at, step_info[idx][2], step_info[idx][3]] if idx
      end
    end
    info
  end

  def summary_timeline
    timeline = create_timeline_data
    cur_step = timeline[0][0]
    indent = 0
    timeline.each do |item|
      step = steps.find_by_id(item[0]) unless item[0].nil?
      puts "Step #{step.number}:"
    end
  end

  def property_summary_maps
    ics = steps.map(&:installed_component_id).reject{ |s| s.nil? }.uniq
    steps_map = {}
    servers = []
    server_aspects = []
    server_map = {}
    server_aspect_map = {}
    ic_map = {}
    steps.each do |step|
      steps_map[step.id] = {:name => step.name, :position => step.position, :number => step.number }
      unless step.servers.nil?
        step.servers.each do |serv|
          servers << serv.id
          if server_map[serv.id].nil?
            server_map[serv.id] = [step.id]
          else
            server_map[serv.id] << step.id
          end
        end
      end
      unless step.server_aspects.nil?
        step.server_aspects.each do |serv|
          server_aspects << serv.id
          if server_aspect_map[serv.id].nil?
            server_aspect_map[serv.id] = [step.id]
          else
            server_aspect_map[serv.id] << step.id
          end
        end
      end
      if step.installed_component_id
        if ic_map[step.installed_component_id].nil?
          ic_map[step.installed_component_id] = [step.id]
        else
          ic_map[step.installed_component_id] << step.id
        end
      end
    end
    {:steps => steps_map, :components => ics, :servers => servers.uniq, :server_aspects => server_aspects.uniq, :ic_map => ic_map, :server_map => server_map, :server_aspect_map => server_aspect_map }
  end

end

