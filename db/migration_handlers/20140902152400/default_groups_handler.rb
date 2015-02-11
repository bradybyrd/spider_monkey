class DefaultGroupsHandler < BaseHandler

  def apply
    create_groups
    assign_users
  end

  def revert
    user_role_groups = ActiveRecord::Base.connection.select_all <<-SQL
      select ug.user_id, r.name
      from roles r
        inner join group_roles gr on r.id = gr.role_id
        inner join user_groups ug on ug.group_id = gr.group_id
        inner join groups g on g.id = gr.group_id
      where upper(g.name) in (#{get_default_group_names_sql})
    SQL

    user_roles = {}
    user_role_groups.each do |row|
      user_roles[row['user_id']] ||= []
      user_roles[row['user_id']] << to_old_role(row['name']).gsub(ADMIN_SUFFIX, '')
    end

    user_roles.each do |user_id,roles|
      roles_sql = roles.to_yaml
      ActiveRecord::Base.connection.execute <<-SQL
        update users set old_roles = '#{roles_sql}' where id = #{user_id}
      SQL
    end

    remove_groups
  end

  private

  def assign_users
    user_roles = ActiveRecord::Base.connection.select_all <<-SQL
      select id, old_roles, admin, root from users
    SQL

    user_roles.each do |row|
      next if row['old_roles'].blank?
      user_id = row['id']
      old_roles = YAML.load(row['old_roles'])
      old_roles.each do |old_role|
        old_role_to_use = is_admin?(row) ? "#{old_role}#{ADMIN_SUFFIX}" : old_role
        group_name = to_group_name(to_role_name(old_role_to_use))
        group_id = GroupSQL.get_group_id(group_name)
        SQLHelper.insert('user_groups', {user_id: user_id, group_id: group_id, time: true})
      end
    end
  end

  def is_admin?(row)
    if PostgreSQLAdapter
      "'#{row['admin']}'" == ActiveRecord::Base.connection.quoted_true
    elsif OracleAdapter
      row['admin'] == 1
    else
      "#{row['admin']}" == ActiveRecord::Base.connection.quoted_true
    end
  end  

  def create_groups
    default_team_id = TeamSQL.create_default_team(TeamGroupsHandler::DEFAULT_TEAM_ID)
    ROLES_HASH.values.each do |role_name|
      next if PERMANENT_ROLES.include? to_old_role(role_name)
      group_id = SQLHelper.insert('groups', {name: "#{to_group_name(role_name)}", active: true, time: true}, true)
      role_id = RoleSQL.get_role_id(role_name)
      SQLHelper.insert('group_roles', {group_id: group_id, role_id: role_id, time: true})
    end
  end

  def remove_groups
    group_ids = ActiveRecord::Base.connection.select_values <<-SQL
      select id from groups where upper(name) in (#{get_default_group_names_sql})
    SQL
    return if group_ids.empty?
    ActiveRecord::Base.connection.execute <<-SQL
      delete from group_roles where group_id in (#{group_ids.join(",")})
    SQL
    ActiveRecord::Base.connection.execute <<-SQL
      delete from groups where id in (#{group_ids.join(",")})
    SQL
  end

  def get_default_group_names_sql
    default_groups = []
    ROLES_HASH.keys.each{|key| default_groups << "'#{to_group_name(to_role_name(key)).upcase}'" unless PERMANENT_ROLES.include?(key.to_s)}
    default_groups.join(",")
  end
end