class TeamGroupsHandler < BaseHandler

  DEFAULT_TEAM_ID = Team::DEFAULT_TEAM_ID
  DEFAULT_GROUP_NAME = '[default]'

  def apply
    prepare_default_group
    team_ids = TeamSQL.get_teams
    team_ids.delete(DEFAULT_TEAM_ID)
    team_ids.each do |team_id|
      user_ids = TeamSQL.get_team_users(team_id)
        user_ids.each do |user_id|
          assign_user_in_group_to_team(team_id, user_id)
        end
    end
    process_groups_like_default
  end

  def revert
    revert_default_group
    revert_assigned_environments
  end

  def remove_assigned_app_dublicates
    duplicates = ActiveRecord::Base.connection.select_all <<-SQL
      select app_id, user_id, min(id) as min_id
      from assigned_apps
      group by app_id, user_id
      having count(*) > 1    
    SQL

    dupl_ids = []
    duplicates.each do |row|
      app_id = row['app_id']
      user_id = row['user_id']
      min_id = row['min_id']
      assigned_app_ids = ActiveRecord::Base.connection.select_values <<-SQL
        select id from assigned_apps where user_id = #{user_id} and app_id = #{app_id} and id > #{min_id}
      SQL
      dupl_ids << assigned_app_ids
    end

    unless dupl_ids.empty?
      ActiveRecord::Base.connection.execute <<-SQL
        delete from assigned_apps where #{SQLHelper::where_in('id', dupl_ids)}
      SQL
    end
  end

  private

  def revert_assigned_environments
    group_ids = ActiveRecord::Base.connection.select_values <<-SQL
      select tg.group_id 
      from team_groups tg 
        inner join team_group_app_env_roles tgaer on tgaer.team_group_id = tg.id
    SQL
    team_group_ids = ActiveRecord::Base.connection.select_values <<-SQL
      select team_group_id from team_group_app_env_roles
    SQL
    ActiveRecord::Base.connection.execute <<-SQL
      delete from team_group_app_env_roles 
    SQL
    ActiveRecord::Base.connection.execute <<-SQL
      delete from team_groups where #{SQLHelper.where_in('id', team_group_ids)}
    SQL
    ActiveRecord::Base.connection.execute <<-SQL
      delete from groups where #{SQLHelper.where_in('id', group_ids)}
    SQL
  end

  def prepare_default_group
    user_ids = TeamSQL.get_team_users(DEFAULT_TEAM_ID)
    default_name_group_id = GroupSQL.get_group_id(DEFAULT_GROUP_NAME)
    unless default_name_group_id
      default_name_group_id = SQLHelper.insert('groups', {name: DEFAULT_GROUP_NAME, active: true, time: true}, true)
    end

    GroupSQL.make_default(default_name_group_id) 
    assign_users_in_default_group_to_default_team(default_name_group_id, user_ids)  
  end

  def process_groups_like_default
    default_name_group_id = GroupSQL.get_group_id(DEFAULT_GROUP_NAME)
    position = Group::DEFAULT_GROUP_POSITION + 1
    GroupSQL.get_default_groups.each do |group_id|
      next if group_id == default_name_group_id
      GroupSQL.set_position(group_id, position)
      position += 1
    end
  end  

  def revert_default_group
    user_ids = TeamSQL.get_team_users(DEFAULT_TEAM_ID)
    user_ids.each do |user_id|
      SQLHelper.insert('teams_users', user_id: user_id, team_id: TeamGroupsHandler::DEFAULT_TEAM_ID, time: true)
    end
    GroupSQL.remove_default_group
  end


  def assign_users_in_default_group_to_default_team(group_id, user_ids)
    group_id = GroupSQL.get_group_id(DEFAULT_GROUP_NAME)
    SQLHelper.insert('team_groups', {team_id: DEFAULT_TEAM_ID, group_id: group_id, time: true}, true)
    user_ids.each do |user_id|
      SQLHelper.insert('user_groups', {user_id: user_id, group_id: group_id, time: true}) if group_id && !UserSQL.already_in_group?(user_id, group_id)
    end  
  end  

  def assign_user_in_group_to_team(team_id, user_id)
    group_id = get_group_for_user(team_id, user_id) || 
      create_group_with_env_roles(team_id, user_id)
    SQLHelper.insert('user_groups', {user_id: user_id, group_id: group_id, time: true}) if group_id && !UserSQL.already_in_group?(user_id, group_id)
  end

  def get_group_for_user(team_id, user_id)
    old_roles = RoleSQL.get_team_roles(team_id, user_id)

    return nil if old_roles.empty?

    roles = old_roles.collect{|old_role_name| "'#{to_role_name(old_role_name).upcase}'"}.uniq

    team_group_ids = ActiveRecord::Base.connection.select_values <<-SQL
      select tg.id
      from team_groups tg
        inner join group_roles gr on tg.group_id = gr.group_id
        left join roles r on gr.role_id = r.id and upper(r.name) in (#{roles.join(",")})
      where tg.team_id = #{team_id}
      group by tg.id
      having min(COALESCE(r.id, 0)) > 0 and count(gr.id) = #{roles.count}
    SQL

    team_group_id = team_group_ids.first
    group_ids = []
    if team_group_id
      group_ids = ActiveRecord::Base.connection.select_values <<-SQL
        select group_id from team_groups where id = #{team_group_id}
      SQL
    end

    group_ids.first
  end

  def create_group_with_env_roles(team_id, user_id)
    group_id = create_group(team_id)
    team_group_id = SQLHelper.insert('team_groups', {team_id: team_id, group_id: group_id, time: true}, true)
    app_ids = TeamSQL.get_team_apps(team_id)

    old_roles = RoleSQL.get_team_roles(team_id, user_id)
    assign_group_roles(group_id, old_roles)

    app_ids.each do |app_id|    
      assigned_app_id = AppSQL.get_assigned_app_id(app_id, user_id, team_id)
      next unless assigned_app_id
      RoleSQL.get_assigned_environments_with_roles(assigned_app_id).each do |row|
        role_id = (row['role'].to_i > 0) ? row['role'].to_i : RoleSQL.get_role_id(to_role_name(row['role']))
        SQLHelper.insert('team_group_app_env_roles', {
          team_group_id: team_group_id, 
          application_environment_id: AppSQL.get_app_environment_id(app_id, row['environment_id']), 
          role_id: role_id, 
          time: true 
        })
      end
    end  
    group_id
  end

  def assign_group_roles(group_id, old_role_names)
    old_role_names.each do |old_role_name|
      role_id = RoleSQL.get_role_id(to_role_name(old_role_name))
      SQLHelper.insert('group_roles', {group_id: group_id, role_id: role_id, time: true})
    end  
  end  

  def create_group(team_id)
    @group_number[team_id] ||= 0
    team_name = "#{TeamSQL.get_team_name(team_id)}#{GROUP_SUFFIX}#{@group_number[team_id] += 1}"
    SQLHelper.insert('groups', {name: team_name, active: true, time: true}, true) 
  end
end