################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class JobRun < ActiveRecord::Base
  include FilterExt
  # Stores automation and monitoring result
  
  belongs_to :script, foreign_key: :automation_id
  belongs_to :step
  belongs_to :user
  
  scope :currently_running, where("status <> 'complete'")

  scope :date_sort, order("started_at DESC")  
  
  scope :filter_by_run_key, lambda { |filter_value| where(:run_key => filter_value) }
  scope :filter_by_status, lambda { |filter_value| where("LOWER(job_runs.status) like ?", filter_value.downcase) }
  scope :filter_by_user_id, lambda { |filter_value| where(:user_id => filter_value) }
  scope :filter_by_process_id, lambda { |filter_value| where(:process_id => filter_value) }
  scope :filter_by_automation_id, lambda { |filter_value| where(:automation_id => filter_value) }
  scope :filter_by_step_id, lambda { |filter_value| where(:step_id => filter_value) }
  scope :filter_by_job_type, lambda { |filter_value| where("LOWER(job_runs.job_type) like ?", filter_value.downcase) }
  
  # may be filtered through REST
  is_filtered cumulative: [:run_key, :status, :job_type, :process_id, :automation_id, :user_id, :step_id],
              default_flag: :all,
              specific_filter: :job_run_specific_filters

  def self.job_run_specific_filters(entities, adapter_column, filters = {})
    if filters[:currently_running].present? && adapter_column.value_to_boolean(filters[:currently_running])
      entities.currently_running
    else
      entities
    end
  end

  def self.completed_in_last(period)
    since_date = case period
    when "month"
      Time.now - 1.months
    when "week"
      Time.now - 1.weeks
    when "year"
      Time.now - 1.years
    else
      Time.now - 1.weeks
    end      
    where("started_at > ? OR job_type = ?", since_date, "Resource Automation").order("started_at DESC")
  end
  
  def auto?
    job_type.downcase == "automation"
  end
  
  def notify?
    job_type.downcase == "notification"
  end

  def job_request
    "#{step.request.number.to_s}/Step(#{step.id.to_s}): #{step.name}" if step
  end
  
  def job_user
    user = User.find(user_id) unless user_id.nil?
    user.nil? ? "unknown" : user.name
  end
  
  def display_output
    File.open(results_path).read.split("\n").last(100).join("\n") if File.exist?(results_path)
  end
  
  def results_hyperlink_path
    rel_path = results_path.nil? ? "" : (results_path.include?("/automation_results") ? results_path[results_path.index("/automation_results")..255] : "")
  end
  
  def complete_job(job_status = "Complete")
    finish_time = Time.now
    self.status = job_status
    self.finished_at = finish_time
    self.updated_at = finish_time
    self.save
  end  

  def self.log_job(run_params)
    if run_params.include?("job_type")
      job = JobRun.new
      job.job_type = run_params["job_type"]
      job.step_id = run_params.has_key?("step_id") ? run_params["step_id"] : -1
      job.status = "Starting"
      job.run_key = run_params["run_key"]
      job.user_id = run_params["user_id"]
      job.results_path = run_params["results_path"]
      job.automation_id = run_params.has_key?("automation_id") ? run_params["automation_id"] : run_params["script_id"]
      job.started_at = Time.now
      job.save
      job
    else
      raise "error: must have job_id specified"
      -100
    end
  end  
end
