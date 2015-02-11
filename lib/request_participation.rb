################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module RequestParticipation

  def is_request_associated_with_user?(request, user, include_groups = true)
    #   num_rows is replaced by row_count
    #   Because connection.execute(sql).methods.include?('num_rows') == false
    res = connection.select_rows("SELECT count(distinct id) from (#{user_participation_sql(request, user, include_groups)}) temp")
    res[0][0] > 0
  end

  def user_participation_sql(request, user, include_groups)
    user_id = user.is_a?(User) ? user.id : user
    request_id = request.is_a?(Request) ? request.id : request.to_i
    request_check = request ? " r.id = :request_id AND " : ""

    should_include_groups = include_groups ? " UNION
                SELECT r.id FROM requests r, steps s, users u
                LEFT OUTER JOIN user_groups ON user_groups.user_id = u.id
                LEFT OUTER JOIN groups ON user_groups.group_id = groups.id
                WHERE (#{request_check} r.id = s.request_id AND s.owner_id = groups.id AND s.owner_type = 'Group' AND u.id = :user_id) " : ""

    params = { :user_id => user_id }
    params.update(:request_id => request_id) if request

    sql_string = "SELECT r.id FROM requests r WHERE (#{request_check} r.deployment_coordinator_id = :user_id)
      UNION SELECT r.id FROM requests r WHERE (#{request_check} r.requestor_id = :user_id)
        UNION SELECT r.id FROM requests r, steps s WHERE (#{request_check} r.id = s.request_id AND s.owner_id = :user_id AND s.owner_type = 'User')
        #{should_include_groups}"

    str = sanitize_sql_array([sql_string, params])
    str
  end

  def group_participation_sql(group)
    group_id = group.is_a?(Group) ? group.id : group.to_i

    sql_string = %Q(
    SELECT r.id FROM requests r, steps s
    WHERE (r.id = s.request_id AND s.owner_id = :group_id AND s.owner_type = 'Group')
    )

    sanitize_sql_array([sql_string, { :group_id => group_id }])
  end

  def request_view_step_headers_sql(request, step_ids=nil)
    # FIXME, Manish, 28 Nov 11, DB adapter specific code to be refactored. Pass this as-is and let the Request model take care of creating assigned_to value.
    # Another request to fix this as it tangled with the new task model as well and is VERY fragile
    if PostgreSQLAdapter || OracleAdapter
      name = "u.first_name || ' ' || u.last_name"
    elsif MsSQLAdapter
      name = "u.first_name +  ' ' +  u.last_name"
    end

    sql = "select s.id  as id, s.position, s.aasm_state as status, s.name, c.name as component, t.name as work_task,
      COALESCE(g.name,#{name}) AS assigned_to, s.component_version
      from steps s
          LEFT JOIN components c ON s.component_id=c.id
          LEFT JOIN work_tasks t ON s.work_task_id=t.id
          LEFT JOIN users u ON s.owner_type='User' AND s.owner_id=u.id
          LEFT JOIN groups g ON s.owner_type='Group' AND s.owner_id=g.id
      WHERE
      s.request_id= :request_id"
    params = {:request_id => request.id}
    if !step_ids.blank?
      sql += " AND s.id IN(:step_ids)"
      params.update({:step_ids => step_ids.join(',')})
    end
    sanitize_sql_array([sql, params])
  end

  def get_server_names_for_steps(step_ids)
    Step.scoped.extending(QueryHelper::WhereIn)
      .joins("INNER JOIN servers_steps ON servers_steps.step_id = steps.id")
      .select('servers_steps.step_id')
      .select('steps.name')
      .where_in('servers_steps.step_id', step_ids.uniq)
  end
end
