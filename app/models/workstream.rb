################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class Workstream < ActiveRecord::Base
  include AllocationHelpers

  belongs_to :resource, :class_name => 'User'
  belongs_to :activity

  has_many :resource_allocations, :as => :allocated, :dependent => :destroy

  validates :resource_id, :presence => true
  validates :activity_id, 
            :presence => true,
            :uniqueness => {:scope => :resource_id}
  
  delegate :name,       :to => :activity,                   :allow_nil => true
  delegate :name,       :to => :resource, :prefix => true
  delegate :role_names, :to => :resource, :prefix => true

  def allocation_for_year_and_month(year, month)
    resource_allocations.find_by_year_and_month(year, month).try(:allocation) || 0
  end

  def allocations_for_month_range(months_ago, months_from_now)
    Date.act_on_month_range(months_ago, months_from_now) do |month, year|
      allocation_for_year_and_month(year, month)
    end
  end

  def update_allocation(year, month, alloc)
    resource_allocation = resource_allocations.find_or_initialize_by_year_and_month(year, month)
    resource_allocation.allocation = alloc
    resource_allocation.save!
    resource_allocations(true)
  end
end
