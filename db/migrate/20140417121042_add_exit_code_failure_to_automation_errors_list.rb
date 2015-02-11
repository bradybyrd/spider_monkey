################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddExitCodeFailureToAutomationErrorsList < ActiveRecord::Migration
  ERRVAL = "Exit_Code_Failure"

  def self.up
    execute <<-SQL
     insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}(select id from lists where name='AutomationErrors') as list_id,'#{ERRVAL}' as value_text#{OracleAdapter ? " from dual":""})
    SQL
  end

  def self.down
    execute <<-SQL
     delete from list_items where list_id=(select id from lists where name='AutomationErrors') and value_text='#{ERRVAL}'
    SQL
  end
end