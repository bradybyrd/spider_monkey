################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class ScheduledJob < ActiveRecord::Base

  STATUS = [
    SCHEDULED   = 'Scheduled',
    IN_PROGRESS = 'In progress',
    CANCELED    = 'Canceled',
    COMPLETED   = 'Completed',
    FAILED      = 'Failed'
  ]

  attr_accessible :log, :owner_id, :planned_at, :resource_id, :resource_type, :status,
                  :owner, :resource

  belongs_to :owner, :class_name => 'User'
  belongs_to :resource, :polymorphic => true

  validates :resource_id, :resource_type, :owner_id, :status, :planned_at, :log,
            :presence => true

  scope :scheduled, where(:status => SCHEDULED)
  scope :completed, where(:status => COMPLETED)
  scope :failed, where(:status => FAILED)
  scope :by_date, order('planned_at desc')

  scope :accessible_to_user, lambda { |user|
    if user.admin?
      scoped
    else
      where(:owner_id => user.id)
    end
  }

  after_initialize :init
  after_destroy :remove_job_from_service #before_destroy

  def init(attributes = {}, options = {})
    @service_wrapper = ScheduledJobService::ServiceWrapper
  end

  def remove_job_from_service
    @service_wrapper.remove(job_name)
  end

  def self.schedule(resource, current_user)
    sj = ScheduledJob.find_scheduled_by_resource(resource)
    if sj.nil?
      sj = resource.scheduled_jobs.build
      sj.log = 'Job Scheduled'
    end
    sj.planned_at = resource.scheduled_at
    sj.owner = current_user
    sj.status = SCHEDULED

    sj.save

    sj.schedule
  end

  def schedule
    @service_wrapper.at(self)
  end

  def self.unschedule(resource)
    sj = ScheduledJob.find_scheduled_by_resource(resource)
    sj.destroy if sj.present?
  end

  def job_name
    "#{resource_id}##{resource_type}"
  end

  def update_job_status(status, message)
    update_attributes(:status => status, :log => message)
  end

  def update_job_status_and_note(status, message, short_message=nil)
    short_message = message if short_message.nil?
    resource.notes.create(:user_id => owner_id, :content => short_message)
    update_job_status(status, message)
  end

  private

  def self.find_scheduled_by_resource(resource)
    where(:resource_id => resource.id,
          :resource_type => 'Request',
          :status => SCHEDULED).first
  end

end
