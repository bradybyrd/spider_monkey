################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class Plan < ActiveRecord::Base

  scope :by_aasm_state, lambda { |states| where(:aasm_state => states) }
  scope :functional, where('plans.aasm_state NOT IN (?)', ['deleted', 'archived'])
  scope :without_deleted, where('plans.aasm_state NOT IN (?)', ['deleted'])
  #FIXME:DELETE_ME
  #named_scope :running, :conditions => ['lifecycles.aasm_state NOT IN (?)', ['deleted', 'archived', "complete", "cancelled"]]
  #named_scope :done, :conditions => ['lifecycles.aasm_state IN (?)', ['deleted', 'archived', "complete", "cancelled"]]
  #FIXME:TEST_ME
  scope :running, where('plans.aasm_state NOT IN (?)', ['deleted', 'archived', 'complete', 'cancelled'])
  scope :done, where('plans.aasm_state IN (?)', ['deleted', 'archived', 'complete', 'cancelled'])
  scope :not_deleted, where('plans.aasm_state NOT IN (?)', ['deleted'])
  scope :deleted, where(:aasm_state => "deleted")
  scope :archived, where(:aasm_state  => "archived")
  scope :problem, where(:aasm_state => 'problem')
  scope :having_release_date, where('plans.release_date IS NOT NULL')
  scope :by_uppercase_name, lambda {  |lc_name| where('UPPER(plans.name) LIKE ?', lc_name.try(:upcase)) }
  scope :not_including_id, lambda { |lc_id| where('plans.id <> ?', lc_id) }
  scope :by_plan_template_type, lambda { |template_type| joins(:plan_template).where("plan_templates.template_type" => template_type)  }
  scope :by_plan_template, lambda { |plan_template_ids| where("plan_template_id" => plan_template_ids) }

  scope :by_stage, lambda { |stages| select(Plan.groupable_fields).joins(:plan_template => :stages).where('plan_stages.id' => stages) }

  scope :by_release_date, lambda { |release_date|  where(:release_date => release_date) }
  scope :by_name, lambda { |plan_name|  where(:name => plan_name) }

  scope :by_release, lambda { |releases|  where(:release_id => releases)  }

  scope :by_release_manager, lambda { |release_managers|  where(:release_manager_id => release_managers) }

  scope :by_team, lambda { |teams| select(Plan.groupable_fields).joins(:plan_teams).
                                   where('plan_teams.team_id' => teams) }

  scope :by_application, lambda { |applications| select(Plan.groupable_fields).joins(:members => { :request => :apps }).
                                                 where('apps.id' => applications) }

  scope :by_environment, lambda { |environments| select(Plan.groupable_fields).joins(:members => :request).
                                                 where('requests.environment_id' => environments) }

  scope :by_project_server_id, lambda { |project_server_id| where(:project_server_id => project_server_id)}
  scope :by_foreign_id, lambda {|f_id| where(:foreign_id => f_id)}

  # FIXME: removed the joins from this as it was returning empty because of inner joins for associated objects
  scope :preloaded_with_associations, includes(:release_manager, :teams, :release, :stage_dates)

  # FIXME: When possible, we should use 4000 varchar fields instead of the less compatible text fields in our migrations.  When that is done, this kind of test can be removed.
  # plans may be filtered on their index page, which combines a number of the named
  # scopes above and returns the final set of indexes
  def self.filtered(filters = {}, show_archived = false, entitled_plans = nil)
    plans = entitled_plans || self
    unless filters.blank?
      # always set aside deleted and archived # fix show archive
      plans = show_archived ? plans.without_deleted : plans.functional unless filters[:aasm_state]
      plans = plans.by_uppercase_name(filters[:name]) unless filters[:name].blank?
      plans = plans.by_plan_template_type(filters[:plan_type]) unless filters[:plan_type].blank?
      plans = plans.by_plan_template(filters[:plan_template_id]) unless filters[:plan_template_id].blank?
      plans = plans.by_aasm_state(filters[:aasm_state]) unless filters[:aasm_state].blank?
      plans = plans.by_stage(filters[:stage_id]) unless filters[:stage_id].blank?
      plans = plans.by_release(filters[:release_id]) unless filters[:release_id].blank?
      plans = plans.by_release_manager(filters[:release_manager_id]) unless filters[:release_manager_id].blank?
      plans = plans.by_team(filters[:team_id]) unless filters[:team_id].blank?
      plans = plans.by_application(filters[:app_id]) unless filters[:app_id].blank?
      plans = plans.by_environment(filters[:environment_id]) unless filters[:environment_id].blank?
      plans = plans.by_release_date(filters[:release_date]) unless filters[:release_date].blank?
      plans = plans.by_foreign_id(filters[:foreign_id]) unless filters[:foreign_id].blank?
      plans = plans.by_project_server_id(filters[:project_server_id]) unless filters[:project_server_id].blank?

      # now apply any ordering from the filters

      if filters[:sort_scope].present?
        if (filters[:sort_scope] == "release_name") || (filters[:sort_scope] == "plan_template_name") ||(filters[:sort_scope] == "plan_template_type")
          plans = Plan.where(:id => plans.map(&:id)).sorted_by(filters[:sort_scope], filters[:sort_direction] == 'asc')
        else
          plans = plans.sorted_by(filters[:sort_scope], filters[:sort_direction] == 'asc')
        end
      end
    else
      plans = show_archived ? plans.without_deleted.sorted : plans.functional.sorted
    end
    return plans
  end

  # oracle and postgres are fussy about group_by -- oracle will not allow clob field (Rails text) in so these need to be truncated
  # and converted, oracle does not want any select fields that are not in the group by (so clobs need to be chopped there), and
  # pstgres requires all fields in the select to be in the group_by.  Hence a helper function to provide those fields as needed.

  def self.groupable_fields
    return self.columns.collect{|c| c.type == :text && (PostgreSQLAdapter || OracleAdapter) ? "CAST(plans.#{c.name} AS varchar(4000))" : "plans.#{c.name}" }.join(", ")
  end

  def self.entitled(user)
    # TODO: should be clarified
    if user.in_root_group? || user.can?(:list, Plan.new)
      self.includes([:release, :plan_template])
    else
      select(Plan.groupable_fields)
      .includes([:release, :plan_template])
      .joins(:members)
      .where('plan_members.id' => PlanMember.entitled(user))
    end
  end

  scope :sorted, order('plans.name')

end
