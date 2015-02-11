################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class PlanTemplate < ActiveRecord::Base

  scope :by_uppercase_name, lambda {  |plan_template_name| where('UPPER(plan_templates.name) LIKE ?', plan_template_name.try(:upcase)) }
  scope :sorted, order('name')

  is_filtered cumulative_by: {name: :by_uppercase_name}, boolean_flags: {default: :unarchived, opposite: :archived}

  def self.entitled(user)
    self
  end

end
