################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ResourceAllocation < ActiveRecord::Base
  extend AllocationHelpers

  belongs_to :allocated, :polymorphic => true

  validates :allocated_id,:presence => true
  validates :allocated_type,:presence => true
  validates :year,
            :presence => true,
            :numericality => {:only_integer => true}
  validates :month,
            :presence => true,
            :inclusion => {:in => 1..12}
  validates :allocation,
            :presence => true,
            :inclusion => { :in => 0..100, :message => 'must be between 0 and 100.'}

  def self.month_range_names(months_ago, months_from_now)
    Date.act_on_month_range(months_ago, months_from_now) { |month| months_hash[month] }
  end

  def self.allocation_pivot(group_id = -1)
    if group_id < 1 then
      where = ""
    else
      where = " where g.id = #{group_id} "
    end
    user_name = case AdapterName
      when "PostgreSQL", "OracleEnhanced" 
        "u.last_name || ' ' || u.first_name"
      when "MsSQL" 
        "u.last_name + ' ' + u.first_name"
      else 
        "CONCAT(u.last_name, ' ', u.first_name)"
    end     

    find_by_sql <<-SQL
      select pvt.year,  (case when u.type is null then
      #{user_name} else u.type end) as "resource",
      g.name as "group", a.name as "activity",
      pvt.alloc_id as "allocated_id", w.activity_id, w.resource_id, u.type, g.id as group_id,
      pvt.jan,
      pvt.feb,
      pvt.mar,
      pvt.apr,
      pvt.may,
      pvt.jun,
      pvt.jul,
      pvt.aug,
      pvt.sep,
      pvt.oct,
      pvt.nov,
      pvt.dec
      from (
        select
        year, max(allocated_id) as alloc_id,
        max(case when month=1 then allocation else 0 end) as jan,
        max(case when month=2 then allocation else 0 end) as feb,
        max(case when month=3 then allocation else 0 end) as mar,
        max(case when month=4 then allocation else 0 end) as apr,
        max(case when month=5 then allocation else 0 end) as may,
        max(case when month=6 then allocation else 0 end) as jun,
        max(case when month=7 then allocation else 0 end) as jul,
        max(case when month=8 then allocation else 0 end) as aug,
        max(case when month=9 then allocation else 0 end) as sep,
        max(case when month=10 then allocation else 0 end) as oct,
        max(case when month=11 then allocation else 0 end) as nov,
        max(case when month=12 then allocation else 0 end) as dec
        from resource_allocations
        group by year, allocated_id) pvt
      INNER JOIN workstreams w on w.id = pvt.alloc_id
      INNER JOIN users u on w.resource_id = u.id
      INNER JOIN activities a on w.activity_id = a.id
      INNER JOIN user_groups ug on ug.user_id = u.id INNER JOIN groups g on g.id = ug.group_id
      #{where} order by g.name, u.type, u.last_name, u.first_name, a.name, year
    SQL

  end

end
