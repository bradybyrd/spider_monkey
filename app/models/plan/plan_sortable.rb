################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
require 'sortable_model'

class Plan < ActiveRecord::Base
  
  sortable_model

  can_sort_by :name, lambda {|asc|
    order = asc ? "ASC" : "DESC"
    { :order => "plans.name #{order}" }
  }
  
  can_sort_by :aasm_state, lambda {|asc|
    order = asc ? "ASC" : "DESC"
    { :order => "plans.aasm_state #{order}" }
  }

  can_sort_by :release_date, lambda {|asc|
    order = asc ? "ASC" : "DESC"
    { :order => "plans.release_date #{order}" }
  }
  
  can_sort_by :release_name, lambda {|asc|
    order = asc ? "ASC" : "DESC"
    { :order => "releases.name #{order}",
    :include => :release }
  }
  
  can_sort_by :plan_template_name, lambda {|asc|
    order = asc ? "ASC" : "DESC"
    { :order => "plan_templates.name #{order}",
    :include => :plan_template }
  }
  
  can_sort_by :plan_template_type, lambda {|asc|
    order = asc ? "ASC" : "DESC"
    { :order => "plan_templates.template_type #{order}",
    :include => :plan_template }
  }
end