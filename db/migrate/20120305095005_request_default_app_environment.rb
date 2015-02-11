class RequestDefaultAppEnvironment < ActiveRecord::Migration
  def self.up

    #
    # First rename the existing [default] to [deprecated-default] so that we do not break any existing associations
    #
    default_col = OracleAdapter ? "\"DEFAULT\"" : (MySQLAdapter ? "`default`" : "\"default\"")
    rows = ActiveRecord::Base.connection.select_rows("select id from environments where name like '[default]'")
    if rows && rows.count > 0
      env_id = rows[0][0]
      ActiveRecord::Base.connection.execute("update environments set name = '[deprecated-default]', #{default_col}=#{RPMFALSE} where id = #{env_id}")
    end

    rows = ActiveRecord::Base.connection.select_rows("select id from apps where name like '[default]'")
    if rows && rows.count > 0
      app_id = rows[0][0]
      ActiveRecord::Base.connection.execute("update apps set name = '[deprecated-default]', #{default_col}=#{RPMFALSE} where id = #{app_id}")
    end

    #
    # Setup the new default app/env infrastructure
    #
    
    
    
    @env_values = "values (0, '[default]', #{DATE_NOW}, #{DATE_NOW}, #{RPMTRUE}, null, #{RPMTRUE})"
    @apps_values = "values (0, '[default]', #{DATE_NOW}, #{DATE_NOW}, #{RPMTRUE}, #{RPMTRUE}, null)"
    @apps_insert = "insert into apps " + @apps_values
    if MsSQLAdapter
      @env_insert = 'insert into environments (id, name, created_at, updated_at, active, default_server_group_id, "default") ' +  @env_values
      @apps_insert = 'insert into apps  (id, name, created_at, updated_at, active, "default", app_version ) ' + @apps_values
    else
      @env_insert = "insert into environments " +  @env_values
      @apps_insert = "insert into apps " + @apps_values
    end

    ActiveRecord::Base.connection.execute("SET IDENTITY_INSERT environments ON") if MsSQLAdapter
    ActiveRecord::Base.connection.execute(@env_insert)
    ActiveRecord::Base.connection.execute("SET IDENTITY_INSERT environments OFF") if MsSQLAdapter
    
    ActiveRecord::Base.connection.execute("SET IDENTITY_INSERT apps ON") if MsSQLAdapter
    ActiveRecord::Base.connection.execute(@apps_insert)
    ActiveRecord::Base.connection.execute("SET IDENTITY_INSERT apps OFF") if MsSQLAdapter
    
    ActiveRecord::Base.connection.execute("insert into application_environments (#{OracleAdapter ? "id, " : ""} app_id, environment_id, created_at, updated_at, position, different_level_from_previous) values (#{OracleAdapter ? "application_environments_seq.nextval, " : ""} 0, 0, #{DATE_NOW}, #{DATE_NOW}, 1, #{RPMTRUE})")

    #
    # Setup a new default team where everyone will have access to the new default app/env
    #
    ActiveRecord::Base.connection.execute("insert into teams (id, user_id, name, created_at, updated_at, active) values (0, 1, '[default]', #{DATE_NOW}, #{DATE_NOW}, #{RPMTRUE})")
    ActiveRecord::Base.connection.execute("insert into teams_roles (#{OracleAdapter ? "id, " : ""} team_id, user_id, app_id, created_at, updated_at, roles) values (#{OracleAdapter ? "teams_roles_seq.nextval, " : ""} 0, 1, 0, #{DATE_NOW}, #{DATE_NOW}, '--- !map:HashWithIndifferentAccess\n\"1\": deployment_coordinator\n\"2\": deployment_coordinator')")
    ActiveRecord::Base.connection.execute("insert into development_teams (#{OracleAdapter ? "id, " : ""} app_id, team_id, created_at, updated_at) values (#{OracleAdapter ? "development_teams_seq.nextval, " : ""}  0, 0, #{DATE_NOW}, #{DATE_NOW})")

    rows = ActiveRecord::Base.connection.select_rows("select id from users")
    if rows && rows.count > 0
      rows.each do | u |
        ActiveRecord::Base.connection.execute("insert into teams_users (#{OracleAdapter ? "id, " : ""} user_id, team_id, created_at, updated_at) values (#{OracleAdapter ? "teams_users_seq.nextval, " : ""} #{u[0]}, 0, #{DATE_NOW}, #{DATE_NOW})")
        ActiveRecord::Base.connection.execute("insert into assigned_apps (#{OracleAdapter ? "id, " : ""} app_id, user_id, team_id, created_at, updated_at) values (#{OracleAdapter ? "assigned_apps_seq.nextval, " : ""} 0, #{u[0]}, 0, #{DATE_NOW}, #{DATE_NOW})")
        t1_rows = ActiveRecord::Base.connection.select_rows("select id from assigned_apps where app_id = 0 and team_id = 0 and user_id = #{u[0]}")
        if t1_rows && t1_rows.count > 0
          ActiveRecord::Base.connection.execute("insert into assigned_environments (#{OracleAdapter ? "id, " : ""} assigned_app_id, environment_id, role, created_at, updated_at) values (#{OracleAdapter ? "assigned_environments_seq.nextval, " : ""} #{t1_rows[0][0]}, 0, 'deployer', #{DATE_NOW}, #{DATE_NOW})")
        end
      end
    end

    #
    # FIXME:
    # Do we want to fix the existing broken requests?
    # There are concerns over this from Manish. So keeping this commented.
    # To be kept as this is or uncommented based on confirmation with Brady
    #
    # rows = ActiveRecord::Base.connection.select_rows("select requests.id from requests where not exists (select 1 from apps_requests where request_id = requests.id)")
    # if rows && rows.count > 0
    #   rows.each do | r |
    #    ActiveRecord::Base.connection.execute("insert into apps_requests (request_id, app_id, created_at, updated_at) values (#{r[0]}, 0, #{dateString}, #{dateString})")
    #    ActiveRecord::Base.connection.execute("update requests set environment_id = 0 where id = #{r[0]}")
    #  end
    # end

    change_column :requests, :environment_id, :integer, :default => 0

  end

  def self.down
  end
end
