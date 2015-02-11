################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################


class AddUserRoleInListItems < ActiveRecord::Migration
  def self.up 
      
    ["user", "deployer"].each do |role|
      execute <<-SQL
      insert into list_items(#{OracleAdapter ? "id,":""}list_id,value_text)  (select #{OracleAdapter ? "list_items_seq.nextval as id," : ""}(select id from lists where name='UserRoles') as list_id,'#{role}' as value_text #{OracleAdapter ? "from dual" : ""} where not exists (select 1 from list_items where list_id=(select id from lists where name='UserRoles') and value_text='#{role}'))
      SQL
      
    end
  end
 

  def self.down
    ["user", "deployer"].each do |role|
      execute <<-SQL
    delete from list_items where value_text='#{role}' and list_id in (select id from lists where name='UserRoles')
      SQL
    end
  end
end
