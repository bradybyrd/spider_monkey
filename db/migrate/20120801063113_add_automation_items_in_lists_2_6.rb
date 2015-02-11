class AddAutomationItemsInLists26 < ActiveRecord::Migration
  def up
    automation_category_types = ["BMC Application Automation 8.2", "BMC Remedy 7.6.x", "General", "Hudson/Jenkins"]   

    automation_types = ["Automation", "ResourceAutomation"]
    
    execute <<-SQL    
        Insert into lists(#{OracleAdapter ? "id, " : ""}name,is_text) values(#{OracleAdapter ? "lists_seq.nextval, " : ""}'AutomationCategory',#{RPMTRUE})
    SQL

    execute <<-SQL
        Insert into lists(#{OracleAdapter ? "id, " : ""}name,is_text) values(#{OracleAdapter ? "lists_seq.nextval, " : ""}'AutomationType',#{RPMTRUE})
    SQL

    automation_category_types.each do |category|
      execute <<-SQL
        Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{category}' as value_text from lists where name='AutomationCategory')
      SQL
    end

    automation_types.each do |automation_type|
      execute <<-SQL
        Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{automation_type}' as value_text from lists where name='AutomationType')
      SQL
    end    
    
  end

  def down

    ["AutomationCategory", "AutomationType"].each do |automation_type|
      execute <<-SQL
    delete from list_items where list_id=(select id from lists where name='#{automation_type}')    
      SQL

      execute <<-SQL
    delete from lists where name='#{automation_type}'    
      SQL

    end     

  end
end
