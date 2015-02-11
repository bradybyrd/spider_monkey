################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class WorkTask < ActiveRecord::Base
  include ArchivableModelHelpers
  include FilterExt

  normalize_attributes :name
  has_many :steps

  has_many :property_work_tasks, :dependent => :destroy
  has_many :properties, :through => :property_work_tasks

  validates :name,
            :presence => true,
            :uniqueness => true

  scope :in_order, order('position')

  acts_as_list :scope => 'archived_at IS NULL'

  attr_accessible :name, :insertion_point

  scope :filter_by_name, lambda { |filter_value| where("LOWER(work_tasks.name) like ?", filter_value.downcase) }

  # may be filtered through REST
  is_filtered cumulative: [:name], boolean_flags: {default: :unarchived, opposite: :archived}

  def insertion_point
    position
  end

  def insertion_point=(new_position)
    insert_at(new_position.to_i)
  end

  def can_be_archived?
    (count_of_existing_requests_through_step == 0)  && (count_of_request_templates_through_steps == 0) \
    && (count_of_procedures_through_steps ==0)  && self.property_work_tasks.blank?
  end

  def self.import_app(xml_hash)
   if (xml_hash["work_task"])
     worktask =  WorkTask.where(name: xml_hash["work_task"]["name"]).first_or_create
     worktask.id
   end
  end

end

