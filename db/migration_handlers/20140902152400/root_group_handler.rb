class RootGroupHandler < BaseHandler
  def apply
    user_ids = ActiveRecord::Base.connection.select_values <<-SQL
      select id from users where root = #{ActiveRecord::Base.connection.quoted_true}
    SQL

    root_groups = ActiveRecord::Base.connection.select_values <<-SQL
      select id from groups where root = #{ActiveRecord::Base.connection.quoted_true}
    SQL
    group_id = root_groups.first
    group_id = SQLHelper.insert('groups', {name: ROOT_GROUP, root: true, time: true}, true) unless group_id

    user_ids.each do |user_id|
      SQLHelper.insert('user_groups', {user_id: user_id, group_id: group_id, time: true})
    end  

    ActiveRecord::Base.connection.execute <<-SQL
      update users set root = #{ActiveRecord::Base.connection.quoted_false}
    SQL
  end    

  def revert
    user_ids = GroupSQL.get_root_user_ids

    group_id = GroupSQL.get_root_group
    user_ids.each do |user_id|
      ActiveRecord::Base.connection.execute <<-SQL
        update users set root = #{ActiveRecord::Base.connection.quoted_true}
      SQL
    end

    ActiveRecord::Base.connection.execute <<-SQL 
      delete from user_groups where group_id = #{group_id}
    SQL
    ActiveRecord::Base.connection.execute <<-SQL 
      delete from groups where id = #{group_id}
    SQL
  end    
end