################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddAutomationErrorsToLists < ActiveRecord::Migration
  def self.up
    errors = ["STDERR: ", "failed: ", "AuthenticationFailed:"]

    execute <<-SQL
    insert into lists(#{OracleAdapter ? "id, " : ""}name,is_text,is_active) values(#{OracleAdapter ? "lists_seq.nextval, " : ""}'AutomationErrors',#{RPMTRUE}, #{RPMTRUE})
    SQL


    errors.each do |errval|
      execute <<-SQL
     insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}(select id from lists where name='AutomationErrors') as list_id,'#{errval}' as value_text#{OracleAdapter ? " from dual":""})
      SQL

    end
  end

  def self.down
      execute <<-SQL
   delete from list_items where list_id=(select id from lists where name='AutomationErrors')
     SQL

     execute <<-SQL
    delete from lists where name='AutomationErrors'
    SQL
  end
end
