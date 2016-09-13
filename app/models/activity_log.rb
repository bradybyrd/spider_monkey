################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ActivityLog < ActiveRecord::Base
  include FilterExt

  belongs_to :activity
  belongs_to :user
  
  validates :activity,
            :presence => true
  validates :user,
            :presence => true

  attr_accessible :user, :activity, :created_at, :usec_created_at, :user_id

  # disable STI
  self.inheritance_column = :_type_disabled

  
  def  update_request_updated_time
    self.request.update_attribute(:updated_at, Time.now) 
  end
  scope :filter_by_user_id, lambda { |filter_value| where(:user_id => filter_value) }
  scope :filter_by_type, lambda { |filter_value| where(:type => filter_value) }

  # may be filtered through REST
  is_filtered cumulative: [:step_id, :type, :request_id, :user_id],
              default_flag: :all

  class << self
    
    def inscribe(source_model, who_did_it, from_state, to_state, log_type, comments = nil)
      LogActivity::ActivityMessage.new(source_model, who_did_it).log_state(to_state, comments)
    end

    def log_event(source_model, who_did_it, comments)
      LogActivity::ActivityMessage.new(source_model, who_did_it).log_modification(comments)
    end


    def log_event_with_user_readable_format(who_did_it, record)
      #if record.auditable_type=="Step" && record.action=="destroy"
      #   return
      #end

      # If anything is wrong with these finds, they throw application errors,
      # this whole routine needs to be reviewed and all the finds rescued or edge cases handled
      # fixed - rescue added for any exception to avoid application errors.
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
