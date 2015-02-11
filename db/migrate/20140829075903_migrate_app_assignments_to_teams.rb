class MigrateAppAssignmentsToTeams < ActiveRecord::Migration
  class User < ActiveRecord::Base
  end

  class Team < ActiveRecord::Base
    attr_accessible :name
  end

  NAME = 'Automatically created Team'

  def initialize
    super
    @team_num = 0
    @current_time = Time.current.to_formatted_s(:db)
    User.reset_column_information
    Team.reset_column_information
  end

  def up
    User.find_each do |user|
      next unless has_assigned_apps?(user.id)

      assigned_apps_rows = assigned_apps(user.id)
      app_ids = assigned_apps_rows.map {|row| row['app_id']}

      team = find_team_with_apps(app_ids)
      team = create_team_with_apps(app_ids) if team.blank?

      assign_user_to_team(team.id, user.id)
      assigned_apps_rows.each do |row|
        reassign_to_team(row['id'], team.id)
      end
    end
  end

  def down
    ActiveRecord::Base.connection.execute <<-SQL
      update assigned_apps set team_id = null
      where team_id is not null and
            exists(select t.id from teams t where t.id = assigned_apps.team_id and t.name like '#{NAME}%')
    SQL

    Team.where("name like ?", "#{NAME}%").destroy_all
  end

  def has_assigned_apps?(user_id)
    assigned_apps(user_id).size > 0
  end

  def assigned_apps(user_id)
    ActiveRecord::Base.connection.select_all <<-SQL
      select * from assigned_apps where team_id is null and user_id=#{user_id}
    SQL
  end

  def create_team_with_apps(app_ids)
    name = next_name
    team = Team.create(name: name)
    app_ids.each do |app_id|
      assign_app_to_team(app_id, team.id)
    end
    team
  end

  def assign_app_to_team(app_id, team_id)
    ActiveRecord::Base.connection.execute <<-SQL
      insert into development_teams (#{id_field} app_id, team_id, created_at, updated_at)
      values (#{id_value('development_teams')} #{app_id}, #{team_id}, '#{@current_time}', '#{@current_time}')
    SQL
  end

  def assign_user_to_team(team_id, user_id)
    ActiveRecord::Base.connection.execute <<-SQL
      insert into teams_users (#{id_field} team_id, user_id, created_at, updated_at)
      values (#{id_value('teams_users')} #{team_id}, #{user_id}, '#{@current_time}', '#{@current_time}')
    SQL
  end

  def id_field
    OracleAdapter ? "id, " : ""
  end

  def id_value(table)
    OracleAdapter ? "#{table}_seq.nextval, " : ""
  end

  def reassign_to_team(assignment_id, team_id)
    execute <<-SQL
      UPDATE assigned_apps SET team_id=#{team_id} WHERE id=#{assignment_id}
    SQL
  end

  def find_team_with_apps(app_ids)
    team_ids = ActiveRecord::Base.connection.select_values <<-SQL
      select dt.team_id from development_teams dt
      inner join teams t on t.id = dt.team_id
      where t.name like '#{NAME}%' and
            team_id not in(select distinct team_id from development_teams where app_id not in(#{app_ids.join(', ')}))
      group by dt.team_id
      having count(dt.app_id) = #{app_ids.size}
    SQL
    if team_ids.size > 0
      Team.find(team_ids[0])
    else
      nil
    end
  end

  def next_name
    @team_num += 1
    "#{NAME} #{@team_num}"
  end
end
