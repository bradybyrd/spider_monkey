################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class App < ActiveRecord::Base
  
  # overriding the default in SoftDelete to include the ordering
  scope :active, where(:active => true)
  scope :inactive, where(:active => false)

  scope :with_installed_components, joins(:application_environments, :installed_components).
    where('installed_components.application_environment_id = application_environments.id').uniq

  scope :with_package_templates, includes(:package_templates).where(:package_templates => {:active => true})

  scope :accessible_apps_with_installed_components, lambda { |user_id|
    select(App.groupable_fields).joins("INNER JOIN assigned_apps ON assigned_apps.app_id = apps.id").
    where("assigned_apps.user_id" => user_id).group(App.groupable_fields)    
  }
  
  scope :for_plan, lambda { |plan_id| joins(:requests => :plan_member).
      where('plan_members.plan_id' => plan_id).order("apps.name ASC").uniq
  }

  scope :via_team, where("assigned_apps.team_id IS NOT NULL")
  scope :with_direct_access, where("assigned_apps.team_id IS NULL")

  scope :with_components, includes(:application_components).where('application_components.app_id = apps.id')

  scope :name_order, order('apps.name ASC')

  scope :apps_accessible_to_user, lambda {|user_id|
    joins(:assigned_apps).where("assigned_apps.user_id" => user_id).order("apps.name ASC")
  }

  scope :accessible_to_user_for_env, lambda {|env_id|
    joins(:application_environments).where("application_environments.environment_id" => env_id).order("apps.name ASC")
  }
  
  scope :all_apps_for_tickets, select("distinct apps.name,apps.id").joins(:tickets).order("apps.name ASC")

  scope :all_apps_for_tickets_by_plan, lambda {|plan_id|
      select("distinct apps.name,apps.id").joins(:tickets => :plans).
      where("plans.id = #{plan_id}").order("apps.name ASC")
    }
  
  # allows searching by a name prefix delimited with _|_ or by the full name
  scope :by_short_or_long_name, lambda {|app_name| 
    {
      :conditions => ['apps.name like ? OR apps.name like ?', app_name, "#{app_name}_|%"]
    }
    
    }

  # apps may be filtered through REST or the UI
  is_filtered cumulative_by: {name: :by_short_or_long_name}, boolean_flags: {default: :active, opposite: :inactive}
  
  # oracle and postgres are fussy about group_by -- oracle will not allow clob field (Rails text) in so these need to be truncated
  # and converted, oracle does not want any select fields that are not in the group by (so clobs need to be chopped there), and 
  # pstgres requires all fields in the select to be in the group_by.  Hence a helper function to provide those fields as needed.
  # DEFAULT is an oracle keyword and must be quoted and upper cased which will fail on postgress, so I am chosing not to show it
  def self.groupable_fields
    return self.columns.reject { |c| DATABASE_RESERVED_WORDS.include?(c.name.upcase) }.collect{|c| c.type == :text && (PostgreSQLAdapter || OracleAdapter) ? "CAST(apps.#{c.name} AS varchar(4000))" : "apps.#{c.name}" }.join(", ")
  end
end
