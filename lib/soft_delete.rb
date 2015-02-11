################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module SoftDelete
  def self.included(target)
    if target.column_names.include?("name")
      target.scope :active, target.where(:active => true).order("#{target.table_name}.name")
      target.scope :inactive, target.where(:active => false).order("#{target.table_name}.name")
    else
      target.scope :active, target.where(:active => true)
      target.scope :inactive, target.where(:active => false)
    end
  end

  def activate!
    self.update_attribute(:active, true) && after_activate
  end

  def deactivate!
    if before_deactivate_hook
      self.update_attribute(:active, false) && after_deactivate
    else
      false
    end
  end

  def before_deactivate_hook
    true
  end

  def after_activate
    true
  end

  def after_deactivate
    true
  end

  def destroyable?
    return false if self.active

    associations.all? { |assoc| self.send(assoc).empty? }
  end

  def used_by
    associations.map { |assoc| self.send(assoc).map { |assoc| assoc.name if assoc.respond_to?(:name) } }.compact.flatten
  end

protected

  def associations
    @associations ||= self.class.reflect_on_all_associations.select { |assoc| assoc.macro == :has_many || assoc.macro == :has_and_belongs_to_many }.map { |assoc| assoc.name if assoc.respond_to?(:name) }
  end
end
