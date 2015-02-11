################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class DeploymentWindow::Event < ActiveRecord::Base
  belongs_to :occurrence
  belongs_to :environment
  has_many :requests, foreign_key: :deployment_window_event_id
  has_one :series, through: :occurrence

  delegate :environments, to: :series

  # DeploymentWindow::Event.import does not call before_save so we use after_initialize in such case
  after_initialize :cache_duration
  # Updates cached_duration using before_save in case we update record via event.save()
  before_save :cache_duration
  after_update :notify_suspending, if: :suspended?

  validate do |event|
    event.errors.add(:base, "Start can't be blank.") if event.start_at.blank?
    event.errors.add(:base, "Finish can't be blank.") if event.finish_at.blank?
  end
  validates_presence_of :reason, on: :update, if: -> { moved? || suspended? || resumed? }
  validate :check_suspend, on: :update, if: :moved?
  validate :inclusion_in_scope_of_occurrence, on: :update, if: :moved?
  validate :inclusion_in_scope_of_series, on: :update, if: :moved?
  validate :not_change_start_if_in_progress, on: :update, if: :moved?
  validate :check_start_in_past, on: :update, if: -> { moved? && start_at_changed? }
  validate :check_finish_in_past, on: :update, if: -> { moved? && finish_at_changed? }
  validate :check_finish_before_past, on: :update, if: :moved?

  scope :not_passed,  -> { where 'deployment_window_events.finish_at > ?', Time.zone.now }
  scope :not_started, -> { where 'deployment_window_events.start_at > ?', Time.zone.now }
  scope :not_finished,-> { not_passed }
  scope :preventing,  -> { joins(:series).where('deployment_window_series.behavior = ?', DeploymentWindow::Series::PREVENT) }
  scope :allowing,    -> { joins(:series).where('deployment_window_series.behavior = ?', DeploymentWindow::Series::ALLOW) }

  scope :by_estimate, ->(estimate) do
    where('deployment_window_events.finish_at >= :finish AND
      deployment_window_events.cached_duration >= :duration',
      finish: estimate.minutes.from_now,
      duration: estimate.minutes.to_i
    )
  end

  scope :start_after,     ->(time) { where('deployment_window_events.start_at > ?', time) }
  scope :finish_after,    ->(time) { where('deployment_window_events.finish_at > ?', time) }
  scope :by_name,         ->(name) { joins(:series).where('deployment_window_series.name  like ?', "%#{name}%") }
  scope :by_environment,  ->(environment_id) { where('environment_id = ?', environment_id) }
  scope :not_archived,    -> { joins(:series).where('(deployment_window_series.archived_at IS NULL) AND (deployment_window_series.archive_number IS NULL)') }
  scope :series_visible,  -> { joins(:series).where("(deployment_window_series.aasm_state<>'draft')")}
  scope :active,          -> { where('deployment_window_events.state != ?', SUSPENDED) }
  scope :not_suspended,   -> { active }
  scope :ordered_by_start_finish,   -> { order('deployment_window_events.start_at, deployment_window_events.finish_at') }
  scope :filter_by_occurrence_ids,  ->(occurrence_ids) { where(occurrence_id: occurrence_ids) }
  scope :filter_by_environment_ids, ->(environment_ids) { where(environment_id: environment_ids) }

  attr_accessible :environment_id, :state, :finish_at, :start_at, :suspended, :reason, :occurrence_id, :environment_names, :name, :behavior

  STATES = [
              CREATED = 'created',
              SUSPENDED = 'suspended',
              RESUMED = 'resumed',
              MOVED = 'moved'
           ]

  after_initialize ->{ self.state ||= CREATED } # default state

  STATES.each do |state|
    define_method "#{state}?" do
      self.state == state
    end
  end

  def self.delete_all_by_id(event_ids = [])
    DeploymentWindow::Event.scoped.extending(QueryHelper::WhereIn).
        where_in('deployment_window_events.id', event_ids).delete_all if event_ids.count > 0
  end

  def next_available_by_estimate(estimate)
    query = DeploymentWindow::Event.allowing.not_archived.series_visible.active.by_environment(environment_id).start_after(start_at)
    query = query.by_estimate(estimate) if estimate > 0
    query.ordered_by_start_finish.first
  end

  def duration
    dates_present? ? self.finish_at - self.start_at : 0
  end

  def cache_duration
    self.cached_duration = duration
  end

  def check_suspend
    errors.add(:base, "Can't move suspended event.") if state_was == SUSPENDED
  end

  def notify_suspending
    self.requests.each { |request| Notifier.delay.event_with_requests_suspend(request, self) }
  end

  def inclusion_in_scope_of_occurrence
    errors.add(:base, "Occurrence overlap. Please check event start end event finish.") if dates_present? && !event_in_scope_of_occurrence?
  end

  def inclusion_in_scope_of_series
    errors.add(:base, "Event can't be moved outside of series start and finish range.") if dates_present? && !event_in_scope_of_series?
  end

  def event_in_scope_of_series?
    event_start_in_scope_of_series? && event_finish_in_scope_of_series?
  end

  def event_start_in_scope_of_series?
    (occurrence.series.start_at..occurrence.series.finish_at).cover? start_at
  end

  def event_finish_in_scope_of_series?
    (occurrence.series.start_at..occurrence.series.finish_at).cover? finish_at
  end

  def event_in_scope_of_occurrence?
    return true unless occurrence.series.recurrent?
    event_start_in_scope_of_occurrence? && event_finish_in_scope_of_occurrence?
  end

  def event_start_in_scope_of_occurrence?
    return true unless self.occurrence.prev
    prev_occurrence = self.occurrence.prev
    self.start_at > prev_occurrence.finish_at &&
      self.start_at > prev_occurrence.event(self.environment_id).finish_at
  end

  def event_finish_in_scope_of_occurrence?
    return true unless self.occurrence.next
    next_occurrence = self.occurrence.next
    self.finish_at < next_occurrence.start_at &&
      self.finish_at < next_occurrence.event(self.environment_id).start_at
  end

  def not_change_start_if_in_progress
    errors.add(:base, 'Start date can not be changed while window is in progress') if in_progress? && start_at_changed?
  end

  def check_start_in_past
    errors.add(:base, 'Start date is before current date') if start_in_past?
  end

  def check_finish_in_past
    errors.add(:base, 'Finish date is before current date') if in_past?
  end

  def check_finish_before_past
    errors.add(:base, 'Finish date is before Start date') if finish_before_past?
  end

  def start_in_past?
    dates_present? && self.start_at < DateTime.now
  end

  def in_past?
    dates_present? && self.finish_at < DateTime.now
  end

  def in_progress?
    start_in_past? && !in_past?
  end

  def finish_before_past?
    dates_present? && self.start_at >= self.finish_at
  end

  def dates_present?
    self.start_at && self.finish_at
  end
end
