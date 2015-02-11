require 'query_helper'

class UserSQL
  class << self

    def already_in_group?(user_id, group_id)
      res = ActiveRecord::Base.connection.select_values <<-SQL
        select id from user_groups where user_id = #{user_id} and group_id = #{group_id} 
      SQL
      !res.empty?
    end  

    def make_user_admin(user_id)
      ActiveRecord::Base.connection.execute <<-SQL
        update users set admin = #{ActiveRecord::Base.connection.quoted_true} where id = #{user_id}
      SQL
    end

    def make_user_root(user_id)
      ActiveRecord::Base.connection.execute <<-SQL
        update users set root = #{ActiveRecord::Base.connection.quoted_true} where id = #{user_id}
      SQL
    end

    def make_user_not_root(user_id)
      ActiveRecord::Base.connection.execute <<-SQL
        update users set root = #{ActiveRecord::Base.connection.quoted_false} where id = #{user_id}
      SQL
    end

    def assign_user_to_app(user_id, app_id, team_id)
      id_field = DBHelper.id_field
      id_value = DBHelper.id_value('assigned_apps')
      SQLHelper.insert('assigned_apps', {user_id: user_id, app_id: app_id, team_id: team_id, time: true})
    end    

    def get_first_user_id
      res = ActiveRecord::Base.connection.select_values <<-SQL
        select min(id) from users 
      SQL
      res.first
    end    

    def assign_user_to_app_envs(user_id, app_id, team_id, env_roles = {})
      id_field = DBHelper.id_field
      assigned_app_id = AppSQL.get_assigned_app_id(app_id, user_id, team_id)
      AppSQL.get_app_environment_ids(app_id).each_with_index do |env_id, ind|
        SQLHelper.insert('assigned_environments', {assigned_app_id: assigned_app_id, environment_id: env_id, role: env_roles[env_id], time: true})
      end
    end

    def admin?(user_id)
      res = ActiveRecord::Base.connection.select_values <<-SQL
        select id from users where id = #{user_id} and admin = #{ActiveRecord::Base.connection.quoted_true}
      SQL
      !res.empty?
    end
    
    def root?(user_id)
      res = ActiveRecord::Base.connection.select_values <<-SQL
        select id from users where id = #{user_id} and root = #{ActiveRecord::Base.connection.quoted_true}
      SQL
      !res.empty?
    end  

    def get_user_roles
      ActiveRecord::Base.connection.select_all <<-SQL
        select id, old_roles from users
      SQL
    end  
  end
end

class AppSQL
  class << self
    def get_app_environment_id(app_id, environment_id)
      res = ActiveRecord::Base.connection.select_values <<-SQL
        select id from application_environments where app_id = #{app_id} and environment_id = #{environment_id}
      SQL
      res.first
    end

    def get_app_environment_ids(app_id)
      ActiveRecord::Base.connection.select_values <<-SQL
        select environment_id from application_environments ae where ae.app_id = #{app_id}
      SQL
    end

    def get_assigned_app_id(app_id, user_id, team_id)
      res = ActiveRecord::Base.connection.select_values <<-SQL
        select id from assigned_apps a where a.app_id = #{app_id} and a.user_id = #{user_id} and a.team_id = #{team_id}
      SQL
      res.first
    end
  end
end

class GroupSQL
  class << self
    def get_group_id(group_name)
      res = ActiveRecord::Base.connection.select_values <<-SQL
        select id from groups where upper(name) = upper('#{group_name}')
      SQL
      res.first
    end

    def get_user_ids(group_name)
      ActiveRecord::Base.connection.select_values <<-SQL
        select ug.user_id 
        from user_groups ug
          inner join groups g on ug.group_id = g.id
        where upper(g.name) = upper('#{group_name}')
      SQL
    end

    def get_root_user_ids
      ActiveRecord::Base.connection.select_values <<-SQL
        select ug.user_id 
        from user_groups ug
          inner join groups g on ug.group_id = g.id
        where g.root = #{ActiveRecord::Base.connection.quoted_true}
      SQL
    end

    def get_root_group
      res = ActiveRecord::Base.connection.select_values <<-SQL
        select id from groups where root = #{ActiveRecord::Base.connection.quoted_true}
      SQL
      res.first
    end

    def make_default(group_id)
      ActiveRecord::Base.connection.execute <<-SQL
        update groups set position = #{Group::DEFAULT_GROUP_POSITION} where id = #{group_id}
      SQL
    end

    def set_position(group_id, position)
      ActiveRecord::Base.connection.execute <<-SQL
        update groups set position = #{position} where id = #{group_id}
      SQL
    end 

    def get_default_groups
      ActiveRecord::Base.connection.select_values <<-SQL
        select id from groups where position = #{Group::DEFAULT_GROUP_POSITION} or position is NULL order by name ASC
      SQL
    end

    def remove_default_group
      ActiveRecord::Base.connection.execute <<-SQL
        delete from user_groups where group_id in (select id from groups where name = '[default]')
      SQL
      ActiveRecord::Base.connection.execute <<-SQL
        delete from groups where name = '[default]'
      SQL
    end 
  end
end


class RoleSQL
  class << self
    def get_role_id(role_name)
      res = ActiveRecord::Base.connection.select_values <<-SQL
        select id from roles where upper(name) = upper('#{role_name}')
      SQL
      res.first
    end

    def get_assigned_environments_with_roles(assigned_app_id)
      ActiveRecord::Base.connection.select_all <<-SQL
        select environment_id, role from assigned_environments where assigned_app_id = #{assigned_app_id}
      SQL
    end

    def get_team_roles(team_id, user_id)
      res = ActiveRecord::Base.connection.select_values <<-SQL
        select ae.role from assigned_apps aa
          inner join assigned_environments ae on ae.assigned_app_id = aa.id
        where aa.team_id = #{team_id} and aa.user_id = #{user_id}    
      SQL
      res.uniq
    end  

    def assign_role_to_user(user_id, role)
      role_sql = [role].to_yaml.to_s
      ActiveRecord::Base.connection.execute <<-SQL
        update users set old_roles = '#{role_sql}' where id = #{user_id}
      SQL
    end
  end
end
  
class TeamSQL
  class << self
    def get_team_name(team_id)
      res = ActiveRecord::Base.connection.select_values <<-SQL
        select name from teams
        where id = #{team_id}
      SQL
      res.first
    end

    def get_team_users(team_id)
      ActiveRecord::Base.connection.select_values <<-SQL
        select tu.user_id from teams_users tu
        where tu.team_id = #{team_id}
      SQL
    end

    def get_team_apps(team_id)
      ActiveRecord::Base.connection.select_values <<-SQL
        select app_id from development_teams where team_id = #{team_id}
      SQL
    end

    def get_team_groups(team_id)
      ActiveRecord::Base.connection.select_values <<-SQL
        select id from team_groups where team_id = #{team_id}
      SQL
    end

    def get_teams
      ActiveRecord::Base.connection.select_values <<-SQL
        select id from teams
      SQL
    end

    def create_default_team(id)
      res = ActiveRecord::Base.connection.select_values <<-SQL
        select id from teams where id = #{id}
      SQL
      team_id = res.first
      team_id = SQLHelper.insert('teams', {id: id, user_id: UserSQL.get_first_user_id, name: '[dafault]', active: true, time: true}, true) if team_id.nil?
      team_id
    end  

  end
end

class SQLHelper
  extend QueryHelper::WhereIn

  class << self 
    def insert(table_name, values_hash, return_id = false)
      keys_str = DBHelper.id_field
      values_str = DBHelper.id_value(table_name)
      
      keys   = []
      values = []
      values_hash.each do |k,v|
        if k.to_sym == :time
          keys   += ['created_at', 'updated_at']
          values += [ActiveRecord::Base.connection.quote(Time.current.to_formatted_s(:db))]*2
        elsif [TrueClass, FalseClass].include? v.class
          keys   << k
          values << ActiveRecord::Base.connection.quoted_true
        elsif v.nil?
          keys   << k
          values << "NULL"
        else
          keys << k 
          values << ActiveRecord::Base.connection.quote(v)
        end
      end

      keys_str   = "#{keys_str}#{keys.join(',')}"
      values_str = "#{values_str}#{values.join(',')}"
      ActiveRecord::Base.connection.execute <<-SQL
        insert into #{table_name} (#{keys_str})
        values (#{values_str})
      SQL
      ActiveRecord::Base.connection.select_values("select max(id) from #{table_name}").first if return_id
    end

    def where(search_str, *args)
      return "1 = 2" if search_str.empty?
      search_str.gsub("?", "%s")%args.collect{|el| el.join(",")}
    end  
  end
end

class DBHelper
  class << self
    def id_field
      OracleAdapter ? "id, " : ""
    end
   
    def id_value(table)
      OracleAdapter ? "#{table}_seq.nextval, " : ""
    end
  end
end