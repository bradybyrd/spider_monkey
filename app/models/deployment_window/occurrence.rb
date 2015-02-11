################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class DeploymentWindow::Occurrence < ActiveRecord::Base
  belongs_to :series
  has_many :events, dependent: :destroy
  has_many :environments, through: :events, uniq: true
  self.per_page = 20
  delegate :name, :behavior, to: :series

  attr_accessor :environment_ids, :behavior, :name
  attr_accessible :state, :finish_at, :position, :start_at, :environment_ids, :environment_names, :behavior, :name

  validates_uniqueness_of :position, scope: :series_id

  after_initialize ->{ self.state ||= CREATED } # default state
  after_save :build_events

  scope :filter, ->(filters = {}) do
    filters[:complicated].reduce(scoped.where(filters[:simple])) { |result, arel| result.where arel }
  end

  scope :not_started, -> { where 'deployment_window_occurrences.start_at > ?', Time.zone.now + 10.seconds }
  scope :not_finished, ->{ where 'deployment_window_occurrences.finish_at > ?', Time.zone.now }
  scope :passed, ->      { where 'deployment_window_occurrences.finish_at < ?', Time.zone.now }

  STATES = [
              CREATED = 'created',
              EVENT_MOVED = 'event_moved',
              MOVED = 'moved'
           ]

  STATES.each do |state|
    scope state, ->{ where(state: state) }
    scope "non_#{state}", ->{ where(state: STATES - [state]) }
  end

  def self.delete_all_by_id(occurrences_ids = [])
    DeploymentWindow::Occurrence.scoped.extending(QueryHelper::WhereIn).
        where_in('deployment_window_occurrences.id', occurrences_ids).delete_all if occurrences_ids.count > 0
  end

  def duration
    (self.finish_at - self.start_at).round
  end

  def self.orderable_column_names
    self.column_names
  end

  def prev
    series.occurrences.where('start_at < ?', self.start_at).last
  end

  def next
    series.occurrences.where('start_at > ?', self.start_at).first
  end

  def in_past?
    dates_present? && self.finish_at < DateTime.now
  end

  def dates_present?
    self.start_at && self.finish_at
  end

  def event(environment_id)
    events.find_by_environment_id( environment_id )
  end

  private

  def build_events
    DeploymentWindow::Event.import(environment_ids.map do |environment_id|
      DeploymentWindow::Event.new(occurrence_id: self.id,
                                  environment_id: environment_id,
                                  start_at: start_at,
                                  finish_at: finish_at,
                                  environment_names: self.environment_names,
                                  name: self.name,
                                  behavior: self.behavior)
    end)
  end

end
