################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class Category < ActiveRecord::Base
  include ArchivableModelHelpers
  include FilterExt

  normalize_attributes :name

  has_many :steps, :dependent => :nullify
  has_many :requests, :dependent => :nullify

  validates :name,
            :presence => true,
            :uniqueness => {:scope => :categorized_type},
            :length => {:maximum =>255}
  validates :associated_events,:presence => true
  validates :categorized_type,:presence => true

  attr_accessible :name, :categorized_type, :associated_events, :step_ids, :request_ids

  scope :step, where(:categorized_type => 'step')
  scope :request, where(:categorized_type => 'request')
  scope :name_order, order(:name)

  scope :filter_by_name, lambda { |filter_value| where(:name => filter_value) }

  is_filtered cumulative: [:name], boolean_flags: {default: :unarchived, opposite: :archived}

  def self.associated_event(event)
    if OracleAdapter
      where("REGEXP_LIKE(categories.associated_events, '(^|,)#{event}(,|$)')")
    elsif PostgreSQLAdapter || MsSQLAdapter
      where('categories.associated_events LIKE ?', "%#{event}%")
    end
  end

  def associated_events=(events)
    self[:associated_events] = events.join(',')
  end

  def associated_events
    (self[:associated_events] || '').split(',')
  end

  def human_associated_events
    associated_events.map { |event| event.humanize }.to_sentence
  end

  # returns a boolean to the before_archive hook and any view
  # that needs to decide to show or hide the archive link
  def can_be_archived?
    my_req_count = 0
    if self.categorized_type == 'request'
      my_req_count = self.requests.functional.count
    elsif self.categorized_type == 'step'
      my_req_count = count_of_existing_requests_through_step || 0
    end
    return my_req_count.to_i == 0
  end

  # destroyable if it has been archived and there child objects
  def destroyable?
    return self.archived? && self.requests.functional.blank? && self.steps.blank?
  end

end
