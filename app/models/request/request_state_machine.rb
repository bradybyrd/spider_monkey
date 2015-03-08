################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class Request < ActiveRecord::Base

  include AASM

  aasm do
    state :created, :initial => true
    state :planned
    state :started
    state :problem
    state :hold
    state :cancelled
    state :complete
    state :deleted

    event :plan_it, :success =>[:planning_work, :send_mail_planned, :schedule_from_state]do
      transitions :to => :planned, :from => [:created, :cancelled]
    end

    event :created, :success => :push_msg do
      transitions :to => :created, :from => [:created]
    end

    event :start, :success => [:push_msg, :send_mail_started] do
      transitions :to => :started, :from => [:planned, :hold], :guard => :without_compliance_issues?
    end

    event :problem_encountered, :success => [:push_msg, :send_mail_problem] do
      transitions :to => :problem, :from => [:started]
    end

    event :resolve, :success => [:resolving_work, :send_mail_resolved] do
      transitions :to => :started, :from => [:problem]
    end

    event :put_on_hold, :success => [:send_mail_hold, :lock_steps, :push_msg, :schedule_from_state] do
      transitions :to => :hold, :from => [:started, :problem]
    end

    event :cancel, :success => [:freeze_request!, :push_msg, :send_mail_cancelled] do
      transitions :to => :cancelled, :from => [:created, :planned, :started, :problem, :hold]
    end

    event :finish, :success => [:completing_work, :send_mail_completed] do
      transitions :to => :complete, :from => [:started]
    end

    event :reopen, :success => [:reopening_work, :send_mail_planned] do
      transitions :to => :planned, :from => [:complete]
    end

    event :soft_delete, :success => :soft_deleting_work do
      transitions :to => :deleted, :from => [:cancelled, :complete]
    end
  end

  def aasm_event_fired(name, old_state, new_state )
    ActivityLog.inscribe(self, state_changer || self.deployment_coordinator, old_state, new_state, "runtime", log_comments)
  end

  # is called if event transition was failed
  # args(to_state:symbol, from_state:symbol)
  def aasm_event_failed(new_state_name, old_state_name)
    # notify on request failed to start because of DW validations
    send_mail_failed_to_start_dw if failed_to_start(new_state_name) && has_deployment_window_notices?
  end

  def next_state
    if created? || cancelled?
      :plan
    elsif planned? || hold?
      :start
    elsif started?
      :problem
    elsif problem?
      :resolve
    elsif complete?
      :reopen
    else
      raise Exception, "unknown state of #{self} appeared. "
    end
  end

  private

  def send_mail_planned
    if self.notify_on_request_planned
      Notifier.delay.request_send_mail(self, "request_planned", "has been planned.") rescue nil
    end
  end

  def send_mail_started
    if self.notify_on_request_start
      Notifier.delay.request_send_mail(self, "request_started", "has been started.")  rescue nil
    end
  end

  def send_mail_problem
    if self.notify_on_request_problem
      Notifier.delay.request_send_mail(self, "request_in_problem", "has been put in problem.")  rescue nil
    end
  end

  def send_mail_resolved
    if self.notify_on_request_resolved
      Notifier.delay.request_send_mail(self, "request_resolved", "has been resolved.")  rescue nil
    end
  end

  def send_mail_hold
    if self.notify_on_request_hold
      Notifier.delay.request_send_mail(self, "request_on_hold", "has been put on hold.")  rescue nil
    end
  end

  def send_mail_completed
    if self.notify_on_request_complete
      Notifier.delay.request_send_mail(self, "request_completed", "is completed.")  rescue nil
    end
  end

  def send_mail_cancelled
    if self.notify_on_request_cancel
      Notifier.delay.request_send_mail(self, "request_cancelled", "has been cancelled")  rescue nil
    end
  end

  def send_mail_failed_to_start_dw
    if self.notify_on_dw_fail
      Notifier.delay.request_send_mail(self,
                                       'request_failed_to_start_of_deployment_window',
                                       'has failed to start because of Deployment Window validations',
                                       self.deployment_window_notices_message) rescue nil
    end
  end

  # called when successfully transitioned to the planned state
  def planning_work
    self.planned_at = Time.now
    self.unfreeze_request! if self.frozen?
    self.push_msg
  end

  # called when successfully transitioned into resolved state
  def resolving_work
    self.resolve_procedures
    self.executable_steps.each { |step| step.force_resolve! if step.problem? }
    self.prepare_steps_for_execution
    self.push_msg
  end

  # called when successfully transitioned into the complete state
  def completing_work
    self.completed_at = Time.now

    # Log to recent_activities on request completion.
    request_data = name.blank? ? number : name
    req_link = request_link(number)

    # BJB Script and REST dont have current user
    log_user = User.current_user.nil? ? self.backup_owner : User.current_user

    # TODO: RJ: Rails 3: Log Activity plugin not compatible with rails 3
    #log_user.log_activity(:context => "#{req_link} has been #{aasm_state}") do
      freeze_request!
    #end
    update_properties # Now commit properties on completed request

    # if there is a run for this request, let it know we are done
    self.run.try(:request_completed, self)
    self.push_msg

  end

  # called when successfully transitioned into the reopened state
  def reopening_work
    attr_to_update = {scheduled_at: nil,
                      auto_start: false,
                      started_at: nil,
                      target_completion_at: nil,
                      completed_at: nil,
                      deployment_window_event: nil}
    attr_to_update.merge!({:environment_id => Environment.find_or_create_default.id}) unless environment.active
    self.update_attributes(attr_to_update)
    self.unfreeze_request!
    applications = self.apps
    applications.each do |app|
      unless app.active
        has_inactive_app = true
        applications.delete app
      end
    end
    if defined?(has_inactive_app)
      default_app = App.find_or_create_default
      self.apps << default_app unless applications.include?(default_app)
    end
    self.push_msg
  end

  # called when successfully transitioned into the deleted state
  def soft_deleting_work
    # be sure to clear plan_member_id
    self.plan_member.destroy if self.plan_member
    self.update_attribute(:deleted_at, Time.now)
  end

  # check for plan member compliance issues if member of plan
  def without_compliance_issues?
    issues = plan_compliance_issues
    if issues.present?
      logger.error("Request #{ number } could not be started because of plan compliance issues: #{ issues.map(&:message).to_sentence }")
      false
    else
      true
    end
  end

  def failed_to_start(new_state_name)
    new_state_name == :start
  end

end
