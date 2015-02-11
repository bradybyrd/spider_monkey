class RemoveUnwantedLists < ActiveRecord::Migration
  def self.up
    ["Categories", "CostTypes", "UnchangedFields", "ColumnNoChanges", "ProcessingStatus", 
      "CorporateIT", "BudgetYear", "ActivityNotAllow", "ContainerTypes", "Corporate", "FieldActivityStatic"].each do | list |
      rows = ActiveRecord::Base.connection.select_rows("select id from lists where name like '#{list}'")
      if rows && rows[0] && rows[0][0]
        ActiveRecord::Base.connection.execute("delete from list_items where list_id = #{rows[0][0]}")
        ActiveRecord::Base.connection.execute("delete from lists where id = #{rows[0][0]}")
      end
    end
  end

  def self.down
    #
    # Rajesh Jangam 03/22/2012
    # Do not like this. We did not remove old junk in the migrations.
    # And we are putting this junk in the down method of this cleanup migration
    #


    ["Categories", "CostTypes", "UnchangedFields", "ColumnNoChanges", "ProcessingStatus", 
      "BudgetYear", "ActivityNotAllow", "ContainerTypes", "Corporate", "FieldActivityStatic"].each do | list |
      execute <<-SQL
	      Insert into lists(#{OracleAdapter ? "id, " : ""}name,is_text,is_active) values(#{OracleAdapter ? "lists_seq.nextval , " : ""}'#{list}',#{OracleAdapter ? "1,1" : "true,true"})
      SQL
    end
  end

    category_items = ["Collaboration",
                     "Consulting",
                     "Consulting-independent contractor",
                     "Consulting - in-sourced",
                     "Data curation",
                     "Data license",
                     "Escrow",
                     "External Hosting",
                     "Fee",
                     "Hardware - Capital",
                     "Hardware - Expense",
                     "Hardware Maintenence",
                     "IISI DI SLA",
                     "Income",
                     "License",
                     "License & Consulting",
                     "Maintenance",
                     "Misc. Equipment",
                     "Software Maintenance",
                     "Staff Augmentation",
                     "Training"]

  costType_items =%w{Expense Capital}
  costType_items.each do |type_item|
    execute <<-SQL
         Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{type_item}' as value_text from lists where name='CostTypes')
    SQL
      
  end

  unchangedField_items = ["created_at", "updated_at", "id"]
  unchangedField_items.each do|unchange_item|
    execute <<-SQL
         Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{unchange_item}' from lists where name='UnchangedFields')
    SQL
  end
    
  columnNoChange_items = ["activity_id", "po_yef_2010", "yef_2010", "ytdas_2010", "ytd_lex_2010"]
  columnNoChange_items.each do |column_item|
    execute <<-SQL
         Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{column_item}' from lists where name='ColumnNoChanges')
    SQL
  end

  processing_items = ["requested", "active", "execute", "closed", "cancelled"]
  processing_items.each do |processing_item|
    execute <<-SQL
         Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{processing_item}' from lists where name='ProcessingStatus')
    SQL
      
  end

  corporate_items = ["CapEx", "GIS Charge", "Informatics Project", "Informatics Service", "IT Project", "IT Service", "Other Charge"]
  corporate_items.each do |corporate_item|
    execute <<-SQL
         Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{corporate_item}' from lists where name='Corporate')
    SQL
  end

  budgetYear_items = ["2010", "2011"]
  budgetYear_items.each do |budgetYear_item|
    execute <<-SQL
         Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{budgetYear_item}' from lists where name='BudgetYear')
    SQL
  end

  activityNotAllow_items = ["Terminated", "Consolidated", "Complete"]
  activityNotAllow_items.each do |activityNotAllow_item|
    execute <<-SQL
         Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{activityNotAllow_item}' from lists where name='ActivityNotAllow')
    SQL
  end

  containerType_item = ["Program", "Service Suite"]
  containerType_item.each do |container_item|
    execute <<-SQL
         Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{container_item}' as value_text from lists where name='ContainerTypes')
    SQL
  
  end

  fieldActivity_item = %w(name
                            current_phase_id 
                            projected_finish_at 
                            health 
                            parent_ids 
                            leading_group_id 
                            manager_id 
                            budget_category 
                            status 
                            problem_opportunity
                            goal
                            theme
                            blockers
                            cio_list
                            budget
                            service_description
                            estimated_start_for_spend)
  fieldActivity_item.each do |field_item|
    execute <<-SQL
         Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{field_item}' from lists where name='FieldActivityStatic')
    SQL
  end

end
