################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class Release < ActiveRecord::Base
  include ArchivableModelHelpers
  include FilterExt

  attr_accessible :name, :insertion_point, :request_ids, :plan_ids

  normalize_attributes :name

  has_many :requests
  has_many :plans

  validates :name,
            :presence => true,
            :uniqueness => true

  scope :in_order, order('position')
  scope :name_order, order('name asc')

  scope :filter_by_name, lambda { |filter_value| where(:name => filter_value) }

  # releases may be filtered through REST or the UI
  is_filtered cumulative: [:name], boolean_flags: {default: :unarchived, opposite: :archived}

  acts_as_list :scope => 'archived_at IS NULL'

  def insertion_point
    position
  end

  def insertion_point=(new_position)
    insert_at(new_position.to_i)
  end

  def can_be_archived?
    count_of_associated_requests == 0 && count_of_associated_request_templates == 0 && self.plans.running.count == 0
  end

  def self.import_app(xml_hash)
    if xml_hash["release"]
      name = xml_hash["release"]["name"]
      release = find_or_create_by_name(name)
      release.id
    else
      nil
    end
  end

end

