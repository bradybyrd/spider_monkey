################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class EnvironmentType < ActiveRecord::Base
  include FilterExt

  attr_accessible :description, :name, :position, :insertion_point, :environment_ids, :plan_stage_ids, :strict, :label_color

  validates :name, :presence => true, :uniqueness => true, :length => {:maximum => 255}
  validates :label_color, :presence => true, :inclusion => {:in => Colors::Shades.map(&:last)}
  validates :description, :length => {:maximum => 255}

  validate :has_no_plan_stage_instances_when_becoming_strict

  normalize_attribute :name, :description

  has_many :environments, :dependent => :restrict
  has_many :plan_stages, :dependent => :restrict
  has_many :plan_stage_instances, :through => :plan_stages

  # a polymorphic relationship with step_execution_conditions to act as a type of constraint on their contents
  has_many :constraints, as: :constrainable, dependent: :destroy

  # make archivable
  include ArchivableModelHelpers

  # make a list with position column unless archived
  acts_as_list :scope => 'archived_at IS NULL'

  scope :in_order, order('position')

  # this should be case sensitive as some people use development and Development as meaningful types
  scope :filter_by_name, lambda { |filter_value| where(:name => filter_value) }

  # may be filtered through REST
  is_filtered cumulative: [:name],
              boolean_flags: {default: :unarchived, opposite: :archived}


  def short_name
    name.truncate(30) unless name.blank?
  end

  def label
    message = []
    message << short_name
    message << '(Strict)' if strict
    message.join(' ')
  end

  def insertion_point
    position
  end

  def insertion_point=(new_position)
    insert_at(new_position.to_i)
  end

  # only archive if there are no related plan stages or environments
  def can_be_archived?
    self.environments.blank? && self.plan_stages.blank?
  end

  def can_be_made_strict?
    self.plan_stage_instances.blank?
  end

  def self.import_app(env_type_hash)
    unless env_type_hash["name"].blank?
      env_type = create_or_check_for_archived(env_type_hash)
      env_type.update_attributes!(env_type_hash)
      env_type
    end
  end
  
  def self.create_or_check_for_archived(env_type_hash)
    env_type = EnvironmentType.find_or_initialize_by_name(env_type_hash["name"])
    if !env_type.new_record? && env_type.archived?
      env_type.toggle_archive
    end
    env_type
  end
  
  private

  # if a plan is made strict, but has plans with non-matching types,
  # throw an error until those offending stages are recategorized
  def has_no_plan_stage_instances_when_becoming_strict
    # only test if strict has changed and is true
    if self.strict_changed? && self.strict && !self.can_be_made_strict?
      self.errors.add(:strict, "cannot be set to true at this time because plan stage instances already exist for this environment type")
    end
  end
  
end
