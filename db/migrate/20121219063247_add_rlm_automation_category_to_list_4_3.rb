class AddRlmAutomationCategoryToList43 < ActiveRecord::Migration
  def self.up
  	rlm_automation_category = ["RLM Deployment Engine"]

    rlm_automation_category.each do |rlm_category|
      execute <<-SQL
        Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{rlm_category}' as value_text from lists where name='AutomationCategory')
      SQL
    end

  end

  def self.down
    ["RLM Deployment Engine"].each do |rlm_category|
      execute <<-SQL
    		delete from list_items where value_text='#{rlm_category}'    
      SQL
    end   	
  end
end
