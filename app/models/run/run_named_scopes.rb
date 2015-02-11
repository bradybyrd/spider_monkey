################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class Run < ActiveRecord::Base

  include FilterExt

  scope :by_aasm_state, lambda { |states| where(:aasm_state => states) }
  scope :by_name, lambda { |name| where(:name => name) }
  # functional is the same as not_deleted, but might include other states in the future like archived, cancelled, etc
  scope :functional, where('runs.aasm_state NOT IN (?)', ['deleted'])
  scope :mutable, where('runs.aasm_state IN (?)', ['planned', 'created']).order('runs.name ASC')
  scope :not_deleted, where('runs.aasm_state NOT IN (?)', ['deleted'])

  scope :by_stage, lambda {  |plan_stages| where('runs.plan_stage_id' => plan_stages) }
  scope :by_plan_ids, lambda {  |plan_ids| where('runs.plan_id' => plan_ids) }
  scope :by_plan_and_stage, lambda {  |plan_id, plan_stage_id| where('runs.plan_stage_id' => plan_stage_id).
    where('runs.plan_id' => plan_id).order("LOWER(name) asc") }

  scope :by_uppercase_name, lambda {  |lc_name| where('UPPER(runs.name) LIKE ?', lc_name.try(:upcase)) }
  scope :by_requestor, lambda { |requestor_id|  where(:requestor_id => requestor_id) }

  scope :by_owner, lambda { |owner_id| where(:owner_id => owner_id) }

  scope :by_start_at_day, lambda { |time| where('start_at >= ? AND start_at < ?',
    time.to_time.beginning_of_day, time.to_time.tomorrow.beginning_of_day)}

  scope :by_end_at_day, lambda { |time|  where('end_at >= ? AND end_at < ?',
    time.to_time.beginning_of_day, time.to_time.tomorrow.beginning_of_day) }

  scope :by_time, lambda { |time|  where('start_at <= ? AND end_at >= ?', time.to_time.utc, time.to_time.utc) }

  scope :runs_in_plan, lambda { |plan_id|
    select("runs.*").
    joins("INNER JOIN plan_stages on runs.plan_stage_id  = plan_stages.id").
    where("runs.plan_id = #{plan_id} AND runs.aasm_state in ('completed','planned', 'started', 'held', 'cancelled', 'created')").
    order("runs.plan_stage_id ASC")
  }

  is_filtered cumulative_by: {aasm_state: :by_aasm_state,
                              stage_id: :by_stage,
                              owner_id: :by_owner,
                              requestor_id: :by_requestor,
                              start_at: :by_start_at_day,
                              end_at: :by_end_at_day,
                              time: :by_time,
                              name: :by_name},
              default_flag: :all,
              specific_filter: :run_specific_filter

  def self.run_specific_filter(entities, adapter_column, filters = {})
    if (!filters[:aasm_state])
      entities.functional
    else
      entities
    end
  end

  # oracle and postgres are fussy about group_by -- oracle will not allow clob field (Rails text) in so these need to be truncated
  # and converted, oracle does not want any select fields that are not in the group by (so clobs need to be chopped there), and
  # postgres requires all fields in the select to be in the group_by.  Hence a helper function to provide those fields as needed.
  def self.groupable_fields
    return self.columns.collect{|c| (c.type == :text) ? "CAST(runs.#{c.name} AS varchar(4000))" : "runs.#{c.name}" }.join(", ")
  end

end
