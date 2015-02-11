class SiteAdminGroupHandler < BaseHandler
  def apply
    site_admin_group_id = create_site_admin_group_with_role

    user_ids = ActiveRecord::Base.connection.select_values <<-SQL
      select id from users where admin = #{ActiveRecord::Base.connection.quoted_true}
    SQL

    user_ids.each do |user_id|
      process_site_admin(user_id, site_admin_group_id)
    end  

    ActiveRecord::Base.connection.execute <<-SQL
      update users set admin = #{ActiveRecord::Base.connection.quoted_false}
    SQL
  end  

  def revert
    user_ids = GroupSQL.get_user_ids(to_group_name(SITE_ADMIN))

    group_id = GroupSQL.get_group_id(to_group_name(SITE_ADMIN))

    ActiveRecord::Base.connection.execute <<-SQL
      update users set admin = #{ActiveRecord::Base.connection.quoted_true} where #{SQLHelper.where_in('id', user_ids)}
    SQL
    ActiveRecord::Base.connection.execute <<-SQL
      update assigned_environments set role = replace(role, '#{ADMIN_SUFFIX}', '') 
      where role like '%#{ADMIN_SUFFIX}' and assigned_app_id in (
        select assigned_app_id from assigned_apps where #{SQLHelper.where_in('user_id', user_ids)}
      )  
    SQL

    remove_site_admin_group_with_role  
  end

  private

  def create_site_admin_group_with_role
    admin_group_id = SQLHelper.insert('groups', {name: to_group_name(SITE_ADMIN), active: true, time: true}, true)
    role_id = RoleSQL.get_role_id(SITE_ADMIN)
    SQLHelper.insert('group_roles', {group_id: admin_group_id, role_id: role_id, time: true})
    admin_group_id
  end 

  def remove_site_admin_group_with_role
    role_id = RoleSQL.get_role_id(SITE_ADMIN)
    return unless role_id
    group_ids = ActiveRecord::Base.connection.select_values <<-SQL
      select group_id from group_roles where role_id = #{role_id}
    SQL
    ActiveRecord::Base.connection.execute <<-SQL 
      delete from group_roles where group_id in (#{group_ids.join(",")})
    SQL
    ActiveRecord::Base.connection.execute <<-SQL 
      delete from groups where id in (#{group_ids.join(",")})
    SQL
    ActiveRecord::Base.connection.execute <<-SQL 
      delete from roles where id = #{role_id}
    SQL
  end

  def process_site_admin(user_id, site_admin_group_id)
    SQLHelper.insert('user_groups', {user_id: user_id, group_id: site_admin_group_id, time: true})

    permanent_roles_sql = PERMANENT_ROLES.collect{|el| "'#{el.upcase}'"}.join(',')
    set_role_sql = "role = role + '#{ADMIN_SUFFIX}'"
    set_role_sql = "role = role || '#{ADMIN_SUFFIX}'" if PostgreSQLAdapter || OracleAdapter

    ActiveRecord::Base.connection.execute <<-SQL
      update assigned_environments set #{set_role_sql}
      where assigned_app_id in (select id from assigned_apps where user_id = #{user_id}) and upper(role) not in (#{permanent_roles_sql})
    SQL

    #raise "assined_environments: #{select_all('select assigned_app_id, role from assigned_environments').inspect}"
  end    
end