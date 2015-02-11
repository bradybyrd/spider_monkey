################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################
require 'permission_scope'

class Request < ActiveRecord::Base
  include PermissionScope

  scope :exclude_templates, where("requests.request_template_id IS NULL")
  scope :functional, where("requests.request_template_id IS NULL AND requests.aasm_state <> ?", 'deleted')
  scope :template, where("requests.request_template_id IS NOT NULL AND requests.aasm_state <> ?", 'deleted')
  scope :extant, where("requests.aasm_state <> ?", 'deleted')

  scope :unscheduled, where('requests.scheduled_at IS NULL').order('created_at desc')
  scope :active, where(:aasm_state => %w(planned started))
  scope :complete, where(:aasm_state => 'complete').order('completed_at desc')
  scope :cancelled, where(:aasm_state => 'cancelled').order('cancelled_at desc')
  scope :in_progress, where("requests.aasm_state <> ?", 'created')
  scope :promotions, where(:promotion => true)

  def self.in_state(state)
    if state.is_a?(Array) && state.size == 1 && state.first.eql?('active')
      where('requests.aasm_state not in (?,?,?)', 'complete', 'cancelled', 'deleted')
    elsif state == "all"
      where('requests.aasm_state <> ?','created')
    else
      where('requests.aasm_state' => state)
    end
  end

  scope :complete_or_cancelled, where("requests.aasm_state IN ('complete', 'cancelled')")

  scope :from_time_until_now, lambda {|start| where(:completed_at => (Date.generate_from(start).to_time.beginning_of_day.in_time_zone..Time.zone.now)) }
  scope :cancelled_from_time_until_now, lambda {|start| where(:cancelled_at => (Date.generate_from(start).to_time.beginning_of_day.in_time_zone..Time.zone.now)) }

  #FIXME:TEST_ME
  scope :get_all_problematic_request, lambda {|request_id, date_hash|
     start_date = date_hash['start'].to_date
     end_date = date_hash['end'].to_date + 1
     where("(started_at BETWEEN '#{start_date}' AND '#{end_date}' AND requests.aasm_state in ('problem','hold','cancelled')) AND requests.id in (?)",request_id)
  }

  #FIXME:TEST_ME
  scope :request_by_attr_id, lambda{|filters|
       select("requests.id, apps_requests.app_id AS app_id").joins(:apps_requests).joins(:steps).where(filters)
  }

  scope :participated_in_by, lambda { |user| joins("INNER JOIN (#{user_participation_sql(nil, user, true)}) reqs ON reqs.id = requests.id") }

  scope :participated_in_directly_by, lambda { |user| #does not include group participation
                joins("INNER JOIN (#{user_participation_sql(nil, user, false)}) reqs ON reqs.id = requests.id") }

  scope :participated_in_by_group, lambda { |group| joins("INNER JOIN (#{group_participation_sql(group)}) reqs ON reqs.id = requests.id") }

  scope :having_package_contents, lambda { |packages| includes(:package_contents).where('package_contents.id' => packages) }

  scope :with_team_id, lambda { |teams| joins("INNER JOIN apps_requests ON apps_requests.request_id = requests.id ").
               joins("INNER JOIN apps ON apps.id = apps_requests.app_id ").
               joins("INNER JOIN development_teams ON development_teams.app_id = apps_requests.app_id ").
               joins("INNER JOIN teams ON teams.id = development_teams.team_id ").where("teams.id" => teams)  }

  scope :operation_tickets, lambda { |request_ids| includes(:plan_member).includes(:steps).extending(QueryHelper::WhereIn).
            where_in("requests.id", request_ids).where("steps.on_plan" => true).where("requests.request_template_id" => nil) }

  scope :requested_by, lambda { |requestor| where(:requestor_id => requestor.id) }

  # Overridden SearchLogic method
  scope :id_like, lambda { |id| where("(id+#{GlobalSettings[:base_request_number]}) LIKE ?", "%#{id}%") }

  scope :id_in, lambda { |ids| where(:id => ids)}

  # Before using below name scope, use inner_apps_requests name scope present in the same file,
  # as requests table no longer contains app_id column
  def self.name_like_or_id_like_or_notes_like_or_aasm_state_like_or_description_like_or_wiki_url_like(search_query)
    select("requests.*").where(:id => self.unique_request_ids(search_query))
  end

  scope :unique_request_ids, lambda { |search_query|
    conditional_column = PostgreSQLAdapter ? "(CAST((requests.id+#{GlobalSettings[:base_request_number]}) as TEXT))" : "(requests.id+#{GlobalSettings[:base_request_number]})"
    search_query = search_query.downcase
    select('DISTINCT requests.id as unique_id').
    joins("LEFT OUTER JOIN notes nt ON nt.object_id = requests.id AND nt.object_type = 'Request'").
    where("#{conditional_column} LIKE ? OR
                        (LOWER(requests.name) LIKE ?) OR (LOWER(requests.aasm_state) LIKE ?) OR
                        (apps_requests.app_id IN (?)) OR (requests.environment_id IN (?)) OR (requests.business_process_id IN (?)) OR
                        (requests.owner_id IN (?)) #{self.get_text_criteria}",
                        "%#{search_query}%", "%#{search_query}%", "%#{search_query}%",
                        self.request_app_id(search_query), self.request_environment_id(search_query), self.request_business_process(search_query),
                        self.request_owner(search_query), "%#{search_query}%", "%#{search_query}%", "%#{search_query}%")
  }

  scope :inbound_requests_of_user, lambda { |user| includes(:steps).where(user.inbound_request_conds) }

  scope :inbound_requests_of_user_new, lambda { |user| select('distinct(requests.id)').joins(:steps).where(user.inbound_request_conds) }

  scope :participated_by_user_and_group, lambda { |request_id|
    name = if PostgreSQLAdapter || OracleAdapter
        "u.first_name || ' ' || u.last_name"
      elsif MsSQLAdapter
        "u.first_name +  ' ' +  u.last_name"
      else
        "CONCAT(u.first_name, ' ', u.last_name)"
    end

    step_procedure = "s.#{PROCEDURE_COLUMN}"
    select("DISTINCT COALESCE(g.name, #{name}) AS name").
    joins("INNER JOIN steps s ON s.request_id = requests.id").
    joins("LEFT JOIN users u ON s.owner_type='User' AND s.owner_id=u.id").
    joins("LEFT JOIN groups g ON s.owner_type='Group' AND s.owner_id=g.id").
    where("s.request_id= #{request_id} and #{step_procedure} = #{RPMFALSE}")
  }

  scope :accessible_to_user, ->(user) {
    by_ability(:view_requests_list, user)
  }

  def self.between_dates(start_date, end_date)
    start_date = start_date.to_date if start_date.present?
    end_date = end_date.to_date if end_date.present?
    start_date = start_date.blank? ? Request.first_request_time : Date.generate_from(start_date).to_time.beginning_of_day.in_time_zone
    end_date = end_date.blank? ? (Time.now + 10.years).in_time_zone : Date.generate_from(end_date).to_time.end_of_day.in_time_zone
    coalesce_sql = 'COALESCE(requests.started_at, requests.completed_at, requests.scheduled_at, requests.target_completion_at, requests.created_at)'
    select("requests.*, #{coalesce_sql} AS order_column").
        where('( requests.started_at BETWEEN ? AND ? ) OR ( requests.completed_at BETWEEN ? AND ? ) OR '+
                  '( COALESCE(requests.started_at, requests.completed_at, requests.created_at) BETWEEN ? AND ? ) OR '+
                  '( COALESCE(requests.started_at, requests.completed_at, requests.scheduled_at) BETWEEN ? AND ? ) OR '+
                  '( COALESCE(requests.completed_at, requests.target_completion_at) BETWEEN ? AND ? ) OR'+
                  '( requests.started_at <= ?  AND  requests.completed_at >= ? ) OR '+
                  '(requests.completed_at is NULL AND requests.scheduled_at <= ? and  requests.target_completion_at >= ? ) OR'+
                  '(requests.completed_at is NULL AND requests.started_at <= ? and  requests.target_completion_at >= ? )',
              start_date, end_date, start_date, end_date, start_date, end_date, start_date, end_date, start_date, end_date, end_date, start_date, end_date, start_date, end_date, start_date)
  end

  def self.completed_in_previous_given_number_of_weeks(number_of_weeks)
    range_start = (number_of_weeks - 1).weeks.ago.beginning_of_week(:sunday)
    range_end = 0.weeks.ago.end_of_week(:sunday)

    where("completed_at IS NOT NULL AND completed_at BETWEEN ? AND ?", range_start, range_end).order('completed_at desc')
  end

  scope :completed_at_given_week, lambda { |week| where("completed_at IS NOT NULL AND completed_at BETWEEN ? AND ?", week.beginning_of_week(:sunday), week.end_of_week(:sunday)) }

  def self.completed_in_duration(start_duration, end_duration)
    start_date = Date.generate_from(start_duration).to_time.beginning_of_day.in_time_zone
    end_date = Date.generate_from(end_duration).to_time.end_of_day.in_time_zone
    where(:completed_at => (start_date..end_date))
  end

  def self.cancelled_in_duration(start_duration, end_duration)
    start_date = Date.generate_from(start_duration).to_time.beginning_of_day.in_time_zone
    end_date = Date.generate_from(end_duration).to_time.end_of_day.in_time_zone
    where(:cancelled_at => (start_date..end_date))
  end

  def self.started_in_duration(start_duration, end_duration)
    start_date = Date.generate_from(start_duration).to_time.beginning_of_day.in_time_zone
    end_date = Date.generate_from(end_duration).to_time.end_of_day.in_time_zone
    where(:started_at => (start_date..end_date))
  end

  def self.planned_in_duration(start_duration, end_duration)
    start_date = Date.generate_from(start_duration).to_time.beginning_of_day.in_time_zone
    end_date = Date.generate_from(end_duration).to_time.end_of_day.in_time_zone
    where(:planned_at => (start_date..end_date))
  end

  def self.deleted_in_duration(start_duration, end_duration)
    start_date = Date.generate_from(start_duration).to_time.beginning_of_day.in_time_zone
    end_date = Date.generate_from(end_duration).to_time.end_of_day.in_time_zone
    where(:deleted_at => (start_date..end_date))
  end

  # capitalized as proper constants and expanded list of id scopes
  COLUMNS_FOR_NAMED_SCOPES = %w(release_id environment_id business_process_id activity_id owner_id requestor_id request_template_id server_association_id plan_member_id)
  COLUMNS_FOR_NAMED_SCOPES.each { | id_column |
    scope "with_#{id_column}".to_sym, lambda { |given_id| where("requests.#{id_column}" => given_id) }
  }

  # new scopes for a name search and a number search
  scope :with_name, lambda { |name| where(["LOWER(requests.name) = ?", name.downcase]) }
  scope :with_number, lambda { |number| where(["(id+#{GlobalSettings[:base_request_number]}) = ?", number]) }

  scope :with_app_id, lambda { |app_id| joins("INNER JOIN apps_requests ar ON ar.request_id = requests.id").where("ar.app_id" => app_id) }

  scope :present, where("requests.aasm_state not in (?,?,?)", 'complete', 'cancelled', 'deleted')

  scope :with_server_id, lambda { |server_id|
    joins("INNER JOIN steps st ON st.request_id = requests.id" +
        " INNER JOIN servers_steps ss ON ss.step_id = st.id "+
        "INNER JOIN servers s ON ss.server_id = s.id").
    where("s.id" => server_id)
  }

  scope :with_env_id, lambda { |env_id|
    where("requests.environment_id" => env_id)
  }

  def self.active(*args)
    present
  end

  def self.automatic_ready_to_start
    now = Time.zone.now
    lower_bound = now.beginning_of_quarter_hour
    upper_bound = now.end_of_quarter_hour
    where('requests.auto_start = ? AND requests.scheduled_at BETWEEN ? AND ? AND requests.aasm_state IN (?)',
                      true, lower_bound, upper_bound, %w(planned hold))
  end

  scope :requests_with_no_stage, lambda { |plan_id|
    joins("INNER JOIN plan_members ON plan_members.id  = requests.plan_member_id").
    joins(" INNER JOIN plans ON plan_members.plan_id = plans.id").
    where("plans.id = ? AND plan_members.plan_stage_id = 0", plan_id) }

  scope :in_stage_of_plan, lambda { |plan_id, stage_id|
    joins("INNER JOIN plan_members ON plan_members.id = requests.plan_member_id ").
    joins("INNER JOIN plans ON plans.id = plan_members.plan_id").
    where("plan_members.plan_stage_id = ? AND plans.id = ?", stage_id, plan_id) }

  scope :in_assigned_apps_of, lambda { |user| joins("INNER JOIN (SELECT DISTINCT request_id FROM apps_requests " +
               "INNER JOIN assigned_apps ON assigned_apps.app_id = apps_requests.app_id " +
               "WHERE user_id = #{user.id}) r ON r.request_id = requests.id") }

  scope :via_team, where("team_id IS NOT NULL")

  scope :inner_apps_requests, joins(:apps_requests)

  def self.steps_assigned_to_user_including_group(user_id)
     # step_request_ids = Step.owned_by_user_including_groups(user_id).map(&:request_id)
     # where("requests.id in (?)", step_request_ids)

     where("requests.id IN "+
        "((SELECT steps.request_id FROM steps WHERE steps.owner_id IN ( #{user_id.join(", ")} ) AND steps.owner_type = 'User') " +
        "UNION  " +
        "(SELECT steps.request_id FROM steps where steps.owner_id IN " +
        "(SELECT user_groups.group_id FROM user_groups WHERE user_groups.user_id IN ( #{user_id.join(", ")} ) ) " +
        "AND steps.owner_type = 'Group'))")
  end

  scope :aasm_state_equals, lambda{|val|
    where(:aasm_state => val)
  }

  #Changed for report(display only 250 records if requests are more than 1000 and display only 250 requests)
  ORACLE_IN_LIMIT = 1000
  RECORD_DISPLAY_LIMIT = 250

  scope :id_equals, lambda{ |ids|
    #where(:id => ids)
    if ids.size > ORACLE_IN_LIMIT
      ids = ids.in_groups_of(RECORD_DISPLAY_LIMIT)
      where(:id => ids[0])
    else
    where(:id => ids)
    end
  }

  def self.by_plan_run(plan_run_id)
    plan_member_id = PlanMember.find_all_by_run_id(plan_run_id).map(&:id)
    Request.where("requests.plan_member_id in (?)", plan_member_id)
  end

  scope :by_plan_id_and_plan_stage_id, lambda  { |plan_id, plan_stage_id|
    joins(:plan_member).where('plan_members.plan_id' => plan_id,
                              'plan_members.plan_stage_id' => plan_stage_id) }

  scope :include_apps, includes(:apps)
  scope :in_most_recent_order,  order('requests.updated_at DESC').limit(25)
  scope :by_deployment_window_series, ->(deployment_window_series_ids) do
    joins(:deployment_window_event => {:occurrence => :series})
      .where("deployment_window_series.id in (?)", deployment_window_series_ids)
  end
  scope :without_event,->{where(:deployment_window_event_id => nil)}
  scope :by_deployment_window_event, ->(deployment_window_event_id) { where deployment_window_event_id: deployment_window_event_id }

  #FIXME:TEST_ME
  def self.by_step_group(group_id)
    step_request_ids=Step.owned_by_group(group_id).map(&:request_id)
    where("requests.id in (?)", step_request_ids)
  end

  # moved from request.rb and revised to return a full set of filters for rest calls
  def self.filtered(filters = {}, participated_in_by=true)
    requests = self
    unless filters.blank?
      # borrow the active record truthiness function to handle varied user input
      adapter_column = ActiveRecord::ConnectionAdapters::Column

      # assume we want just functional requests unless filters[:functional]==false or someone is searching for deleted records on purpose
      if filters[:functional].present? && !adapter_column.value_to_boolean(filters[:functional])
        unless filters[:deleted_start_date].blank? || filters[:deleted_end_date].blank?
          requests = requests.functional
        end
      end

      # run through similarly named filters with this routine
      (COLUMNS_FOR_NAMED_SCOPES | %w(app_id team_id name number)).each do |attr|
        requests = requests.send("with_#{attr}", filters[attr]) unless filters[attr].blank?
      end

      requests = requests.in_progress if filters[:in_progress].present? && adapter_column.value_to_boolean(filters[:in_progress]) == true
      requests = requests.cancelled_in_duration(filters[:cancelled_start_date], filters[:cancelled_end_date]) unless filters[:cancelled_start_date].blank? || filters[:cancelled_end_date].blank?
      requests = requests.completed_in_duration(filters[:completed_start_date], filters[:completed_end_date]) unless filters[:completed_start_date].blank? || filters[:completed_end_date].blank?
      requests = requests.planned_in_duration(filters[:planned_start_date], filters[:planned_end_date]) unless filters[:planned_start_date].blank? || filters[:planned_end_date].blank?
      requests = requests.started_in_duration(filters[:started_start_date], filters[:started_end_date]) unless filters[:started_start_date].blank? || filters[:started_end_date].blank?
      requests = requests.deleted_in_duration(filters[:deleted_start_date], filters[:deleted_end_date]) unless filters[:deleted_start_date].blank? || filters[:deleted_end_date].blank?

      # original filter group copied over and modified to simply use blank test
      requests = requests.participated_in_by(filters['participated_in_by'])                     if participated_in_by && filters['participated_in_by'].present?
      requests = requests.inbound(participated_in_by)                                           if filters['inbound_outbound'] && filters['inbound_outbound'].include?('inbound_requests')
      requests = requests.outbound(participated_in_by)                                          if filters['inbound_outbound'] && filters['inbound_outbound'].include?('outbound_requests')
      requests = requests.in_state(Array(filters['aasm_state']).collect { |s| s.downcase })     unless filters['aasm_state'].blank?
      requests = requests.having_package_contents(filters['package_content_id'])                unless filters['package_content_id'].blank?
      requests = requests.steps_assigned_to_user_including_group(Array(filters['assignee_id'])) unless filters['assignee_id'].blank?
      requests = requests.by_step_group(filters['group_id'])                                    unless filters['group_id'].blank?
      requests = requests.by_plan_run(filters['plan_run_id'])                                   unless filters['plan_run_id'].blank?
      requests = requests.by_deployment_window_event(filters['deployment_window_event_id'])     unless filters['deployment_window_event_id'].blank?

      if !filters['deployment_window_series_id'].blank? && filters['deployment_window_series_id'].include?('no_dws')
        if filters['deployment_window_series_id'] == ['no_dws']
          requests = requests.without_event
        else
          requests = Request.relation_with_no_dws(requests, filters['deployment_window_series_id'].reject { |dws| dws == 'no_dws' })
        end
      else
        requests = requests.by_deployment_window_series(filters['deployment_window_series_id']) unless filters['deployment_window_series_id'].blank?
      end

    end
    # check for safety in case bare class made it through filters
    return requests == self ? self.functional : requests
  end

  scope :on_closed_environment, -> { joins(:environment).where('environments.deployment_policy = ?', 'closed') }
  scope :with_auto_start_errors, -> { where('automatically_start_errors IS NOT NULL') }

  def self.relation_with_no_dws(requests, dws_ids)
    request_ids = requests.without_event.map(&:id) + requests.by_deployment_window_series(dws_ids).map(&:id)
    Request.scoped.extending(QueryHelper::WhereIn).where_in('requests.id', request_ids)
  end

  scope :inbound, ->(user) do
    where(request_table[:requestor_id].not_eq(user.id)).joins(:steps).
        where(step_table[:owner_type].eq('User').and((step_table[:owner_id].eq(user.id))).
           or(step_table[:owner_type].eq('Group').and((step_table[:owner_id].in(user.group_ids))))).
        extant.exclude_templates.accessible_to_user(user)
  end

  scope :outbound, ->(user) do
    where(request_table[:requestor_id].eq(user.id).
       or(request_table[:owner_id].eq(user.id))).
       extant.exclude_templates.accessible_to_user(user)
  end

  private

  def self.request_table
    Request.arel_table
  end
  private_class_method :request_table

  def self.step_table
    Step.arel_table
  end
  private_class_method :step_table

end
