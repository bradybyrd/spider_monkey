################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ListItemProcedureCopy < ActiveRecord::Migration
  def self.up
    lists = ["IncludeInSteps"]
    
    includeStep_item =  %w(
            related_object_type
            latest_package_instance
            create_new_package_instance
            package_id
      )

    includeStep_item.each do |step_item|
      execute <<-SQL
	      Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{step_item}' from lists where name='IncludeInSteps')
      SQL
    end

  end

  def self.down
  end
end
