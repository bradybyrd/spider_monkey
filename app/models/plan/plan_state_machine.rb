################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class Plan < ActiveRecord::Base

  include AASM
  include Messaging
  acts_as_messagable

  aasm do
    state :created, :initial => true
    state :planned
    state :started
    state :plan_locked
    state :complete
    state :reopen
    state :archived
    state :hold
    state :cancelled
    state :deleted,  :enter => :prepare_for_deletion

    event :created do
      transitions :to => :created, :from => [:created]
    end

    event :plan_it do
      transitions :to => :planned, :from => [:created, :cancelled]
    end

    event :start do
      transitions :to => :started, :from => [:hold, :planned, :plan_locked]
    end

    event :lock do
      transitions :to => :plan_locked, :from => [:planned, :started]
    end

    event :finish do
      transitions :to => :complete, :from => [:started, :archived]
    end

    event :archive do
      transitions :to => :archived, :from => [:complete]
    end

    event :put_on_hold do
      transitions :to => :hold, :from => [:started, :plan_locked]
    end

    event :cancel do
      transitions :to => :cancelled, :from => [:created, :planned, :hold, :started]
    end

    event :delete do
      transitions :to => :deleted, :from => [:created, :archived, :cancelled]
    end

    event :reopen do
      transitions :to => :planned, :from => [:complete]
    end

  end

  private

  def prepare_for_deletion
    # because this is a soft-delete using the state machine, we will not be
    # triggering the association call backs and need to do some manual cleaning up
    # FIXME: Ideally, the archive and delete are not state machine transitions
    # but follow the universal archive - delete model lifecycle pattern and benefit
    # from all the rails call backs.

    # CHKME: we need to clean up any linked_items to tickets, but should be careful removing
    # the tickets as before since they might be linked to steps that have run and be needed
    # for tracking and auditing.  The tickets would then just float free of any plan which
    # may or may not be ok. As it stands now, the tickets will be deleted with linked_items
    # through this command.

    # FIXME: For now we are deleting tickets explicitely since we are not hard deleting plan
    # instead we are setting its state as 'deleted'. Infact we need to hard delete plan and
    # specify dependant destroy for tickets association so that tickets will get deleted along
    # with plan. So we can remove explicit deletion of tickets here.
    ticket_ids = self.tickets.map(&:id)
    Ticket.destroy(ticket_ids)

    # FIXME: Commenting this out to get through the review for the name defect and
    # then we can find a good solution to the destroy issue.
    # other associations also need to be deleted to avoid leaving garbage in the database
    # and while they all have :destroy on their associations, these will never be triggered
    # until the plans are allowed to call their own destroy method.
    # self.plan_teams.destroy_all
    # self.members.destroy_all #this will nullify the plan_member_id in requests leaving them free standing
    # self.runs.destroy_all
    # self.stage_dates.destroy_all
    # self.plan_env_app_dates.destroy_all
    # self.queries.destroy_all

    # before moving to the deleted state, adjust the name so it has the date and does not
    # cause a uniqueness violation by holding onto a usable name or fail to update because it has grown too long.
    new_name = (self.name.length > 200 ? "#{self.name[0..200]}... " : self.name)
    new_name = "#{new_name} [deleted #{Time.now.to_s(:db)}]"
    success = self.update_attribute(:name, new_name)
    # put in a fail safe if something went wrong
    unless success
      # pick something whose length and uniqueness is known and should not cause an error
      success = self.update_attribute(:name, "Renamed on Update Error [deleted #{Time.now.to_s(:db)}]")
    end
  end

    # a number of operations depend on whether a plan is "running" or "done"
  def running?
    return ![:deleted, :archived, :cancelled, :complete].include?(self.state)
  end

  def done?
    return !self.running?
  end

end
