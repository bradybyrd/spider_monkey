################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module HasDefault
  module ClassMethods
    def default
      order("#{self.quoted_table_name}.position").first
    end

    def default= model_or_id
      model = self === model_or_id ? model_or_id : find_by_id(model_or_id)
      model.try(:make_default!)
    end
  end

  def self.included(mod)
    mod.extend(ClassMethods)
    mod.instance_eval do
      acts_as_list
    end
  end

  def make_default!
    insert_at 1
  end

  def default?
    position == 1
  end

end
