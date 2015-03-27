################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class Step < ActiveRecord::Base

  include AASM

  aasm do

    state :locked, :initial => true
    state :ready
    state :in_process
    state :blocked
    state :problem
    state :being_resolved
    state :complete
    # state :waiting

    event :ready_for_work, :success => [:push_msg, :send_mail_ready] do
      transitions :to => :ready, :from => [:locked]
    end

    event :start, :success => [:push_msg, :send_mail_start] do
      transitions :to => :in_process, :from => [:ready, :locked, :complete], :guard => :startable_with_blade_password?
    end

    event :lock, :success => [:lock_steps, :push_msg]  do
      transitions :to => :locked, :from => [:ready, :in_process, :problem], :guard => :only_procedures_from_in_process?
    end

    event :done, :success => [:complete_step!, :push_msg, :send_mail_complete] do
      transitions :to => :complete, :from => [:in_process, :problem, :ready, :locked], :guard => :completeable?
    end

    event :reset, :success => [:reset_step_work] do
      transitions :to => :locked, :from => [:complete]
    end

    event :oops, :success => [:unfreeze_step!, :push_msg] do
      transitions :to => :in_process, :from => [:complete]
    end

    event :problem, :success => [:push_msg, :send_mail_problem], after_commit: [:update_request_status] do
      transitions :to => :problem, :from => [:in_process]
    end

    event :resolve, :success => [:push_msg], after_commit: [:update_request_status, :resolve_run_script] do
      transitions :to => :in_process, :from => [:problem]
    end

    event :finish_resolution, :success => :push_msg do
      transitions :to => :in_process, :from => [:being_resolved, :problem]
    end

    event :force_resolve, :success => [:push_msg], after_commit: [:run_script] do
      transitions :to => :in_process, :from => [:problem]
    end

    event :block, :success => [:push_msg, :send_mail_block] do
      transitions :to => :blocked, :from => [:locked, :ready, :in_process]
    end

    event :unblock_ready, :success => :push_msg do
      transitions :to => :ready, :from => [:blocked]
    end

    event :unblock_in_process, :success => :push_msg do
      transitions :to => :in_process, :from => [:blocked]
    end
  end

  private

  def reset_step_work
    self.unfreeze_step!
    self.request.try(:lock_steps)
    self.push_msg
  end

  def startable_with_blade_password?
    self.startable? && self.bladelogic_password_available?
  end

  def aasm_event_fired( old_state, new_state )
    who_did_it = auto? ? User.current_user : (state_changer || (user_owner? ? owner : request.user))
    ActivityLog.inscribe(self, who_did_it, old_state, new_state, "runtime")
  end

  def send_mail_ready
    if self.request.notify_on_step_ready && allow_mail_delivery?
      Notifier.delay.step_status_mail(self, 'step_ready', 'is ready.') rescue nil
    end
  end

  def send_mail_start
    if self.request.notify_on_step_start && allow_mail_delivery?
      Notifier.delay.step_status_mail(self, 'step_started', 'is started.') rescue nil
    end
  end

  def send_mail_complete
    if self.request.notify_on_step_complete && allow_mail_delivery?
      Notifier.delay.step_status_mail(self, 'step_completed', 'is completed.') rescue nil
    end
  end

  def send_mail_problem
    if self.request.notify_on_step_problem && allow_mail_delivery?
      Notifier.delay.step_status_mail(self, 'step_problem', 'has been put in problem.') rescue nil
    end
  end

  def send_mail_block
    if self.request.notify_on_step_block && allow_mail_delivery?
      Notifier.delay.step_status_mail(self, 'step_blocked', 'is blocked.') rescue nil
    end
  end

end
