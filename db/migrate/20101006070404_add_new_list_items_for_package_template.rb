################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddNewListItemsForPackageTemplate < ActiveRecord::Migration
  def self.up
    
    {'SingleUserMode' => ['Not required', 'Use single-user mode without reboot', 'Reboot into single-user mode'],
      'Reboot' => ['Not required', 'After item deployment', 'After item deployment with reconfiguration (Solaris ONLY)', 'Out-of-Band', 'By end of job', 'By end of job with reconfiguration (Solaris ONLY)'],
      'ActionOnFail' => ['Ignore', 'Abort', 'Continue']
    }.each_pair { |key, values|
      execute <<-SQL
      insert into lists(#{OracleAdapter ? "id, " : ""}name) (select #{OracleAdapter ? "lists_seq.nextval as id, " : ""}'#{key}' as name #{OracleAdapter ? "from dual" : ""} where not exists (select 1 from lists where name='#{key}'))
      
SQL

      execute <<-SQL
      update lists set is_text=#{RPMTRUE} where name='#{key}'
      SQL
      #list = List.find_or_create_by_name(key)
      #list.update_attribute(:is_text, true)
      values.each do |v|
        execute <<-SQL
        insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}(select id from lists where name='#{key}') as list_id,'#{v}' as value_text#{OracleAdapter ? " from dual" : ""} where not exists (select 1 from list_items li inner join lists l on l.name='#{key}' and l.id=li.list_id and li.value_text='#{v}'))
        SQL
        #list.list_items.find_or_create_by_value_text(v)
      end
    }
  end

  def self.down
    # No need to roll back
  end
end
