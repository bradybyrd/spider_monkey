################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2013
# All Rights Reserved.
################################################################################

module OwningGroup

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

    def acts_as_owning_group
      # don't allow multiple calls
      #return if self.included_modules.include?(OwningGroup::InstanceMethods)

      parent_obj = self.to_s
      table_name = parent_obj.underscore.pluralize

      belongs_to :owner_group, :class_name => 'Group'

      attr_accessible :owner_group, :owner_group_id

      #scope :all_visible
      scope :owning_groups, ->(group_ids = []) { where owner_group_id: group_ids }

      #validate :owning_group_acceptable

      #include OwningGroup::InstanceMethods
    end
  end

  #module InstanceMethods
  #  def owning_group_and_resource_except_users_acceptable
  #    errors.add(:owning_group, "Owning group bla-bla-bla") if !all_is_good_with_group
  #  end
  #end
end
