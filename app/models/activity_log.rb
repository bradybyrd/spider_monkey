################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ActivityLog < ActiveRecord::Base
  include FilterExt

  belongs_to :request
  belongs_to :user
  before_save :update_request_updated_time
  belongs_to :step
  
  validates :request,
            :presence => true
  validates :activity,
            :presence => true
  validates :user,
            :presence => true

  attr_accessible :user, :activity, :step_id, :created_at, :usec_created_at, :request_id, :user_id

  # disable STI
  self.inheritance_column = :_type_disabled

  scope :get_problems_of, lambda { |request_ids|
    select("activity_logs.id, activity_logs.request_id, activity_logs.activity").where("activity_logs.request_id" => request_ids)
  }

  scope :recent_activity_for, lambda { |app_ids, environment_ids|     
    joins(:request => [{ :apps => :environments }]).
    where('apps_requests.app_id' => app_ids).
    where('environments.id' => environment_ids).
    where('requests.environment_id' => environment_ids).
    order("activity_logs.id DESC")
  }  
  
  def  update_request_updated_time
    self.request.update_attribute(:updated_at, Time.now) 
  end
  scope :filter_by_user_id, lambda { |filter_value| where(:user_id => filter_value) }
  scope :filter_by_request_id, lambda { |filter_value| where(:request_id => filter_value) }
  scope :filter_by_step_id, lambda { |filter_value| where(:step_id => filter_value) }
  scope :filter_by_type, lambda { |filter_value| where(:type => filter_value) }

  # may be filtered through REST
  is_filtered cumulative: [:step_id, :type, :request_id, :user_id],
              default_flag: :all

  class << self
    def dashboard_requests_ids(request_ids)
      request_ids = request_ids.split(",") if request_ids.is_a? String
      Request.select('requests.id').select('requests.release_id').select('plan_members.plan_id').extending(QueryHelper::WhereIn)
        .joins(:plan_member)
        .joins("INNER JOIN plans ON plans.id = plan_members.plan_id")
        .where_in('requests.id', request_ids)
        .where('requests.release_id IS NOT NULL AND requests.release_id = plans.release_id')
    end
    
    def inscribe(source_model, who_did_it, from_state, to_state, log_type, comments = nil)
      RequestActivity::ActivityMessage.new(source_model, who_did_it).log_state(to_state, comments)
    end

    def log_event(source_model, who_did_it, comments)
      RequestActivity::ActivityMessage.new(source_model, who_did_it).log_modification(comments)
    end


    def log_event_with_user_readable_format(who_did_it, record)
      #if record.auditable_type=="Step" && record.action=="destroy"
      #   return
      #end

      # If anything is wrong with these finds, they throw application errors,
      # this whole routine needs to be reviewed and all the finds rescued or edge cases handled
      # fixed - rescue added for any exception to avoid application errors.
      begin
        source_model = if record.auditable_type=="Request"
                         if record.action=="destroy"
                           nil
                         else
                           Request.find_by_id(record.auditable_id)
                         end
                       elsif record.auditable_type=="Step"
                         if record.action=="destroy"
                           Request.find record[:changes]['request_id']
                         else
                           Step.find(record.auditable_id)
                         end
                       else
                         if record.action=="destroy"
                           record_obj = if record[:changes]['request_id']
                                          Request.find record[:changes]['request_id']
                                        elsif record[:changes]['step_id']
                                          Step.find record[:changes]['step_id']
                                        else
                                          if record.auditable_type=="Upload"
                                            (Kernel.const_get record[:changes].delete('owner_type') ).find record[:changes].delete('owner_id')
                                            #elsif record.auditable_type=="PropertyValue"
                                            #  (Kernel.const_get record[:changes].delete('value_holder_type')).find  record[:changes].delete('value_holder_id')
                                          elsif record.auditable_type=="LinkedItem"
                                            (Kernel.const_get record[:changes].delete('target_holder_type') ).find record[:changes].delete('target_holder_id')
                                          else
                                            nil
                                          end
                                        end
                           record_obj
                         else
                           record_obj = (Kernel.const_get record.auditable_type).find record.auditable_id
                           if record_obj.respond_to?(:request)
                             record_obj.request
                           elsif record_obj.respond_to?(:step)
                             record_obj.step
                           else
                             if record.auditable_type=="Upload"
                               (Kernel.const_get record[:changes].delete('owner_type')).find  record[:changes].delete('owner_id')
                               #elsif record.auditable_type=="PropertyValue"
                               #  (Kernel.const_get record[:changes].delete('value_holder_type')).find  record[:changes].delete('value_holder_id')
                             elsif record.auditable_type=="LinkedItem"
                               (Kernel.const_get record[:changes].delete('target_holder_type') ).find record[:changes].delete('target_holder_id')
                             else
                               nil
                             end
                           end
                         end
                       end
        if (!source_model.kind_of?(Step) && !source_model.kind_of?(Request)) || source_model.nil?

          #if record.auditable_type=="PropertyValue"
          # Take long route to achieve association so implemented at model level. instead added in steps controller
          #  source_model = case source_model
          #    when Server
          #    when InstalledComponent
          #    when Server
          #  end
          #else
          return
          #end
        end
        message = case source_model
                    when Request
                      ":Request modification"
                    when Step
                      ":Step modification #{source_model.parent ?  source_model.parent.number.to_s+"."+source_model.position.to_s : source_model.position.to_s} : #{source_model.name}"
                    else
                      ""
                  end

        #message << " -- #{record.auditable_type} #{record.action} : #{(get_humanize_map(record.changes, source_model)).inspect}"  if record
        message << " -- #{record.auditable_type} #{record.action} : #{record.changes.to_s}" if record

        request = source_model.respond_to?(:request) ? source_model.request : source_model
        created_at_time = Time.now
        request.respond_to?(:logs) ? (request.logs.create :user => who_did_it, :activity => message, :created_at => created_at_time, :usec_created_at => created_at_time.usec) : ""
      rescue Exception => exc
        # do nothing to do so that application to proceed. Ignore all errors.
      end
    end

    def get_humanize_map ( map, request_or_step)
      map
      model_viewname_mapping = Hash[
        "phase_id",               [Phase, "phase"],
        "work_task_id",           [WorkTask, "work task"],
        "app_id",                 [App, "application"],
        "component_id",           [Component, "component"],
        "runtime_phase_id",       [RuntimePhase, "runtime phase"],
        "category_id",            [Category, "category"],
        "activity_id",            [Activity, "activity"],
        "environment_id",         [Environment, "environment"],
        # "plan_member_id",    [PlanMember, "plan"],
        "release_id",             [Release, "release tag"],
        "request_template_id",    [RequestTemplate, "request template"],
        "business_process_id",    [BusinessProcess, "process"],
        "aasm_state",             [nil, "state"],
        "additional_email_addresses",[nil, "additional email addresses"],
        "estimate",               [nil, "duration"],
        "notify_on_request_complete",[nil, "notify participants on completion"],
        "notify_on_request_hold", [nil, "notify participants on hold"],
        "notify_on_request_start",[nil, "notify participants on start"],
        "notify_on_step_block",   [nil, "notify deployment coordinator when steps are blocked"],
        "notify_on_step_complete",[nil, "notify participants when steps complete"],
        "notify_on_step_start",   [nil, "notify participants when steps start"],
        "owner_id",               [nil, "owner"],
        "planned_at",             [nil, "planned start"],
        "release_id",             [nil, "Release Tag"],
        "requestor_id",           [User, "requestor"],
        "rescheduled",            [nil, "scheduled"],
        "script_id",              [nil, "script"],
        #"script_argument_id",     [ScriptArgument, "script argument"],
        #"",[nil, ""],
        "auto_start",             [nil, "start automatically"],
        "package_content_id",     [PackageContent, "package content"],
        "target_completion_at",   [nil, "Due by"],
        "wiki_url",               [nil, "wiki"]
        ]
      if(map["recipient_id"])
        model_viewname_mapping["recipient_id"] =  [ map["recipient_type"].kind_of?(Array) ? (Kernel.const_get map["recipient_type"][0]) : (Kernel.const_get map["recipient_type"]), "recipient"]
      end
      if(map["source_holder_id"])
        model_viewname_mapping["source_holder_id"] =  [ map["source_holder_type"].kind_of?(Array) ? (Kernel.const_get map["source_holder_type"][0]) : (Kernel.const_get map["source_holder_type"]), map["source_holder_type"].kind_of?(Array) ?  map["source_holder_type"][0] : map["source_holder_type"]]
      end

      if(map["script_id"])
        v = map["script_id"]
        if v.kind_of?(Array)
          if map["script_type"]
            v[0] = (Kernel.const_get(map["script_type"][0]).find v[0]).name  if v[0] && !v[0].blank?
            v[1] = (Kernel.const_get(map["script_type"][1]).find v[1]).name  if v[1] && !v[1].blank?
          else
            v[0] = ((Kernel.const_get request_or_step.script.type.name).find v[0]).name  if v[0] && !v[0].blank?
            v[1] = ((Kernel.const_get request_or_step.script.type.name).find v[1]).name  if v[1] && !v[1].blank?
          end
          map["script_id"] = v
        else
          if v && !v.blank?
            v = request_or_step.respond_to?(:script) ? request_or_step.script.name : v
            map["script_id"] = v
          end
        end
      end
      if(map["owner_id"])
        if request_or_step.kind_of?(Step)
          if map["owner_type"]
            v = map["owner_id"]
            if v.kind_of?(Array)
              v[0] = ((request_or_step.user_owner? ? Group: User).find v[0]).name  if v[0] && !v[0].blank?
              v[1] = ((request_or_step.user_owner? ? User : Group).find v[1]).name  if v[1] && !v[1].blank?
              map["owner_id"] = v
            else
              if v && !v.blank?
                v = ((request_or_step.user_owner? ? User : Group).find v).name
                map["owner_id"] = v
              end
            end

          else
            model_viewname_mapping["owner_id"] = request_or_step.user_owner? ?  [User, "owner"] : [Group, "owner"]
          end
        else
          model_viewname_mapping["owner_id"] =[User, "owner"]
        end
      end
      if map["owner_type"] && !map["owner_id"]
        v = Array.new
        v[0] = ((request_or_step.user_owner? ? Group: User).find request_or_step.owner_id).name
        v[1] = ((request_or_step.user_owner? ? User : Group).find request_or_step.owner_id).name
        map["owner_id"] = v
      end

      newhash = Hash.new
      map.each_pair do |k,v|
        mv_mapping = model_viewname_mapping[k]
        if mv_mapping
          if mv_mapping[0]
            if v.kind_of?(Array)
              v[0] = (mv_mapping[0].find v[0]).name  if v[0] && !v[0].blank?
              v[1] = (mv_mapping[0].find v[1]).name  if v[1] && !v[1].blank?
            else
              if v && !v.blank?
                v = (mv_mapping[0].find v).name
                map[k] = v
              end
            end
          end
          if mv_mapping[1]
            newhash[mv_mapping[1]] = v
            map.delete(k)
          end
        end
      end

      if map["plan_member_id"]
        v = map["plan_member_id"]
        if v.kind_of?(Array)
          if v[0] && !v[0].blank?
            v[0] = (PlanMember.find v[0]).plan.name
          end
          if v[1]&& !v[1].blank?
            v[1] = (PlanMember.find v[1]).plan.name
          end
          else
            v = (PlanMember.find v).plan.name   if v && !v.blank?
          end
        map["plan"] = v
        map.delete("plan_member_id")
      end
      newhash.merge(map)
    end

    def extract_state(log_string)
      log_string =~ /^(?:Step \d+: [\w ]* [\w ]*, )?([\w ]+)/
      $1
    end

    def extract_previous_state(logs, current_index)
      if logs[current_index].activity =~ /^Step (\d+):/
        previous_state_finder(logs, current_index - 1, $1)
      else
        previous_state_finder(logs, current_index - 1)
      end
    end

    def get_status_duration(logs, options)
      status_regex, unrelated_status_regex = get_status_regex_and_unrelated_status_regex(options)

      status_set_at = nil
      total_duration = 0
      logs.each do |log|
        status_set_at = log.created_at if log.activity =~ status_regex

        if status_set_at && log.activity !~ unrelated_status_regex
          total_duration += log.created_at - status_set_at
          status_set_at = nil
        end
      end

      total_duration = Time.now - status_set_at if status_set_at

      total_duration
    end

    def get_status_count(logs, options)
      status_regex, unrelated_status_regex = get_status_regex_and_unrelated_status_regex(options)
      
      count = 0
      logs.each do |log|
        count += 1 if log.activity =~ status_regex
      end

      count
    end

    private

    def previous_state_finder(logs, current_index, step_number = nil)
      return nil if current_index < 0

      if step_number && logs[current_index].activity =~ /^Step #{step_number}:/ || !step_number && logs[current_index].activity !~ /^Step \d+:/
        extract_state(logs[current_index].activity) 
      else
        previous_state_finder(logs, current_index - 1, step_number)
      end
    end

    def get_status_regex_and_unrelated_status_regex(options)
      if options.keys.first == :request
        status = options[:request][:status].to_s.humanize

        status_regex = /^#{status}/
        unrelated_status_regex = /^(#{status}|Step \d+:)/
      else
        status = options[:step][:status].to_s.humanize
        number = options[:step][:number]

        status_regex = /^Step #{number}: [\w ]* [\w ]*, #{status}/
        unrelated_status_regex = /(#{status_regex}|^(?!Step #{number}:))/
      end

      [status_regex, unrelated_status_regex]
    end

  end
end
