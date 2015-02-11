################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################
require 'permission_scope'

class DeploymentWindow::Series < ActiveRecord::Base
  include IceCube
  include FilterExt
  include ObjectState
  include PermissionScope

  ARCHIVED_PATERN = /(\s\[archived .*\])/

  BEHAVIOR = [
                ALLOW = 'allow',
                PREVENT = 'prevent'
             ]
  DURATION_DAYS = (0..30)
  OCCURRENCE_YEAR_LIMIT = 2
  OCCURRENCE_LIMIT_COUNT = 366 * OCCURRENCE_YEAR_LIMIT
  ROUND_TIME_TO = 30.minutes
  NEEDED_ATTRS = %w(id name start_at finish_at frequency_description frequency_name behavior recurrent archived_at archive_number)

  after_initialize :set_time, if: :new_record?
  before_validation :update_schedule, if: :recurrent?
  before_destroy :check_if_destroyable
  before_update :prevent_update_for_archived_entities

  has_many :occurrences, dependent: :destroy, order: 'deployment_window_occurrences.start_at'
  has_many :events, through: :occurrences
  has_many :environments, through: :events, uniq: true
  has_many :requests, through: :events

  attr_accessor :environment_ids, :frequency, :stored_requests, :check_permissions
  attr_accessible :behavior, :finish_at, :name, :recurrent, :schedule, :start_at, :duration_in_days,
                  :environment_ids, :environment_names, :frequency, :archived_at, :archive_number, :occurrences_ready, :frequency_description,
                  :frequency_name, :aasm_state, :created_by, :check_permissions

  serialize :schedule, IceCube::Schedule

  validates_presence_of :behavior, :name
  validate do |series|
    series.errors.add(:base, "Start can't be blank.") if series.start_at.blank?
    series.errors.add(:base, "Finish can't be blank.") if series.finish_at.blank?
    series.errors.add(:base, "Frequency can't be blank.") if series.schedule.blank? && recurrent?
  end
  validates_uniqueness_of :name
  validates_length_of     :name, maximum: 255
  validates_inclusion_of  :behavior, in: BEHAVIOR
  validate :check_behavior, if: :persisted?
  validate :check_start_in_past, if: :start_at_changed?
  validate :check_finish_equal_start
  validate :check_finish_before_past
  validate :check_duration, if: :recurrent?
  validate :check_frequency, if: proc { recurrent? && !schedule.blank? && !archived_at_changed? }
  validates_with PermissionsPerEnvironmentValidator

  scope :archived, lambda { where %Q{#{self.table_name}.archived_at IS NOT NULL AND #{self.table_name}.archive_number IS NOT NULL} }
  scope :unarchived, lambda { where(archived_at: nil, archive_number: nil) }
  scope :allowed, -> { where(behavior: ALLOW) }
  scope :filter_by_name, lambda { |filter_value| where('LOWER(name) like ?', filter_value.downcase) }
  scope :filter_by_behavior, lambda { |filter_value| where('behavior = ?', filter_value.downcase) }
  scope :filter_by_environment, lambda { |filter_value| joins(:environments).where('environments.id = ?', filter_value.to_i) }
  scope :filter_by_start_before, lambda { |filter_value| where('start_at <= ?', time_for_filter(filter_value)) }
  scope :filter_by_start_after, lambda { |filter_value| where('start_at >= ?', time_for_filter(filter_value)) }
  scope :filter_by_finish_before, lambda { |filter_value| where('finish_at <= ?', time_for_filter(filter_value)) }
  scope :filter_by_finish_after, lambda { |filter_value| where('finish_at >= ?',  time_for_filter(filter_value)) }
  scope :filter_by_user_environments, lambda { |ids|
    query = DeploymentWindow::Series.select("DISTINCT deployment_window_series.id")
                                    .joins(:events)
                                    .where("deployment_window_events.environment_id IN(?)", ids)
    joins("INNER JOIN (#{query.to_sql}) user_series ON user_series.id = deployment_window_series.id")
  }

  scope :active_per_environment, lambda { |env| filter_by_user_environments(env.id).unarchived.not_draft }

  scope :filter, ->(filters = {}) do
    filters = {} if not filters.is_a? Hash
    filters[:complicated] = [] if not filters[:complicated].is_a? Enumerable

    filters[:complicated].reduce(scoped.where(filters[:simple])) { |result, arel| result.where arel }
  end

  scope :search, ->(q = nil) do
    q.present? ? where('lower(deployment_window_series.name) LIKE ? OR lower(deployment_window_series.environment_names) LIKE ?', *(["%#{q}%".downcase] * 2)) :
                 scoped
  end

  # REST API filters
  is_filtered cumulative: [:name, :behavior, :start_before, :start_after, :finish_before, :finish_after, :environment],
              boolean_flags: { default: :unarchived, opposite: :archived }

  self.per_page = 20

  # initialize AASM state machine for object status
  init_state_machine

  def start_date_changed?
    if start_at_change
      return true if start_at_change.all?(&:nil?)
      changeset = start_at_change.map {|n| n.nil? ? n : n.to_date }
      !(changeset.first == changeset.last)
    else
      false
    end
  end

  def self.fetch_depends_on_user(user)
    by_ability(:list, user)
  end

  def non_recurrent?
    !recurrent?
  end

  def allow?
    behavior == ALLOW
  end

  def has_active_requests?
    requests.active.any?
  end

  def destroyable?
    true
  end

  def archived? #TODO check why acts_as_archival doesn't work here
    !!(archived_at? && archive_number)
  end

  def archive #TODO check why acts_as_archival doesn't work here
    self.class.transaction do
      begin
        if can_be_archived? && !self.archived?
          head_archive_number ||= Digest::MD5.hexdigest("#{self.class.name}#{self.id}")
          self.archived_at = Time.zone.now
          local_time = self.archived_at.to_s.gsub(/\s\+\d{4}/,'')
          self.name = self.name.gsub(ARCHIVED_PATERN, '') + " [archived #{local_time}]"
          self.archive_number = head_archive_number
          self.save!
          true
        else
          false
        end
      rescue
        raise ActiveRecord::Rollback
      end
    end
  end

  def unarchivable?
    archived? && !in_past?
  end

  def unarchive #TODO check why acts_as_archival doesn't work here
    self.class.transaction do
      begin
        if self.archived?
          self.archived_at = nil
          self.archive_number = nil
          self.save!(validate: false) # Do we need to carry about validations here?
        end
        true
      rescue
        raise ActiveRecord::Rollback
      end
    end
  end

  def can_be_archived?
    !has_active_requests?
  end

  def toggle_archive
    success = true
    if archived?
      if self.respond_to?(:aasm_state)
        self.aasm_state = 'retired'
      end
      if success
        return self.unarchive
      else
        return success
      end
    else
      if self.respond_to?(:aasm_state)
        if self.may_archival? || self.aasm_state != 'archived_state'
          begin
            success = self.archival_no_archive!
          rescue
            self.errors[:toggle_archive] << "You cannot archive a " +self.class.to_s.underscore.humanize.downcase+" unless it is in a retired state"
            success = false
          end
        end
      end

      if success
        return self.archive
      else
        return success
      end
    end
  end

  def duration
    if recurrent?
      (duration_upon_day % 1.day) + duration_in_days.days
    else
      (self.finish_at - self.start_at).round
    end
  end

  def duration_upon_day
    return 0 unless dates_present?
    ((self.finish_at.hour - self.start_at.hour).hours + (self.finish_at.min - self.start_at.min).minutes)
  end

  def not_change_start_if_in_progress
    errors.add(:base, 'Start date is changed while window is in progress') if in_progress? && start_at_changed?
  end

  def check_start_in_past
    errors.add(:base, I18n.t('deployment_window.validations.date.start_at_before_current_date')) if start_date_changed? && start_in_past_date?
    errors.add(:base, I18n.t('deployment_window.validations.date.non_recurrent.start_at_before_current_time')) if start_in_past_time? && non_recurrent?
    errors.add(:base, I18n.t('deployment_window.validations.date.recurrent.start_at_before_current_time')) if start_in_past_time? && recurrent?
  end

  def check_finish_before_past
    errors.add(:base, I18n.t('deployment_window.validations.date.finish_at_before_start_at_date')) if finish_before_past_date?
    errors.add(:base, I18n.t('deployment_window.validations.date.non_recurrent.finish_at_before_start_at_time')) if finish_before_past_time? && non_recurrent? && dates_equal?
    errors.add(:base, I18n.t('deployment_window.validations.date.recurrent.finish_at_before_start_at_time')) if finish_before_past_time? && recurrent?
  end

  def check_finish_equal_start
    errors.add(:base, I18n.t('deployment_window.validations.date.non_recurrent.start_at_equal_finish_at')) if finish_equal_start? && non_recurrent?
    errors.add(:base, I18n.t('deployment_window.validations.date.recurrent.start_at_equal_finish_at')) if finish_equal_start? && recurrent?
  end

  # def check_duration_overlapping
  #   errors.add(:base, 'Occurrence is out of Start/Finish date range') if !finish_before_past_time? && duration_overlap? && !self.schedule.blank? && recurrent?
  # end

  def check_frequency
    return unless frequency_hash[:interval].is_a? Numeric
    check_daily_frequency
    check_weekly_frequency
    check_monthly_frequency
    check_weekly_days
    check_monthly_days
  end

  def check_daily_frequency
    if schedule_rule.is_a?(IceCube::DailyRule) && !(1..999).include?(frequency_hash[:interval])
      errors.add(:base, I18n.t('deployment_window.validations.frequency.daily_range', range: '1-999'))
    end
  end

  def check_weekly_frequency
    if schedule_rule.is_a?(IceCube::WeeklyRule) && frequency_hash[:interval] && !(1..99).include?(frequency_hash[:interval])
      errors.add(:base, I18n.t('deployment_window.validations.frequency.weekly_range', range: '1-99'))
    end
  end

  def check_monthly_frequency
    if schedule_rule.is_a?(IceCube::MonthlyRule) && frequency_hash[:interval] && !(1..99).include?(frequency_hash[:interval])
      errors.add(:base, I18n.t('deployment_window.validations.frequency.monthly_range', range: '1-99'))
    end
  end

  def check_weekly_days
    if schedule_rule.is_a?(IceCube::WeeklyRule) && frequency_days_empty?
      errors.add(:base, I18n.t('deployment_window.validations.frequency.weekly_days'))
    end
  end

  def check_monthly_days
    if schedule_rule.is_a?(IceCube::MonthlyRule) && frequency_days_empty?
      errors.add(:base, I18n.t('deployment_window.validations.frequency.monthly_days'))
    end
  end

  def frequency_days_empty?
    frequency_hash[:validations].blank? ||
    (frequency_hash[:validations][:day].blank? && frequency_hash[:validations][:day_of_month].blank? &&
     frequency_hash[:validations][:day_of_week].blank?)
  end

  def check_behavior
    errors.add(:behavior, I18n.t('deployment_window.validations.behavior.cannot_change')) if behavior_changed?
  end

  def duration_overlap?
    dates_present? && ((self.finish_at - self.start_at) < duration)
  end

  def start_in_past_date?
    dates_present? && self.start_at.to_date < DateTime.now.to_date
  end

  def start_in_past_time?
    start_in_past? && self.start_at.to_date == DateTime.now.to_date
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

  def finish_before_past_time?
    dates_present? && dates_equal? && duration_upon_day < 0
  end

  def finish_before_past_date?
    dates_present? && self.finish_at.to_date < self.start_at.to_date
  end

  def finish_equal_start?
    dates_present? && self.start_at.to_i == self.finish_at.to_i
  end

  def dates_equal?
    dates_present? && self.start_at.to_date == self.finish_at.to_date
  end

  def editable?
    !in_past?
  end

  def dates_present?
    self.start_at && self.finish_at
  end

  def check_duration
    errors.add(:base, 'Recurrent setup is invalid. Please check From, To and Duration') if duration <= 0
  end

  def schedule_rule
    self.schedule.rrules.first if self.schedule && recurrent?
  end

  def view_frequency
    return if non_recurrent?
    schedule_rule.to_ical.match(/FREQ=(\w*)/) { $1.downcase.camelize }
  end

  def rrule_description
    return if non_recurrent?
    case self.frequency_description
    when 'Daily'
      'Every day'
    when 'Weekly'
      'Every week'
    when 'Monthly'
      'Every month'
    else
      self.frequency_description
    end
  end

  def send_notification
    self.requests.each { |request| Notifier.delay.series_with_requests_update(request, self) }
  end

  def self.orderable_column_names
    self.column_names
  end

  def validator
    DeploymentWindow::SeriesValidator.new(self)
  end

  def frequency_hash
    return unless frequency
    @frequency_hash ||= (frequency.is_a?(String) ? JSON.parse(frequency) : frequency).deep_symbolize_keys
  end

  def quick_delete_occurrences
    occurrences_ids = occurrences.pluck('deployment_window_occurrences.id')
    event_ids       = events_to_delete(occurrences_ids).pluck('deployment_window_events.id')

    DeploymentWindow::Event.delete_all_by_id event_ids
    DeploymentWindow::Occurrence.delete_all_by_id occurrences_ids
  end

  def quick_delete
    quick_delete_occurrences
    self.delete
  end

  def delete_occurrences_not_finished_and_their_events
    occurrences_ids = occurrences.not_finished.pluck('deployment_window_occurrences.id')
    event_ids       = events_to_delete(occurrences_ids).pluck('deployment_window_events.id')

    DeploymentWindow::Event.delete_all_by_id event_ids
    DeploymentWindow::Occurrence.delete_all_by_id occurrences_ids
  end

  def delete_events_by_environment_ids(environment_ids)
    occurrences_ids = occurrences.not_finished.pluck('deployment_window_occurrences.id')
    event_ids       = events_to_delete(occurrences_ids, environment_ids).pluck('deployment_window_events.id')

    DeploymentWindow::Event.delete_all_by_id event_ids
  end

  def environments_changed?
    environment_ids_old != environment_ids_new
  end

  def environment_ids_old
    occurrence_ids = occurrences.not_finished.pluck('deployment_window_occurrences.id')
    @environment_ids_old ||= events.filter_by_occurrence_ids(occurrence_ids).pluck(:environment_id).uniq.sort
  end

  def environment_ids_new
    @environment_ids_new ||= (environment_ids || []).sort
  end

  def non_recurrent_changed?
    previous_changes.include?('finish_at') || previous_changes.include?('start_at') || previous_changes.include?('recurrent')
  end

  def recurrent_changed?
    non_recurrent_changed? || previous_changes.include?('duration_in_days') || frequency_changed?
  end

  def environment_ids_to_delete
    self.environment_ids_old - self.environment_ids_new
  end

  def environment_ids_to_create
    self.environment_ids_new - self.environment_ids_old
  end

  # make series not editable (until occurrences are built)
  def lock!
    self.update_column(:occurrences_ready, false)
  end

  def unlock!
    self.update_column(:occurrences_ready, true)
  end

  def schedule_from(time)
    return unless frequency
    schedule = IceCube::Schedule.new(time)
    schedule.add_recurrence_rule RecurringSelect.dirty_hash_to_rule(frequency)
    schedule.duration = duration
    schedule
  end

  def check_if_destroyable
    archived?
  end

  def active_requests
    requests.functional.active
  end

  def schedule_data
    [ json_string: String.new(self.schedule_rule.to_json) ]
  end

  private

  def update_schedule
    if frequency
      self.schedule = schedule_from(self.start_at)
      self.frequency_name = self.schedule_rule.class.name.match(/Daily|Weekly|Monthly/)[0] || '-'
      self.frequency_description = self.schedule_rule.to_s
    end
  end

  def set_time
    if self.finish_at.nil? && self.start_at.nil? && errors.empty?
      time = Time.at((Time.zone.now.to_f / ROUND_TIME_TO).round * ROUND_TIME_TO)
      time = (time + 30.minutes) if time < Time.zone.now
      self.start_at = time
      self.finish_at = time + ROUND_TIME_TO
    end
  end

  def self.time_for_filter(filter_value)
    Time.parse(filter_value).to_s(:db)
  end

  def events_to_delete(occurrence_ids, environment_ids = nil)
    result = self.events.filter_by_occurrence_ids(occurrence_ids)
    result = result.filter_by_environment_ids(environment_ids) unless environment_ids.nil?
    result
  end

  def frequency_changed?
    return unless previous_changes.has_key?(:schedule)
    recurrence      = previous_changes[:schedule].first.recurrence_rules[0]
    recurrence_was  = previous_changes[:schedule].last.recurrence_rules[0]

    recurrence != recurrence_was
  end

  def prevent_update_for_archived_entities
    if self.archived? && !self.archived_at_changed?
      self.errors[:base] << I18n.t('cannot_edit_archived', model_name: "Deployment Window")
      false
    else
      true
    end
  end

end
