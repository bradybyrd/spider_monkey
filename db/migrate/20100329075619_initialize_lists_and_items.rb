################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class InitializeListsAndItems < ActiveRecord::Migration
  def self.up
    lists = ["FieldActivityStatic","ContainerTypes","IncludeInSteps","EventsForCategories","UserRoles","EmploymentTypes","Locations","Corporate","UnchangedFields","ColumnNoChanges","BudgetYear","ActivityNotAllow", "Categories", "CostTypes", "ProcessingStatus", "Roles", "Healths", "ValidStatuses", "ClosedStatuses"]
    
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
    containerType_item = ["Program", "Service Suite"]
    includeStep_item =  %w(component_id
                      work_task_id
                      phase_id
                      owner_id
                      owner_type
                      description
                      estimate
                      different_level_from_previous
                      name
                      manual
                      script_id
                      script_type)
   eventCategory_item = %w(problem block resolve unblock)
   user_role_item = [ "deployment_coordinator", "requestor", "portfolio_manager", "resource_manager", "financial_manager" ]
   employmentType_item = [ "contractor", "permanent" ]
   location_items = [ "hq" ]
   corporate_items = ["CapEx", "GIS Charge", "Informatics Project", "Informatics Service", "IT Project", "IT Service", "Other Charge"]
   unchangedField_items = ["created_at", "updated_at", "id"] 
   columnNoChange_items = ["activity_id", "po_yef_2010", "yef_2010", "ytdas_2010", "ytd_lex_2010"] 
   budgetYear_items = ["2010", "2011"]
   activityNotAllow_items = ["Terminated", "Consolidated", "Complete"]
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
   processing_items = ["requested", "active", "execute", "closed", "cancelled"]
   role_items =  %w(account_manager 
              application_owner 
              business_analyst 
              computational_scientist 
              informatician 
              project_manager 
              quality_manager 
              software_developer 
              system_administrator 
              solution_architect 
              service_manager 
              team_member 
              technical_writer)
    health_items = %w(green yellow red)
    validstatus_items = ["Projected", "Ongoing", "On Hold", "Terminated", "Consolidated", "Complete"]
    closedstatus_items = ["On hold", "Terminated", "Consolidated", "Complete"]
    
    lists.each do |list|
      execute <<-SQL
	      Insert into lists(#{OracleAdapter ? "id, " : ""}name,is_text,is_active) values(#{OracleAdapter ? "lists_seq.nextval, " : ""}'#{list}',#{RPMTRUE},#{RPMTRUE})
      SQL
    end


    fieldActivity_item.each do |field_item|
      execute <<-SQL
	      Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{field_item}' as value_text from lists where name='FieldActivityStatic')
      SQL
    end
    containerType_item.each do |container_item|
      execute <<-SQL
              Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{container_item}' as value_text from lists where name='ContainerTypes')
      SQL
    end
    includeStep_item.each do |step_item|
      execute <<-SQL
	      Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{step_item}' from lists where name='IncludeInSteps')
      SQL
    end

    eventCategory_item.each do |event_item|
      execute <<-SQL
	      Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{event_item}' from lists where name='EventsForCategories')
      SQL
    end

    user_role_item.each do |user_item|
      execute <<-SQL
	      Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{user_item}' from lists where name='UserRoles')
      SQL
    end

    employmentType_item.each do |employment_item|
      execute <<-SQL
	      Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{employment_item}' from lists where name='EmploymentTypes')
      SQL
    end

    location_items.each do |location_item|
      execute <<-SQL
	      Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{location_item}' from lists where name='Locations')
      SQL
    end

    corporate_items.each do |corporate_item|
      execute <<-SQL
	      Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{corporate_item}' from lists where name='Corporate')
      SQL
    end

    unchangedField_items.each do|unchange_item|
      execute <<-SQL
	      Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{unchange_item}' from lists where name='UnchangedFields')
      SQL
    end

    columnNoChange_items.each do |column_item|
      execute <<-SQL
	      Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{column_item}' from lists where name='ColumnNoChanges')
      SQL
    end

    budgetYear_items.each do |budgetYear_item|
      execute <<-SQL
	      Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{budgetYear_item}' from lists where name='BudgetYear')
      SQL
    end

    activityNotAllow_items.each do |activityNotAllow_item|
      execute <<-SQL
	      Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{activityNotAllow_item}' from lists where name='ActivityNotAllow')
      SQL
    end

    category_items.each do |category_item|
      execute <<-SQL
	      Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{category_item}' from lists where name='Categories')
      SQL
    end

    costType_items.each do |type_item|
      execute <<-SQL
	      Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{type_item}' from lists where name='CostTypes')
      SQL
    end

    processing_items.each do |processing_item|
      execute <<-SQL
	      Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{processing_item}' from lists where name='ProcessingStatus')
      SQL
    end

    role_items.each do |role_item|
      execute <<-SQL
	      Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{role_item}' from lists where name='Roles')
      SQL
    end

    health_items.each do |health_item|
      execute <<-SQL
	      Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{health_item}' from lists where name='Healths')
      SQL
    end

    validstatus_items.each do |valid_item|
      execute <<-SQL
	      Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{valid_item}' from lists where name='ValidStatuses')
      SQL
    end

    closedstatus_items.each do |close_item|
      execute <<-SQL
	      Insert into list_items(#{OracleAdapter ? "id, " : ""}list_id,value_text) (select #{OracleAdapter ? "list_items_seq.nextval as id, " : ""}id as list_id,'#{close_item}' from lists where name='ClosedStatuses')
      SQL
    end
  
    
  end

  def self.down
    # so what, big deal
  end
end
